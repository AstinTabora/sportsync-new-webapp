import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/courts/data/courts_repository.dart';
import 'package:sportsync/features/courts/widgets/court_card.dart';
import 'package:sportsync/features/courts/widgets/court_card_compact.dart';
import 'package:sportsync/features/home/providers/home_providers.dart';
import 'package:sportsync/features/onboarding/providers/onboarding_providers.dart';
import 'package:sportsync/features/onboarding/widgets/onboarding_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shown = ref.read(onboardingShownThisSessionProvider);
      if (shown) return;
      ref.read(onboardingShownThisSessionProvider.notifier).state = true;
      OnboardingSheet.show(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final courts = ref.watch(filteredCourtsProvider);
    final loadState = ref.watch(courtsStreamProvider);
    final viewMode = ref.watch(homeViewModeProvider);

    return CustomScrollView(
      slivers: [
        // Hero + How It Works card composed in a single sliver Stack so the
        // card cleanly sits ON TOP of the hero image (no sliver-clipping
        // edge cases from negative offsets).
        SliverToBoxAdapter(child: _HeroWithCard(ref: ref)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _FilterBar(),
          ),
        ),
        if (courts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ViewModeToggle(
                    mode: viewMode,
                    onSelect: (m) =>
                        ref.read(homeViewModeProvider.notifier).state = m,
                  ),
                ],
              ),
            ),
          ),
        if (courts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: loadState.isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Text(
                        loadState.hasError
                            ? 'Could not load venues. Pull to retry.'
                            : 'NO VENUES MATCH YOUR SEARCH.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.microLabel(
                          color: AppColors.slate400,
                        ).copyWith(fontSize: 12, letterSpacing: 1.2),
                      ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final court = courts[index];
                  // Placeholder until an "open courts today" feed is wired up.
                  final open = court.numberOfCourts * 15;
                  void details() => context.push('/home/courts/${court.id}');
                  void book() {
                    ref.read(selectedCourtProvider.notifier).state = court;
                    ref.read(bookingStepProvider.notifier).state =
                        BookingStep.calendar;
                    context.push('/home/courts/${court.id}/book');
                  }

                  final compact = viewMode == HomeViewMode.compact;
                  return Padding(
                    padding: EdgeInsets.only(bottom: compact ? 10 : 16),
                    child: compact
                        ? CourtCardCompact(
                            court: court,
                            onDetails: details,
                            onBook: book,
                          )
                        : CourtCard(
                            court: court,
                            openToday: open,
                            onDetails: details,
                            onBook: book,
                          ),
                  );
                },
                childCount: courts.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// Segmented toggle to switch the court list between the full card and the
/// compact horizontal row. Appearance is driven by [mode] (the parent watches
/// the provider), taps fire [onSelect].
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onSelect});

  final HomeViewMode mode;
  final ValueChanged<HomeViewMode> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, HomeViewMode m) {
      final active = mode == m;
      return GestureDetector(
        onTap: () => onSelect(m),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? Colors.white : AppColors.slate400,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.view_agenda_outlined, HomeViewMode.regular),
          const SizedBox(width: 2),
          btn(Icons.view_list_outlined, HomeViewMode.compact),
        ],
      ),
    );
  }
}

// ─── Hero + Card composite ──────────────────────────────────────────────────

/// Stacks the hero (520dp) and the How It Works card (~140dp), with the card
/// pulled UP into the hero by 48dp via a Positioned offset. Using one Stack
/// here (instead of two slivers with Transform.translate on the card)
/// guarantees the card paints AFTER the hero — i.e. on top — with zero
/// risk of sliver-bound clipping on the overlapping pixels.
class _HeroWithCard extends ConsumerWidget {
  const _HeroWithCard({required this.ref});
  final WidgetRef ref;

