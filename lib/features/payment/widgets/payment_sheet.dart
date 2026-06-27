import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/bookings/models/booking.dart';
import 'package:sportsync/features/payment/data/alternate_slots_service.dart';
import 'package:sportsync/features/payment/data/payment_session_repository.dart';
import 'package:sportsync/features/payment/data/slot_holds_repository.dart';
import 'package:sportsync/features/payment/models/payment_sheet_state.dart';
import 'package:sportsync/features/payment/providers/payment_providers.dart';
import 'package:sportsync/features/payment/services/payment_lifecycle_observer.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';
import 'package:sportsync/features/payment/widgets/slot_clock.dart';
import 'package:sportsync/features/payment/widgets/states/state_b_first_time.dart';
import 'package:sportsync/features/payment/widgets/states/state_d_processing.dart';
import 'package:sportsync/features/payment/widgets/states/state_e_confirming.dart';
import 'package:sportsync/features/payment/widgets/states/state_f_success.dart';
import 'package:sportsync/features/payment/widgets/states/state_g_declined.dart';
import 'package:sportsync/features/payment/widgets/states/state_h_expired.dart';
import 'package:url_launcher/url_launcher.dart';

const _hourSlots = [
  '6am - 7am', '7am - 8am', '8am - 9am', '9am - 10am', '10am - 11am',
  '11am - 12pm', '12pm - 1pm', '1pm - 2pm', '2pm - 3pm', '3pm - 4pm',
  '4pm - 5pm', '5pm - 6pm', '6pm - 7pm', '7pm - 8pm', '8pm - 9pm',
  '9pm - 10pm',
];

