import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/sport_icons.dart';
import 'package:sportsync/core/widgets/court_image.dart';
import 'package:sportsync/features/home/providers/home_providers.dart';
import 'package:sportsync/features/onboarding/providers/onboarding_providers.dart';

/// Placeholder distances and next-slot strings reused across all results.
/// No backend — these are static stand-ins until real location/availability
/// data is wired up.
const _placeholderDistances = ['0.8 km', '1.4 km', '2.1 km', '3.2 km'];
const _placeholderSlots = ['6:00 PM', '6:00 PM', '7:00 PM', '8:00 PM'];

class _Recommendation {
  const _Recommendation({
    required this.court,
    required this.distance,
    required this.nextSlot,
  });
  final Court court;
  final String distance;
  final String nextSlot;
}

final filteredRecommendationsProvider = Provider<List<_Recommendation>>((ref) {
  final sport = ref.watch(onboardingSportProvider);
  final all = ref.watch(courtsListProvider);
  final pool = sport == null
      ? all
      : all.where((c) => c.type == sport).toList();
  final results = pool.take(_placeholderDistances.length).toList();
  return [
    for (var i = 0; i < results.length; i++)
      _Recommendation(
        court: results[i],
        distance: _placeholderDistances[i],
        nextSlot: _placeholderSlots[i],
      ),
  ];
});

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(filteredRecommendationsProvider);
    final sport = ref.watch(onboardingSportProvider);
    final date = ref.watch(onboardingDateProvider);
    final time = ref.watch(onboardingTimeProvider);

    return Container(
      color: AppColors.primary,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _GreenHeader(
              count: results.length,
              sport: sport,
              date: date,
              time: time,
              onBack: () => context.pop(),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl3 + 4),
                ),
              ),
              child: results.isEmpty
                  ? _EmptyState(
                      onBroaden: () =>
                          ref.read(onboardingSportProvider.notifier).state =
                              null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      itemCount: results.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == results.length) {
                          return _BroadenButton(
                            onTap: () => ref
                                .read(onboardingSportProvider.notifier)
                                .state = null,
                          );
                        }
                        final r = results[index];
                        return _RecommendationCard(
                          recommendation: r,
                          isBestMatch: index == 0,
                          onTap: () =>
                              context.push('/home/courts/${r.court.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  const _GreenHeader({
    required this.count,
    required this.sport,
    required this.date,
    required this.time,
    required this.onBack,
  });

  final int count;
  final CourtType? sport;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateLabel = _isSameDay(date, today)
        ? 'TODAY'
        : DateFormat('EEE d').format(date).toUpperCase();
    final sportLabel = sport == null ? 'ANY SPORT' : sport!.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Top picks\nfor you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                '$count FOUND',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryChip(
                  icon: sport == null ? Icons.auto_awesome : sportIcon(sport!),
                  label: sportLabel,
                ),
                const SizedBox(width: 6),
                _SummaryChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel,
                ),
                const SizedBox(width: 6),
                _SummaryChip(
                  icon: Icons.access_time,
                  label: time.format(context).toUpperCase(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ───────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.isBestMatch,
    required this.onTap,
  });

  final _Recommendation recommendation;
  final bool isBestMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final court = recommendation.court;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl3),
          border: Border.all(
            color: isBestMatch ? AppColors.primary : AppColors.slate100,
            width: isBestMatch ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isBestMatch ? 0.10 : 0.04,
              ),
              blurRadius: isBestMatch ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CourtImage(
                        path: court.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryExtralight,
                          child: Icon(
                            sportIcon(court.type),
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _Body(recommendation: recommendation)),
                ],
              ),
            ),
            if (isBestMatch)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'BEST MATCH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.recommendation});

  final _Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final court = recommendation.court;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              court.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primaryExtralight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    sportIcon(court.type),
                    color: AppColors.primary,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.directions,
                  color: AppColors.primary,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  recommendation.distance.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              recommendation.nextSlot,
              style: const TextStyle(
                color: AppColors.statusEmerald,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₱${court.price.toInt()}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                  const TextSpan(
                    text: '/hr',
                    style: TextStyle(
                      color: AppColors.slate300,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Empty / broaden ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBroaden});
  final VoidCallback onBroaden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              color: AppColors.slate300,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'NO COURTS MATCH YOUR PICKS.',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _BroadenButton(onTap: onBroaden),
          ],
        ),
      ),
    );
  }
}

class _BroadenButton extends StatelessWidget {
  const _BroadenButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.slate200,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, color: AppColors.slate400, size: 12),
            SizedBox(width: 8),
            Text(
              'BROADEN SEARCH',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
