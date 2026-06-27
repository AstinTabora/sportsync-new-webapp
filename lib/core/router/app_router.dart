import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/features/about/screens/about_screen.dart';
import 'package:sportsync/features/booking/screens/booking_screen.dart';
import 'package:sportsync/features/bookings/screens/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/features/courts/data/courts_repository.dart';
import 'package:sportsync/features/courts/screens/court_detail_screen.dart';
import 'package:sportsync/features/home/screens/home_screen.dart';
import 'package:sportsync/features/onboarding/screens/recommendations_screen.dart';
import 'package:sportsync/features/profile/screens/account_screen.dart';
import 'package:sportsync/features/profile/screens/edit_profile_screen.dart';
import 'package:sportsync/features/profile/screens/profile_screen.dart';
import 'package:sportsync/features/shell/main_scaffold.dart';

/// Single [GoRouter] for the app.
/// Bottom tabs use [StatefulShellRoute] (Home / Bookings / Profile).
/// Court detail + booking flow are pushed inside the Home branch so they
/// inherit the back-stack of the tab the user came from.
/// Resolves a court by id against the Firestore stream, then renders the
/// detail screen. Falls back to a loading / not-found screen.
class _CourtDetailRoute extends ConsumerWidget {
  const _CourtDetailRoute({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courtsStreamProvider);
    return async.when(
      data: (courts) {
        Court? found;
        for (final c in courts) {
          if (c.id == id) {
            found = c;
            break;
          }
        }
        if (found == null) {
          return const Scaffold(
            body: Center(child: Text('Court not found.')),
          );
        }
        return CourtDetailScreen(court: found);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          // Home tab (with nested court detail + booking flow).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'recommendations',
                    builder: (_, __) => const RecommendationsScreen(),
                  ),
                  GoRoute(
                    path: 'courts/:id',
                    builder: (context, state) =>
                        _CourtDetailRoute(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'book',
                        builder: (context, state) => const BookingScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Bookings tab.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MyBookingsScreen(),
                ),
              ),
            ],
          ),
          // Profile tab (with nested Edit + About).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'account',
                    builder: (context, state) => const AccountScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