/// Show the payment sheet as a modal bottom sheet. Returns when dismissed.
Future<void> showPaymentSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const PaymentSheet(),
  );
}

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key});

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  late final PaymentLifecycleObserver _lifecycle;
  bool _opened = false;

  // Captured while the widget is alive so `dispose()` can close the controller
  // without touching the widget `ref` (which throws once the element is torn
  // down: "Bad state: Cannot use ref after the widget was disposed").
  PaymentSheetController? _controller;

  @override
  void initState() {
    super.initState();
    _lifecycle = PaymentLifecycleObserver(
      onBackgrounded: _onBackgrounded,
      onResumed: _onResumed,
    );
    _lifecycle.attach();
    _controller = ref.read(paymentSheetControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openHold());
  }

  Future<void> _openHold() async {
    if (_opened) return;
    _opened = true;
    final court = ref.read(selectedCourtProvider);
    final slots = ref.read(selectedSlotsProvider);
    final date = ref.read(selectedDateProvider);
    if (court == null || slots.isEmpty) return;

    final dateStr = _yyyymmdd(date);
    final amountCents = (court.price * 100).toInt() * slots.length;
    final holdId = SlotHoldsRepository.holdIdFor(
      courtId: court.id,
      date: dateStr,
      slots: slots,
    );
    await ref.read(paymentSheetControllerProvider.notifier).open(
          holdId: holdId,
          courtId: court.id,
          date: dateStr,
          slots: slots,
          amountCents: amountCents,
        );
  }

  @override
  void dispose() {
    _lifecycle.detach();
    // Use the controller captured in initState — the widget `ref` is unusable
    // here. `close()` runs through the controller's own provider Ref, and the
    // autoDispose controller is still alive during this synchronous unmount.
    _controller?.close();
    super.dispose();
  }

  void _onBackgrounded() {
    final state = ref.read(paymentSheetControllerProvider);
    if (state == PaymentSheetState.firstTime ||
        state == PaymentSheetState.finalWarning) {
      // Likely the user switched to GCash mid-tap. The processing state
      // gets entered properly by `_pay()` below; this is a safety net for
      // edge cases.
    }
  }

  void _onResumed() {
    // The user returned to the app (e.g. from the PayMongo checkout page).
    // Ask the server to confirm the payment in case the webhook / deep-link
    // return were missed. `reconcile()` no-ops unless we're awaiting payment.
    _controller?.reconcile();
  }

  @override
  Widget build(BuildContext context) {
    // Wire deep-link + booking-status listeners.
    ref.watch(paymentBookingStatusListenerProvider);

    // Note: the success screen stays open until the user dismisses it
    // (tap-away / drag-down / VIEW BOOKING) — no auto-close.

    final court = ref.watch(selectedCourtProvider);
    final slotsSel = ref.watch(selectedSlotsProvider);
    final date = ref.watch(selectedDateProvider);
    final hold = ref.watch(activeSlotHoldProvider);
    final state = ref.watch(paymentSheetControllerProvider);

    if (court == null || slotsSel.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = BookingSummary(
      courtName: court.name,
      date: DateFormat('EEE, MMM d').format(date),
      timeRange: slotsSel.length == 1
          ? slotsSel.first.time
          : '${slotsSel.length} slots',
      totalCents: (court.price * 100).toInt() * slotsSel.length,
      facilityAddress: court.location,
      durationLabel: '${slotsSel.length} hr · ${slotsSel.length} slot${slotsSel.length > 1 ? 's' : ''} × ₱${court.price.toInt()}',
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  if (hold != null && state != PaymentSheetState.success)
                    SlotClock(expiresAt: hold.expiresAt)
                  else if (state == PaymentSheetState.success)
                    _SuccessRail()
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 4),
                  _Body(state: state, court: court, summary: summary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.court,
    required this.summary,
  });

  final PaymentSheetState state;
  final Court court;
  final BookingSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsSel = ref.watch(selectedSlotsProvider);
    final date = ref.watch(selectedDateProvider);
    final totalCents = (court.price * 100).toInt() * slotsSel.length;

    switch (state) {
      case PaymentSheetState.firstTime:
      case PaymentSheetState.finalWarning:
      case PaymentSheetState.returningSavedMethod:
        return FirstTimePayState(
          totalCents: totalCents,
          summary: summary,
          onPay: () => _pay(context, ref, BookingPayment.qrph),
          warning: state == PaymentSheetState.finalWarning,
        );

      case PaymentSheetState.processing:
        return ProcessingState(
          summary: summary,
          onCancel: () {
            ref.read(paymentSheetControllerProvider.notifier).retry();
          },
          onCheckStatus: () =>
              ref.read(paymentSheetControllerProvider.notifier).reconcile(),
        );

      case PaymentSheetState.confirming:
        return ConfirmingState(
          summary: summary,
          onCheckStatus: () =>
              ref.read(paymentSheetControllerProvider.notifier).reconcile(),
        );

      case PaymentSheetState.success:
        final refCode = ref.read(bookingRefCodeProvider);
        final email = ref.read(userEmailProvider);
        return SuccessState(
          refCode: refCode,
          userEmail: email.isEmpty ? 'your email' : email,
          summary: summary,
          onAddToCalendar: () {},
          onViewBooking: () {
            Navigator.of(context).maybePop();
            ref.read(bookingStepProvider.notifier).state =
                BookingStep.confirmation;
          },
        );

      case PaymentSheetState.declined:
        return DeclinedState(
          reason: 'payment was not completed',
          summary: summary,
          onRetry: () => _pay(context, ref, BookingPayment.qrph),
        );

      case PaymentSheetState.expired:
        return _ExpiredBody(courtId: court.id, date: date, court: court);
    }
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref,
    BookingPayment method,
  ) async {
    final court = ref.read(selectedCourtProvider);
    final slotsSel = ref.read(selectedSlotsProvider);
    final date = ref.read(selectedDateProvider);
    final hold = ref.read(activeSlotHoldProvider);
    final refCode = ref.read(bookingRefCodeProvider);
    if (court == null || slotsSel.isEmpty || hold == null) return;

    final controller = ref.read(paymentSheetControllerProvider.notifier);

    try {
      final session =
          await ref.read(paymentSessionRepositoryProvider).create(
                holdId: hold.id,
                refCode: refCode,
                amountCentavos:
                    (court.price * 100).toInt() * slotsSel.length,
                pricePerSlot: court.price,
                courtId: court.id,
                courtName: court.name,
                courtType: court.type.label,
                date: _yyyymmdd(date),
                slots: slotsSel,
                userEmail: ref.read(userEmailProvider),
                userName: ref.read(userNameProvider),
                userPhone: ref.read(userPhoneProvider),
                payment: method,
              );
      ref.read(activePaymentSessionProvider.notifier).state = session;
      ref.read(paymentBookingStatusListenerProvider);
      controller.enterProcessing();
      await launchUrl(
        Uri.parse(session.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
    } on FirebaseFunctionsException catch (e) {
      _toast(context, _humanizeFunctionsError(e));
      if (e.code == 'failed-precondition') {
        // Hold expired or inactive.
        ref.read(paymentSheetControllerProvider.notifier).markExpired();
      }
    } catch (e) {
      _toast(context, 'Something went wrong: $e');
    }
  }
}

class _ExpiredBody extends ConsumerStatefulWidget {
  const _ExpiredBody({
    required this.courtId,
    required this.date,
    required this.court,
  });
  final String courtId;
  final DateTime date;
  final Court court;

  @override
  ConsumerState<_ExpiredBody> createState() => _ExpiredBodyState();
}

class _ExpiredBodyState extends ConsumerState<_ExpiredBody> {
  List<AlternateSlot>? _alts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slotsSel = ref.read(selectedSlotsProvider);
    final originalTime = slotsSel.isEmpty ? '' : slotsSel.first.time;
    List<AlternateSlot> found;
    try {
      found = await ref.read(alternateSlotsServiceProvider).find(
            courtId: widget.courtId,
            date: _yyyymmdd(widget.date),
            originalTime: originalTime,
            canonicalHours: _hourSlots,
            pricePerSlot: widget.court.price.toInt(),
          );
    } catch (_) {
      // Never leave the sheet spinning — fall back to the "see all" path.
      found = const [];
    }
    if (mounted) setState(() => _alts = found);
  }

  @override
  Widget build(BuildContext context) {
    if (_alts == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ExpiredState(
      alternates: _alts!,
      onPickAlternate: (slot) {
        // Reset the selection to the alternate and reopen.
        ref.read(selectedSlotsProvider.notifier).state = [
          (court: slot.court, time: slot.time),
        ];
        // Regenerate refCode + reset state.
        ref.read(bookingRefCodeProvider.notifier).state =
            generateRefCode();
        ref.read(paymentSheetControllerProvider.notifier).retry();
      },
      onSeeAll: () {
        Navigator.of(context).maybePop();
        ref.read(bookingStepProvider.notifier).state =
            BookingStep.calendar;
      },
    );
  }
}

class _SuccessRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.statusEmerald,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

String _yyyymmdd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void _toast(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
}

String _humanizeFunctionsError(FirebaseFunctionsException e) {
  switch (e.code) {
    case 'unauthenticated':
      return 'Please sign in to continue.';
    case 'failed-precondition':
      return 'Your slot hold expired. Pick another slot.';
    case 'permission-denied':
      return 'You don\'t have permission to pay for this booking.';
    case 'invalid-argument':
      return e.message ?? 'Invalid booking details.';
    default:
      return 'Payment failed: ${e.message ?? e.code}';
  }
}
