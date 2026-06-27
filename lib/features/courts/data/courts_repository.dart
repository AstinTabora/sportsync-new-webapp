import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/models/court.dart';

/// Firestore-backed source of truth for the public court catalog.
/// Returns only `published` courts; owner-side draft courts are hidden.
class CourtsRepository {
  CourtsRepository(this._db);
  final FirebaseFirestore _db;

  Stream<List<Court>> watchPublishedCourts() {
    return _db
        .collection('courts')
        .where('published', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Court.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}

final courtsRepositoryProvider = Provider<CourtsRepository>(
  (ref) => CourtsRepository(FirebaseFirestore.instance),
);

final courtsStreamProvider = StreamProvider<List<Court>>(
  (ref) => ref.watch(courtsRepositoryProvider).watchPublishedCourts(),
);
