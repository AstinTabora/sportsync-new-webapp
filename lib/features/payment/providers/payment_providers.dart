import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/bookings/models/booking.dart';
import 'package:sportsync/features/payment/data/payment_session_repository.dart';
import 'package:sportsync/features/payment/data/slot_holds_repository.dart';
import 'package:sportsync/features/payment/models/payment_session.dart';
import 'package:sportsync/features/payment/models/payment_sheet_state.dart';
import 'package:sportsync/features/payment/models/slot_hold.dart';
import 'package:sportsync/features/payment/services/payment_deep_link_service.dart';

/// Active slot hold for the current sheet session. Null when the sheet is
/// closed. Set by `PaymentSheetController.open`.
final activeSlotHoldProvider = StateProvider<SlotHold?>((ref) => null);

/// Active checkout session for the current sheet session.
final activePaymentSessionProvider =
    StateProvider<PaymentSession?>((ref) => null);

/// Stream of the booking status for the active refCode. Drives E → F/G
/// when the webhook flips status to paid / paymentFailed.
final activeBookingStatusProvider =
    StreamProvider.autoDispose<BookingStatus>((ref) {
  final session = ref.watch(activePaymentSessionProvider);
  if (session == null) return const Stream.empty();
  return ref
      .watch(paymentSessionRepositoryProvider)
      .watchBookingStatus(session.refCode);
});

/// The 8-state machine notifier.
class PaymentSheetController extends StateNotifier<PaymentSheetState> {
  PaymentSheetController(this._ref) : super(PaymentSheetState.firstTime);

  final Ref _ref;
  Timer? _holdTicker;
  Timer? _confirmingTimeout;
  Timer? _reconcileTimer;

  /// Called by the sheet when it opens. Creates a slot hold and starts the
  /// hold-expiry ticker.
  Future<SlotHold?> open({
    required String holdId,
    required String courtId,
    required String date,
    required List<({String court, String time})> slots,
    required int amountCents,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Caller is responsible for ensuring anonymous sign-in completed.
      state = PaymentSheetState.expired;
      return null;
    }

    state = PaymentSheetState.firstTime;
    try {
      final hold = await _ref.read(slotHoldsRepositoryProvider).create(
            holdId: holdId,
            userId: uid,
            courtId: courtId,
            date: date,
            slots: slots,
            amountCents: amountCents,
          );
      _ref.read(activeSlotHoldProvider.notifier).state = hold;
      _startHoldTicker(hold);
      return hold;
    } catch (e) {
      debugPrint('slot hold create failed: $e');
      state = PaymentSheetState.expired;
      return null;
    }
  }

  /// Called when the user taps "pay with GCash" (or card).
  void enterProcessing() {
    state = PaymentSheetState.processing;
    _startReconcilePolling();
  }

  /// Ask the server to confirm the payment with PayMongo and advance the sheet.
  /// Safe to call repeatedly; only acts while we're waiting on payment.
  Future<void> reconcile() async {
    if (state != PaymentSheetState.processing &&
        state != PaymentSheetState.confirming) {
      return;
    }
    final session = _ref.read(activePaymentSessionProvider);
    if (session == null) return;
    try {
      final status = await _ref
          .read(paymentSessionRepositoryProvider)
          .reconcile(session.refCode);
      if (status == BookingStatus.paid) {
        _cancelConfirmingTimeout();
        _reconcileTimer?.cancel();
        state = PaymentSheetState.success;
      } else if (status == BookingStatus.paymentFailed) {
        _reconcileTimer?.cancel();
        state = PaymentSheetState.declined;
      }
    } catch (_) {
      // Best-effort: the poll, app-resume, or a manual tap will retry.
    }
  }

