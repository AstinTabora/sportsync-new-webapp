import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/features/payment/models/slot_hold.dart';

class SlotHoldsRepository {
  SlotHoldsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('slotHolds');

  /// Deterministic ID for the held slot bundle so duplicate opens dedupe.
  static String holdIdFor({
    required String courtId,
    required String date,
    required List<({String court, String time})> slots,
  }) {
    final sorted = slots.map((s) => '${s.court}@${s.time}').toList()..sort();
    return '${courtId}_${date}_${sorted.join('|').hashCode.toRadixString(36)}';
  }

  /// Create a 5-minute hold. If a hold with the same ID already exists and
  /// is still active, returns it as-is (idempotent).
  Future<SlotHold> create({
    required String holdId,
    required String userId,
    required String courtId,
    required String date,
    required List<({String court, String time})> slots,
    required int amountCents,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final ref = _col.doc(holdId);
    final now = DateTime.now();
    final expiresAt = now.add(ttl);

    final existing = await ref.get();
    if (existing.exists) {
      final current = SlotHold.fromDoc(existing);
      if (current.status == SlotHoldStatus.active && !current.isExpired) {
        return current;
      }
      // Stale doc — overwrite below.
    }

    final hold = SlotHold(
      id: holdId,
      userId: userId,
      courtId: courtId,
      date: date,
      slots: slots,
      amountCents: amountCents,
      expiresAt: expiresAt,
      status: SlotHoldStatus.active,
      createdAt: now,
    );
    await ref.set(hold.toMap());
    return hold;
  }

  Future<void> cancel(String holdId) async {
    try {
      await _col.doc(holdId).update({'status': SlotHoldStatus.cancelled.wireValue});
    } catch (_) {
      // Fire-and-forget; UI shouldn't block on this.
    }
  }

  Stream<SlotHold?> watch(String holdId) {
    return _col.doc(holdId).snapshots().map((s) {
      if (!s.exists) return null;
      return SlotHold.fromDoc(s);
    });
  }
}

final slotHoldsRepositoryProvider = Provider<SlotHoldsRepository>((ref) {
  return SlotHoldsRepository(FirebaseFirestore.instance);
});
