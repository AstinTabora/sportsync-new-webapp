import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/config/env.dart';
import 'package:sportsync/features/bookings/models/booking.dart';
import 'package:sportsync/features/payment/models/payment_session.dart';

class PaymentSessionRepository {
  PaymentSessionRepository(this._functions, this._db);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  /// Calls the `createCheckoutSession` Cloud Function and returns the
  /// PayMongo checkout URL.
  Future<PaymentSession> create({
    required String holdId,
    required String refCode,
    required int amountCentavos,
    required double pricePerSlot,
    required String courtId,
    required String courtName,
    required String courtType,
    required String date,
    required List<({String court, String time})> slots,
    required String userEmail,
    required String userName,
    required String userPhone,
    required BookingPayment payment,
  }) async {
    // Hydrate the auth token cache so cloud_functions includes it in the HTTP header.
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    final callable =
        _functions.httpsCallable('createCheckoutSession');
    final result = await callable.call<Map<String, dynamic>>({
      'holdId': holdId,
      'refCode': refCode,
      'amountCentavos': amountCentavos,
      'pricePerSlot': pricePerSlot,
      'courtId': courtId,
      'courtName': courtName,
      'courtType': courtType,
      'date': date,
      'slots': slots
          .map((s) => {'court': s.court, 'time': s.time})
          .toList(),
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'payment': payment.wireValue,
    });

    final data = result.data;
    return PaymentSession(
      checkoutUrl: data['checkoutUrl'] as String,
      sessionId: data['sessionId'] as String,
      refCode: refCode,
    );
  }

  /// Ask the server to confirm payment directly with PayMongo and flip the
  /// booking if paid. Fallback for a missed webhook / deep-link return.
  Future<BookingStatus> reconcile(String refCode) async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    final callable = _functions.httpsCallable('reconcilePayment');
    final result = await callable.call<Map<String, dynamic>>({
      'refCode': refCode,
    });
    return BookingStatusX.parse(result.data['status'] as String?);
  }

  /// Stream the booking doc by refCode — the webhook flips `status` from
  /// `pendingPayment` to `paid` / `paymentFailed`, which drives the
  /// E → F/G transition on the sheet.
  Stream<BookingStatus> watchBookingStatus(String refCode) {
    return _db
        .collection('bookings')
        .doc(refCode)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return BookingStatus.pendingPayment;
      return BookingStatusX.parse(snap.data()?['status'] as String?);
    });
  }
}

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: Env.functionsRegion);
});

final paymentSessionRepositoryProvider =
    Provider<PaymentSessionRepository>((ref) {
  return PaymentSessionRepository(
    ref.watch(firebaseFunctionsProvider),
    FirebaseFirestore.instance,
  );
});
