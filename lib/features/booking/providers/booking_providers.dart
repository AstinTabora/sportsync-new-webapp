import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/models/court.dart';

enum BookingStep { details, calendar, payment, confirmation }

enum BookingPaymentMethod { gcash, cash }

typedef SelectedSlot = ({String court, String time});
typedef BookedSlot = ({
  String facilityId,
  String date,
  String court,
  String time
});

final selectedCourtProvider = StateProvider<Court?>((ref) => null);

final bookingStepProvider =
    StateProvider<BookingStep>((ref) => BookingStep.details);

final selectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final selectedSlotsProvider =
    StateProvider<List<SelectedSlot>>((ref) => []);

/// Session-local booked slots. Merged with `courtBookedSlotsProvider` (the
/// Firestore source of truth) in the calendar grid.
final bookedSlotsProvider =
    StateProvider<List<BookedSlot>>((ref) => const <BookedSlot>[]);

/// Firestore-backed booked slots for the currently selected court + date.
/// Written server-side (webhook / reconcile) when a booking is paid, so the
/// calendar reflects real bookings for every user.
final courtBookedSlotsProvider =
    StreamProvider.autoDispose<List<BookedSlot>>((ref) {
  final court = ref.watch(selectedCourtProvider);
  final date = ref.watch(selectedDateProvider);
  if (court == null) return Stream.value(const <BookedSlot>[]);
  final dateStr = _dateStr(date);
  return FirebaseFirestore.instance
      .collection('bookedSlots')
      .where('courtId', isEqualTo: court.id)
      .where('date', isEqualTo: dateStr)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final m = d.data();
            return (
              facilityId: m['courtId'] as String? ?? '',
              date: m['date'] as String? ?? '',
              court: m['court'] as String? ?? '',
              time: m['time'] as String? ?? '',
            );
          }).toList());
});

typedef CourtBlockout = ({
  String startDate,
  String endDate,
  List<String>? slots, // null means whole day
});

/// Active block-outs for the selected court that overlap the selected date.
/// Each item carries the affected slot times (HH:mm) or `null` for whole-day.
final courtBlockoutsProvider =
    StreamProvider.autoDispose<List<CourtBlockout>>((ref) {
  final court = ref.watch(selectedCourtProvider);
  final date = ref.watch(selectedDateProvider);
  if (court == null) return Stream.value(const <CourtBlockout>[]);
  final dateStr = _dateStr(date);

  return FirebaseFirestore.instance
      .collection('courts')
      .doc(court.id)
      .collection('blockouts')
      .where('endDate', isGreaterThanOrEqualTo: dateStr)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) {
            final m = d.data();
            final start = (m['startDate'] as String?) ?? '';
            final end = (m['endDate'] as String?) ?? '';
            if (dateStr.compareTo(start) < 0) return null;
            final raw = m['slots'];
            List<String>? slots;
            if (raw is List) {
              slots = raw.map((e) => e.toString()).toList();
            } else {
              slots = null; // "all"
            }
            return (startDate: start, endDate: end, slots: slots);
          })
          .whereType<CourtBlockout>()
          .toList());
});

final paymentMethodProvider =
    StateProvider<BookingPaymentMethod?>((ref) => null);

final bookingRefCodeProvider = StateProvider<String>((ref) => '');

final userNameProvider = StateProvider<String>((ref) => '');
final userEmailProvider = StateProvider<String>((ref) => '');
final userPhoneProvider = StateProvider<String>((ref) => '');

final totalPriceProvider = Provider<int>((ref) {
  final court = ref.watch(selectedCourtProvider);
  final slots = ref.watch(selectedSlotsProvider);
  return (court?.price.toInt() ?? 0) * slots.length;
});

/// Generate a short, unique booking reference code, e.g. `SS-LMEV7K2PQ4`.
/// Used as the Firestore `bookings/{refCode}` document id, so it must be
/// unique: the base36 timestamp is unique per device-millisecond and the
/// random salt covers concurrent same-millisecond bookings. Generated once
/// per booking session (via `bookingRefCodeProvider`).
String generateRefCode() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final rand = Random();
  final time =
      DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
  final salt =
      List.generate(2, (_) => chars[rand.nextInt(chars.length)]).join();
  return 'SS-$time$salt';
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
