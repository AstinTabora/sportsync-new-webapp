import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/features/profile/data/user_profile_repository.dart';

/// Streams the FirebaseAuth user. Uses `userChanges()` (not
/// `authStateChanges()`) so that linking an email credential onto the anonymous
/// user — which keeps the same uid and signed-in state — still emits, flipping
/// `isAnonymous` to false in the UI. Yields `null` when fully signed-out.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

/// Stable accessor for the current UID. Returns null when signed-out.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

/// User profile from Firestore (`users/{uid}`). Auto-creates an empty doc
/// the first time it's read.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(userProfileRepositoryProvider).stream(uid);
});
