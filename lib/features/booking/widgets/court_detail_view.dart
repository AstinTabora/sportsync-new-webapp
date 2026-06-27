import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/widgets/court_image.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';

const _primary = Color(0xFF005F02);
const _primaryExtralight = Color(0xFFE6F0E6);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);

enum _SubTab { map, gallery, pricing }

class CourtDetailView extends ConsumerStatefulWidget {
  const CourtDetailView({super.key});

  @override
  ConsumerState<CourtDetailView> createState() => _CourtDetailViewState();
}

class _CourtDetailViewState extends ConsumerState<CourtDetailView> {
  _SubTab _tab = _SubTab.map;

  @override
  Widget build(BuildContext context) {
    final court = ref.watch(selectedCourtProvider)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCF9),
      body: CustomScrollView(
        slivers: [
          _CourtHeader(court: court, onBook: _goToCalendar),
          SliverToBoxAdapter(
            child: _SubTabBar(
              tab: _tab,
              onTap: (t) => setState(() => _tab = t),
            ),
          ),
          SliverToBoxAdapter(child: _tabContent(court)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _tabContent(Court court) {
    switch (_tab) {
      case _SubTab.map:
        return _MapTab(court: court);
      case _SubTab.gallery:
        return _GalleryTab(court: court);
      case _SubTab.pricing:
        return _PricingTab(court: court);
    }
  }

  void _goToCalendar() {
    ref.read(bookingStepProvider.notifier).state = BookingStep.calendar;
    ref.read(selectedSlotsProvider.notifier).state = [];
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _CourtHeader extends ConsumerWidget {
  const _CourtHeader({required this.court, required this.onBook});
  final Court court;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge(court.type.label, _primary, Colors.white),
                const SizedBox(width: 8),
                _badge('★ ${court.rating}', _primaryExtralight, _primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              court.name,
              style: const TextStyle(
                color: _primary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: _primary, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    court.location,
                    style: const TextStyle(
                      color: _slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₱${court.price.toInt()}',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const TextSpan(
                        text: '/hr',
                        style: TextStyle(
                          color: _slate400,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: _primary.withValues(alpha: 0.35),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  child: const Text('BOOK NOW'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}

// ─── Sub-tab bar ─────────────────────────────────────────────────────────────

class _SubTabBar extends StatelessWidget {
  const _SubTabBar({required this.tab, required this.onTap});
  final _SubTab tab;
  final void Function(_SubTab) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          _tab('MAP', _SubTab.map),
          const SizedBox(width: 8),
          _tab('GALLERY', _SubTab.gallery),
          const SizedBox(width: 8),
          _tab('PRICING', _SubTab.pricing),
        ],
      ),
    );
  }

  Widget _tab(String label, _SubTab value) {
    final active = tab == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primary : _slate50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _slate400,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─── Map tab ─────────────────────────────────────────────────────────────────

class _MapTab extends StatelessWidget {
  const _MapTab({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: _slate50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _slate100),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryExtralight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOCATION',
                        style: TextStyle(
                          color: _slate400,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        court.name,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              court.location,
              style: const TextStyle(
                color: _slate400,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (court.phone != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: _primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    court.phone!,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final q = Uri.encodeComponent(court.location);
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$q',
                  );
                  if (await canLaunchUrl(uri))
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('OPEN IN GOOGLE MAPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
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

// ─── Gallery tab ─────────────────────────────────────────────────────────────

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CourtImage(
              path: court.image,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: _primaryExtralight,
                child: const Icon(Icons.sports, color: _primary, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, i) {
              final isLast = i == 3;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://picsum.photos/seed/${court.id}$i/200/200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: _slate100),
                    ),
                    if (isLast)
                      Container(
                        color: _primary.withValues(alpha: 0.75),
                        child: const Center(
                          child: Text(
                            '+12',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Pricing tab ─────────────────────────────────────────────────────────────

class _PricingTab extends StatelessWidget {
  const _PricingTab({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    final tier = _PricingTier(
      name: 'Hourly Rate',
      price: '₱${court.price.toInt()}',
      period: 'per hour',
      desc: 'Per court, per hour. No commitment.',
      highlight: false,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: _PricingCard(tier: tier),
    );
  }
}

class _PricingTier {
  const _PricingTier({
    required this.name,
    required this.price,
    required this.period,
    required this.desc,
    required this.highlight,
  });
  final String name, price, period, desc;
  final bool highlight;
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.tier});
  final _PricingTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.highlight ? _primary : _slate100,
          width: tier.highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tier.desc,
                  style: const TextStyle(
                    color: _slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tier.price,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                tier.period,
                style: const TextStyle(
                  color: _slate400,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
