import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adjacent slot suggestions shown in state H when the hold expires.
class AlternateSlot {
  const AlternateSlot({
    required this.court,
    required this.time,
    required this.label,
    required this.price,
  });

  final String court;
  final String time;
  final String label; // "same time" / "+1 hour" / "-1 hour"
  final int price;
}

class AlternateSlotsService {
  AlternateSlotsService(this._db);

  final FirebaseFirestore _db;

  /// Returns up to 3 free slots for the given court+date, ranked by
  /// closeness to `originalTime`. Excludes anything in `bookedSlots` or in
  /// an active `slotHolds` doc.
  Future<List<AlternateSlot>> find({
    required String courtId,
    required String date,
    required String originalTime,
    required List<String> canonicalHours, // e.g. ['6am - 7am', ..., '9pm - 10pm']
    required int pricePerSlot,
  }) async {
    final booked = await _db
        .collection('bookedSlots')
        .where('courtId', isEqualTo: courtId)
        .where('date', isEqualTo: date)
        .get();
    final takenTimes = <String>{
      for (final d in booked.docs) (d.data()['time'] as String? ?? '')
    };

    // Held (but not yet booked) slots. Best-effort: if this query fails (e.g.
    // permissions or an offline read) we still return suggestions from booked
    // slots rather than leaving the caller hanging.
    try {
      final now = Timestamp.now();
      final holds = await _db
          .collection('slotHolds')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'active')
          .get();
      for (final d in holds.docs) {
        final expiresAt = d.data()['expiresAt'] as Timestamp?;
        if (expiresAt == null || expiresAt.compareTo(now) < 0) continue;
        for (final s in (d.data()['slots'] as List? ?? const [])) {
          if (s is Map && s['time'] is String) takenTimes.add(s['time']);
        }
      }
    } catch (_) {
      // Ignore — held-slot exclusion is an optimization, not a correctness
      // requirement for the suggestion list.
    }

    final originalIdx = canonicalHours.indexOf(originalTime);
    final candidates = canonicalHours
        .where((h) => !takenTimes.contains(h) && h != originalTime)
        .map((h) {
      final idx = canonicalHours.indexOf(h);
      final delta = originalIdx == -1 ? 99 : (idx - originalIdx);
      final label = delta == 0
          ? 'same time'
          : (delta > 0 ? '+${delta}h' : '${delta}h');
      return (
        slot: AlternateSlot(
          // Court name picked at site of use (we only know the courtId here).
          court: courtId,
          time: h,
          label: label,
          price: pricePerSlot,
        ),
        distance: delta.abs(),
      );
    }).toList();

    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    return candidates.take(3).map((c) => c.slot).toList();
  }
}

final alternateSlotsServiceProvider =
    Provider<AlternateSlotsService>((ref) {
  return AlternateSlotsService(FirebaseFirestore.instance);
});
