import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/features/bookings/models/booking.dart';

class BookingsRepository {
  BookingsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  Stream<List<Booking>> streamForUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }

  Future<void> create(Booking booking) async {
    final data = booking.toMap();
    if (booking.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(booking.id).set(data);
    }
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _col.doc(id).update({'status': status.wireValue});
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(FirebaseFirestore.instance);
});
