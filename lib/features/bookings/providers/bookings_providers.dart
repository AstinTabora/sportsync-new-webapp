import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/features/bookings/data/bookings_repository.dart';
import 'package:sportsync/features/bookings/models/booking.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

/// In-memory bookings list, merged with the Firestore stream in
/// [userBookingsProvider]. Paid bookings are persisted server-side by the
/// PayMongo webhook; this stays available for optimistic local inserts and
/// survives only for the app session.
class LocalBookingsNotifier extends StateNotifier<List<Booking>> {
  LocalBookingsNotifier() : super(const []);

  void add(Booking booking) {
    final idx = state.indexWhere((b) => b.id == booking.id);
    if (idx == -1) {
      state = [...state, booking];
    } else {
      final next = [...state];
      next[idx] = booking;
      state = next;
    }
  }
}

final localBookingsProvider =
    StateNotifierProvider<LocalBookingsNotifier, List<Booking>>(
  (ref) => LocalBookingsNotifier(),
);

/// Remote stream — only active when a user is signed in.
final _remoteBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Booking>[]);
  return ref.watch(bookingsRepositoryProvider).streamForUser(uid);
});

/// All bookings for display: merge of in-memory + Firestore (deduped by id;
/// local wins on conflict).
final userBookingsProvider = Provider<List<Booking>>((ref) {
  final local = ref.watch(localBookingsProvider);
  final remote = ref.watch(_remoteBookingsProvider).asData?.value ?? const [];

  final byId = <String, Booking>{};
  for (final b in remote) {
    byId[b.id] = b;
  }
  for (final b in local) {
    byId[b.id] = b;
  }
  return byId.values.toList()..sort((a, b) => b.date.compareTo(a.date));
});

/// Splits the user's bookings into upcoming vs past based on date.
final upcomingBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(userBookingsProvider);
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return all.where((b) => !b.date.isBefore(startOfToday)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

final pastBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(userBookingsProvider);
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return all.where((b) => b.date.isBefore(startOfToday)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Aggregated stats shown on the Profile screen's 3-up grid.
final bookingsStatsProvider = Provider<({int total, int hours, double rating})>(
    (ref) {
  final all = ref.watch(userBookingsProvider);
  final completed =
      all.where((b) => b.status == BookingStatus.completed).toList();
  final hours = all.fold<int>(0, (sum, b) => sum + b.slots.length);
  return (total: all.length, hours: hours, rating: completed.isEmpty ? 5.0 : 4.9);
});
