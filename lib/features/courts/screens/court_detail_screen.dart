import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/core/widgets/court_image.dart';
import 'package:sportsync/features/courts/widgets/court_map.dart';
import 'package:sportsync/features/courts/widgets/court_photo.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single-scrollable court detail with a persistent floating Book Now bar.
/// Sections: photo header, title card overlap, description+amenities, location,
/// gallery, pricing, contact. Matches `screens-detail.jsx`.
class CourtDetailScreen extends ConsumerWidget {
  const CourtDetailScreen({super.key, required this.court});

  final Court court;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ListView must be Positioned.fill — a bare ListView in a Stack
          // gets unbounded vertical constraints and collapses to 0 height,
          // which renders as a blank screen with only the floating bar.
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 140),
              children: [
                _PhotoHeader(court: court),
                _TitleCard(court: court),
                _DescriptionSection(court: court),
                const SizedBox(height: 24),
                _LocationSection(court: court),
                const SizedBox(height: 24),
                _GallerySection(court: court),
                const SizedBox(height: 24),
                _PricingSection(basePrice: court.price.toInt()),
                const SizedBox(height: 24),
                _ContactSection(court: court),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Persistent floating Book Now bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BookNowBar(
              price: court.price.toInt(),
              onBook: () {
                ref.read(selectedCourtProvider.notifier).state = court;
                ref.read(bookingStepProvider.notifier).state =
                    BookingStep.calendar;
                context.push('/home/courts/${court.id}/book');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CourtPhoto(court: court),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl3),
          border: Border.all(color: AppColors.slate100),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ChipPill(
                  label: court.type.label,
                  fg: AppColors.primary,
                  bg: AppColors.primaryExtralight,
                ),
                _ChipPill(
                  label: '★ ${court.rating}',
                  fg: AppColors.primary,
                  bg: AppColors.slate50,
                ),
                _ChipPill(
                  label: 'OPEN NOW',
                  fg: AppColors.statusEmerald,
                  bg: AppColors.statusEmeraldBg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(court.name, style: AppTextStyles.cardTitle()),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    court.location,
                    style: AppTextStyles.bodyBold(color: AppColors.slate500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label, required this.fg, required this.bg});
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: fg.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: AppTextStyles.microLabel(
          color: fg,
        ).copyWith(fontSize: 9, letterSpacing: 1.6),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.description.isNotEmpty
                ? '${court.description} ${court.numberOfCourts} courts available daily 8am–11pm.'
                : '${court.numberOfCourts} courts available daily 8am–11pm.',
            style: AppTextStyles.body(color: AppColors.slate600),
          ),
          if (court.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in court.amenities)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: Text(
                      a.toUpperCase(),
                      style: AppTextStyles.microLabel(
                        color: AppColors.slate500,
                      ).copyWith(fontSize: 9),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.map,
            label: 'LOCATION',
            trailing: '2.4 km · ~9 min',
          ),
          const SizedBox(height: 10),
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.xl3),
              border: Border.all(color: AppColors.slate100),
            ),
            clipBehavior: Clip.antiAlias,
            child: _MapContent(court: court),
          ),
        ],
      ),
    );
  }
}

/// Map preview + Directions button overlay. Uses Google's iframe embed
/// (no API key) on web; styled placeholder on mobile until we add a
/// WebView there. `mapUrl` is part of the Firestore court document.
class _MapContent extends StatelessWidget {
  const _MapContent({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CourtMap(court: court)),
        Positioned(
          right: 12,
          bottom: 12,
          child: _DirectionsButton(court: court),
        ),
      ],
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.court});
  final Court court;

  Future<void> _open() async {
    final lat = court.latitude;
    final lng = court.longitude;
    final uri = lat != null && lng != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(court.location)}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions, color: AppColors.primary, size: 12),
            const SizedBox(width: 6),
            Text(
              'DIRECTIONS',
              style: AppTextStyles.microLabel(
                color: AppColors.primary,
              ).copyWith(fontSize: 9, letterSpacing: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SectionHeader(
              icon: Icons.photo_library,
              label: court.images.isEmpty
                  ? 'GALLERY'
                  : 'GALLERY (${court.images.length})',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (court.images.isEmpty)
                  SizedBox(
                    height: 112,
                    width: 144,
                    child: CourtPhoto(
                      court: court,
                      borderRadius: BorderRadius.circular(AppRadius.xl2),
                    ),
                  )
                else
                  for (final url in court.images) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl2),
                      child: SizedBox(
                        height: 112,
                        width: 144,
                        child: CourtImage(
                          path: url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryExtralight,
                            child: const Icon(
                              Icons.image,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.basePrice});
  final int basePrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.local_offer, label: 'PRICING'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              border: Border.all(color: AppColors.slate100),
              boxShadow: AppShadows.cardSubtle,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOURLY RATE', style: AppTextStyles.microLabel()),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₱$basePrice', style: AppTextStyles.priceMega()),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/hr',
                              style: AppTextStyles.microLabel(
                                color: AppColors.slate400,
                              ).copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Per court · No commitment',
                        style: AppTextStyles.body(color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryExtralight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.info_outline, label: 'CONTACT'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.phone,
                  text: court.phone ?? '+63 82 221 1234',
                  trail: 'CALL',
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.slate100,
                ),
                _ContactRow(
                  icon: Icons.email,
                  text: court.email ?? 'contact@example.ph',
                  trail: 'EMAIL',
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.slate100,
                ),
                _ContactRow(
                  icon: Icons.access_time,
                  text: 'Daily · 8 AM – 11 PM',
                  trailColor: AppColors.statusEmerald,
                  trail: 'OPEN',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.trail,
    this.trailColor = AppColors.primary,
  });
  final IconData icon;
  final String text;
  final String trail;
  final Color trailColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyBold(color: AppColors.slate600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            trail,
            style: AppTextStyles.microLabel(
              color: trailColor,
            ).copyWith(fontSize: 9, letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.pill().copyWith(letterSpacing: 2),
          ),
        ),
        if (trailing != null) Text(trailing!, style: AppTextStyles.eyebrow()),
      ],
    );
  }
}

class _BookNowBar extends StatelessWidget {
  const _BookNowBar({required this.price, required this.onBook});
  final int price;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.slate100)),
        boxShadow: AppShadows.floatingBar,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FROM', style: AppTextStyles.microLabel()),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱$price', style: AppTextStyles.priceMega()),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/hr',
                      style: AppTextStyles.microLabel(
                        color: AppColors.slate300,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                elevation: 6,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('BOOK NOW', style: AppTextStyles.ctaLabel()),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
