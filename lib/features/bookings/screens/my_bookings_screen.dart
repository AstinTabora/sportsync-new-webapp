import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/widgets/court_image.dart';
import 'package:sportsync/features/bookings/models/booking.dart';
import 'package:sportsync/features/bookings/providers/bookings_providers.dart';
import 'package:sportsync/features/home/providers/home_providers.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final upcoming = ref.watch(upcomingBookingsProvider);
    final past = ref.watch(pastBookingsProvider);
    final list = _showUpcoming ? upcoming : past;
    final total = upcoming.length + past.length;
    // courtId → cover image, to show each booking's court photo.
    final courtImages = {
      for (final c in ref.watch(courtsListProvider)) c.id: c.image,
    };

    return Container(
      color: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 64,
          16,
          32,
        ),
        children: [
          _Header(total: total, upcoming: upcoming.length),
          const SizedBox(height: 16),
          _Tabs(
            upcomingCount: upcoming.length,
            pastCount: past.length,
            showUpcoming: _showUpcoming,
            onTap: (v) => setState(() => _showUpcoming = v),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            _EmptyState(showUpcoming: _showUpcoming)
          else
            ..._buildList(list, courtImages),
          const SizedBox(height: 16),
          _BookAnotherCta(),
        ],
      ),
    );
  }

  List<Widget> _buildList(List<Booking> bookings, Map<String, String> covers) {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    final thisWeek = bookings.where((b) => !b.date.isAfter(endOfWeek)).toList();
    final later = bookings.where((b) => b.date.isAfter(endOfWeek)).toList();
    final widgets = <Widget>[];
    if (thisWeek.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(_showUpcoming ? 'THIS WEEK' : 'RECENT',
            style: AppTextStyles.eyebrow()),
      ));
      widgets.addAll(thisWeek.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingCard(booking: b, cover: covers[b.courtId] ?? ''),
          )));
    }
    if (later.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Text(_showUpcoming ? 'NEXT WEEK & BEYOND' : 'EARLIER',
            style: AppTextStyles.eyebrow()),
      ));
      widgets.addAll(later.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingCard(booking: b, cover: covers[b.courtId] ?? ''),
          )));
    }
    return widgets;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.upcoming});
  final int total;
  final int upcoming;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MY BOOKINGS', style: AppTextStyles.headingBlack()),
        const SizedBox(height: 6),
        Text(
          '$total total · $upcoming upcoming',
          style: AppTextStyles.bodyBold(color: AppColors.slate400),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.upcomingCount,
    required this.pastCount,
    required this.showUpcoming,
    required this.onTap,
  });
  final int upcomingCount;
  final int pastCount;
  final bool showUpcoming;
  final ValueChanged<bool> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.slate100),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'UPCOMING',
              count: upcomingCount,
              active: showUpcoming,
              onTap: () => onTap(true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Tab(
              label: 'PAST',
              count: pastCount,
              active: !showUpcoming,
              onTap: () => onTap(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: active ? AppShadows.cta : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.microLabel(
                color: active ? AppColors.white : AppColors.slate400,
              ).copyWith(fontSize: 10, letterSpacing: 2),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.microLabel(
                  color: active ? AppColors.white : AppColors.slate300,
                ).copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.cover = ''});
  final Booking booking;
  final String cover;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.slate100),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 64,
              height: 64,
              child: cover.isEmpty
                  ? Container(
                      color: AppColors.primaryExtralight,
                      child:
                          const Icon(Icons.sports, color: AppColors.primary),
                    )
                  : CourtImage(
                      path: cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryExtralight,
                        child: const Icon(Icons.sports,
                            color: AppColors.primary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.courtName,
                        style: AppTextStyles.pageTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusPill(status: booking.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 11, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d').format(booking.date),
                      style: AppTextStyles.bodyBold(color: AppColors.slate500)
                          .copyWith(fontSize: 11),
                    ),
                    Text(' · ',
                        style: AppTextStyles.body(color: AppColors.slate200)),
                    const Icon(Icons.access_time,
                        size: 11, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      booking.slots.isEmpty ? '' : booking.slots.first.time,
                      style: AppTextStyles.bodyBold(color: AppColors.slate500)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.slots.map((s) => s.court).toSet().join(' · '),
                        style: AppTextStyles.eyebrow(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(booking.refCode,
                        style: AppTextStyles.eyebrow(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, border) = switch (status) {
      BookingStatus.pending => (
          'PENDING',
          AppColors.statusAmber,
          AppColors.statusAmberBg,
          AppColors.statusAmber,
        ),
      BookingStatus.paid => (
          'PAID',
          AppColors.statusEmerald,
          AppColors.statusEmeraldBg,
          AppColors.statusEmerald,
        ),
      BookingStatus.cash => (
          'PAY AT COURT',
          AppColors.statusBlue,
          AppColors.statusBlueBg,
          AppColors.statusBlue,
        ),
      BookingStatus.completed => (
          'COMPLETED',
          AppColors.slate500,
          AppColors.slate100,
          AppColors.slate200,
        ),
      BookingStatus.cancelled => (
          'CANCELLED',
          AppColors.slate400,
          AppColors.slate100,
          AppColors.slate200,
        ),
      BookingStatus.pendingPayment => (
          'AWAITING PAYMENT',
          AppColors.statusAmber,
          AppColors.statusAmberBg,
          AppColors.statusAmber,
        ),
      BookingStatus.paymentFailed => (
          'PAYMENT FAILED',
          const Color(0xFFE11D48),
          const Color(0xFFFFE4E6),
          const Color(0xFFE11D48),
        ),
      BookingStatus.slotExpired => (
          'SLOT EXPIRED',
          AppColors.slate500,
          AppColors.slate100,
          AppColors.slate200,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        border: Border.all(color: border.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.microLabel(color: fg)
            .copyWith(fontSize: 9, letterSpacing: 1.6),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showUpcoming});
  final bool showUpcoming;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryExtralight,
              borderRadius: BorderRadius.circular(AppRadius.xl3),
            ),
            child: const Icon(Icons.calendar_today,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            showUpcoming ? 'NO UPCOMING BOOKINGS' : 'NO PAST BOOKINGS',
            style: AppTextStyles.pill().copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: 8),
          Text(
            showUpcoming
                ? 'Book a court and it will appear here.'
                : 'Your booking history will appear here.',
            style: AppTextStyles.body(color: AppColors.slate400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookAnotherCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/home'),
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryExtralight,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              'BOOK ANOTHER COURT',
              style: AppTextStyles.microLabel(color: AppColors.primary)
                  .copyWith(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