  /// Poll PayMongo (via the server) while waiting on payment, so the sheet
  /// advances even if the webhook and deep-link return are both missed.
  void _startReconcilePolling() {
    _reconcileTimer?.cancel();
    final startedAt = DateTime.now();
    _reconcileTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      final waitedTooLong =
          DateTime.now().difference(startedAt) > const Duration(minutes: 3);
      final notWaiting = state != PaymentSheetState.processing &&
          state != PaymentSheetState.confirming;
      if (waitedTooLong || notWaiting) {
        t.cancel();
        return;
      }
      reconcile();
    });
  }

  /// Called when the OS delivers the deep-link callback.
  void onDeepLink(PaymentDeepLinkCallback cb) {
    final session = _ref.read(activePaymentSessionProvider);
    if (session == null || cb.refCode != session.refCode) return;
    if (cb.status == PaymentCallbackStatus.success) {
      _enterConfirming();
    } else {
      state = PaymentSheetState.declined;
    }
  }

  /// Called by the Firestore stream listener on `bookings/{refCode}`.
  void onBookingStatusChange(BookingStatus s) {
    switch (s) {
      case BookingStatus.paid:
        _cancelConfirmingTimeout();
        state = PaymentSheetState.success;
        break;
      case BookingStatus.paymentFailed:
        _cancelConfirmingTimeout();
        state = PaymentSheetState.declined;
        break;
      default:
        // pending / pendingPayment — no transition.
        break;
    }
  }

  /// "Try again" from G — re-arm the sheet for another attempt.
  void retry() {
    state = PaymentSheetState.firstTime;
  }

  /// Called when the server reports the hold is no longer valid (expired
  /// between our timer and the function call). Surfaces state H.
  void markExpired() {
    state = PaymentSheetState.expired;
  }

  void _enterConfirming() {
    state = PaymentSheetState.confirming;
    _confirmingTimeout?.cancel();
    _confirmingTimeout = Timer(const Duration(seconds: 90), () {
      // Stay in confirming — UI flips copy to "still confirming…".
      // No state change; widgets can read a separate "slow webhook" flag if
      // we want to swap copy. Keeping logic conservative for v1.
    });
  }

  void _startHoldTicker(SlotHold hold) {
    _holdTicker?.cancel();
    _holdTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = hold.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _holdTicker?.cancel();
        if (state == PaymentSheetState.firstTime ||
            state == PaymentSheetState.finalWarning) {
          state = PaymentSheetState.expired;
        }
        // If we're already in processing/confirming, don't yank to H —
        // payment may still complete. Webhook flips to F/G.
      } else if (remaining.inSeconds <= 60 &&
          state == PaymentSheetState.firstTime) {
        state = PaymentSheetState.finalWarning;
      }
    });
  }

  void _cancelConfirmingTimeout() {
    _confirmingTimeout?.cancel();
    _confirmingTimeout = null;
  }

  void close() {
    _holdTicker?.cancel();
    _confirmingTimeout?.cancel();
    _reconcileTimer?.cancel();
    final hold = _ref.read(activeSlotHoldProvider);
    if (hold != null &&
        state != PaymentSheetState.success &&
        state != PaymentSheetState.processing &&
        state != PaymentSheetState.confirming) {
      _ref.read(slotHoldsRepositoryProvider).cancel(hold.id);
    }
    _ref.read(activeSlotHoldProvider.notifier).state = null;
    _ref.read(activePaymentSessionProvider.notifier).state = null;
    state = PaymentSheetState.firstTime;
  }

  @override
  void dispose() {
    _holdTicker?.cancel();
    _confirmingTimeout?.cancel();
    _reconcileTimer?.cancel();
    super.dispose();
  }
}

final paymentSheetControllerProvider = StateNotifierProvider.autoDispose<
    PaymentSheetController, PaymentSheetState>(
  (ref) => PaymentSheetController(ref),
);

/// Wires the deep-link stream to the controller. Watched by `main.dart`
/// at app boot so cold-start payment returns are handled.
final paymentDeepLinkListenerProvider = Provider.autoDispose<void>((ref) {
  final controller = ref.read(paymentSheetControllerProvider.notifier);
  final service = ref.watch(paymentDeepLinkServiceProvider);
  final sub = service.stream.listen(controller.onDeepLink);
  ref.onDispose(sub.cancel);
});

/// Wires the booking-status stream to the controller. Driven by the sheet
/// while open.
final paymentBookingStatusListenerProvider = Provider.autoDispose<void>((ref) {
  final controller = ref.read(paymentSheetControllerProvider.notifier);
  // Use `ref.listen` (callback runs *after* build) rather than mutating the
  // controller during this provider's build — doing the latter trips Riverpod's
  // "providers must not modify other providers during initialization" assertion
  // and blocked the E → F/G transition. The already-paid-before-subscribe case
  // is covered by `reconcile()` (which sets state outside any build).
  ref.listen<AsyncValue<BookingStatus>>(
    activeBookingStatusProvider,
    (prev, next) => next.whenData(controller.onBookingStatusChange),
  );
});

/// Convenience: today's booking ref code lives in `bookingRefCodeProvider`
/// (legacy). Re-export under a payment-feature alias to keep imports local.
final paymentRefCodeProvider = Provider<String>((ref) {
  return ref.watch(bookingRefCodeProvider);
});