  static const double _heroHeight = 520;
  static const double _overlap = 48;
  // Approximate card height (icons + labels + padding). Generous so the
  // card never gets clipped at the bottom; the trailing whitespace blends
  // into the canvas below.
  static const double _cardArea = 152;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return SizedBox(
      height: _heroHeight + _cardArea - _overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hero pinned to the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight,
            child: _HeroSection(ref: ref),
          ),
          // Card overlaps the bottom 48dp of the hero. Listed AFTER the hero
          // in this Stack → painted on top.
          Positioned(
            top: _heroHeight - _overlap,
            left: 16,
            right: 16,
            child: const _HowItWorksCard(),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  const _HeroSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return SizedBox(
      height: 520,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 (bottom): court photo background.
          Image.asset(
            'assets/images/hero-bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF001F12)),
          ),
          // Layer 2: dark green gradient on TOP of the photo so the brand
          // wash dominates and text stays readable. Matches the design's
          // `from-[#001F12] via-[#003D1A]/90 to-[#005F02]/80`.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF2001F12), // 95%
                  Color(0xE5003D1A), // 90%
                  Color(0xCC005F02), // 80%
                ],
              ),
            ),
          ),
          // Layer 3: centered content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'PLAN LESS\nPLAY MORE.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayBlack(color: AppColors.white)
                        .copyWith(fontSize: 48, height: 0.85),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Book premium Badminton and Pickleball courts in a few clicks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── How It Works ───────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.slate100),
        // Heavier shadow so the card visibly "lifts" off the dark hero.
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000), // ~20% black
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x14000000), // ~8% black, tighter
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DottedConnectorPainter()),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _StepItem(icon: Icons.sports_tennis, title: 'PICK A SPORT')),
              Expanded(child: _StepItem(icon: Icons.location_on, title: 'CHOOSE A COURT')),
              Expanded(child: _StepItem(icon: Icons.event_available, title: 'BOOK YOUR SLOT')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryExtralight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _DottedConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Same wave as design: M 150 50 Q 350 10, 500 50 Q 650 90, 850 50
    // (but normalized to our card width/height)
    final yMid = size.height * 0.32;
    final dashWidth = 2.0;
    final dashGap = 6.0;
    final path = Path();
    path.moveTo(size.width * 0.18, yMid);
    path.quadraticBezierTo(
        size.width * 0.36, yMid - 18, size.width * 0.50, yMid);
    path.quadraticBezierTo(
        size.width * 0.64, yMid + 18, size.width * 0.82, yMid);

    // Dash the path
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          m.extractPath(distance, next.clamp(0, m.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Search + Filter bar ────────────────────────────────────────────────────
// One clean control: search on the left, filters on the right. Tapping either
// expands its own panel (search field / Sport + Sort); the other collapses.

enum _Panel { none, search, filters }

class _FilterBar extends ConsumerStatefulWidget {
  const _FilterBar();

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  _Panel _panel = _Panel.none;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggle(_Panel p) {
    setState(() => _panel = _panel == p ? _Panel.none : p);
    if (_panel == _Panel.search) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _searchFocus.requestFocus());
    }
  }

  void _onQuery(String v) {
    ref.read(homeSearchQueryProvider.notifier).state = v;
    setState(() {}); // refresh the clear button
  }

  @override
  Widget build(BuildContext context) {
    final sport = ref.watch(homeFilterProvider);
    final sortMode = ref.watch(homeSortProvider);
    final asc = ref.watch(homeSortAscendingProvider);
    final query = ref.watch(homeSearchQueryProvider);
    final filtersActive =
        sport != null || sortMode != CourtSortMode.defaultOrder;
    final searchActive = _panel == _Panel.search || query.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: AppShadows.cardSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        children: [
          Row(
            children: [
              // Search trigger (left)
              Expanded(
                child: InkWell(
                  onTap: () => _toggle(_Panel.search),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: searchActive
                                ? AppColors.primary
                                : AppColors.slate400,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            query.isEmpty ? 'Search courts' : query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyBold(
                              color: query.isEmpty
                                  ? AppColors.slate400
                                  : AppColors.slate700,
                            ).copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 22, color: AppColors.slate100),
              // Filters trigger (right)
              InkWell(
                onTap: () => _toggle(_Panel.filters),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  child: Row(
                    children: [
                      Icon(Icons.tune,
                          color: filtersActive || _panel == _Panel.filters
                              ? AppColors.primary
                              : AppColors.slate400,
                          size: 16),
                      const SizedBox(width: 6),
                      Text('FILTERS',
                          style: AppTextStyles.eyebrow(
                            color: filtersActive || _panel == _Panel.filters
                                ? AppColors.primary
                                : AppColors.slate400,
                          )),
                      const SizedBox(width: 2),
                      Icon(
                        _panel == _Panel.filters
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.slate400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: switch (_panel) {
              _Panel.none => const SizedBox(width: double.infinity),
              _Panel.search => _searchPanel(),
              _Panel.filters => _filtersPanel(sport, sortMode, asc),
            },
          ),
        ],
      ),
    );
  }

  Widget _searchPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
      child: Column(
        children: [
          const Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.slate100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.slate400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: _onQuery,
                    textInputAction: TextInputAction.search,
                    style: AppTextStyles.bodyBold(color: AppColors.slate700)
                        .copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Search courts or locations',
                      hintStyle:
                          AppTextStyles.bodyBold(color: AppColors.slate400)
                              .copyWith(fontSize: 14),
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _onQuery('');
                    },
                    child: const Icon(Icons.close,
                        color: AppColors.slate400, size: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersPanel(CourtType? sport, CourtSortMode sortMode, bool asc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 12),
          _GroupLabel(icon: Icons.sports_tennis, label: 'SPORT'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sportChip('All', null, sport),
              _sportChip('Badminton', CourtType.badminton, sport),
              _sportChip('Pickleball', CourtType.pickleball, sport),
              _sportChip('Basketball', CourtType.basketball, sport),
            ],
          ),
          const SizedBox(height: 14),
          _GroupLabel(icon: Icons.swap_vert, label: 'SORT'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sortChip('Price', CourtSortMode.price, sortMode, asc),
              _sortChip('Courts', CourtSortMode.courts, sortMode, asc),
              _sortChip('Rating', CourtSortMode.rating, sortMode, asc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sportChip(String label, CourtType? value, CourtType? current) {
    return GestureDetector(
      onTap: () => ref.read(homeFilterProvider.notifier).state = value,
      child: _chip(label.toUpperCase(), current == value),
    );
  }

  Widget _sortChip(
      String label, CourtSortMode mode, CourtSortMode current, bool asc) {
    final active = current == mode;
    return GestureDetector(
      onTap: () => cycleSort(ref, mode),
      child: _chip(
        label.toUpperCase(),
        active,
        trailing: active
            ? Icon(asc ? Icons.arrow_upward : Icons.arrow_downward,
                color: AppColors.white, size: 11)
            : null,
      ),
    );
  }

  Widget _chip(String label, bool selected, {Widget? trailing}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.slate400,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing],
        ],
      ),
    );
  }
}

// ─── Group label (Sport / Sort) ─────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.slate300, size: 13),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.microLabel(color: AppColors.slate300)),
      ],
    );
  }
}
