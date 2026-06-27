import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/sport_icons.dart';
import 'package:sportsync/features/onboarding/providers/onboarding_providers.dart';

/// Bottom-sheet shown over the home screen on cold start. Flush to the
/// screen's left, right, and bottom edges with rounded top corners.
///
/// Collects sport + date + time, then pushes the recommendations screen.
class OnboardingSheet extends ConsumerWidget {
  const OnboardingSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    ref.read(floatingHeaderHiddenProvider.notifier).state = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => const OnboardingSheet(),
      );
    } finally {
      ref.read(floatingHeaderHiddenProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = ref.watch(onboardingSportProvider);
    final date = ref.watch(onboardingDateProvider);
    final time = ref.watch(onboardingTimeProvider);

    final dates = _buildDateOptions(today: _stripTime(DateTime.now()));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl3),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Headline
                  const Text(
                    "Let's find\nyou a court.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sport row
                  _SportRow(selected: sport, ref: ref),
                  const SizedBox(height: 16),

                  // Date row
                  _DateRow(
                    selectedDate: date,
                    dates: dates,
                    onPick: (d) =>
                        ref.read(onboardingDateProvider.notifier).state = d,
                    onCalendar: () => _pickDate(context, ref, date),
                  ),
                  const SizedBox(height: 16),

                  // Time pill
                  _TimePill(
                    time: time,
                    onTap: () => _pickTime(context, ref, time),
                  ),
                  const SizedBox(height: 20),

                  // Primary CTA
                  _FindCourtsButton(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/home/recommendations');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Skip
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: Text(
                      'SKIP FOR NOW',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final today = _stripTime(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      ref.read(onboardingDateProvider.notifier).state = _stripTime(picked);
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      ref.read(onboardingTimeProvider.notifier).state = picked;
    }
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DateTime> _buildDateOptions({required DateTime today}) {
    return List.generate(6, (i) => today.add(Duration(days: i)));
  }
}

// ─── Sport row ──────────────────────────────────────────────────────────────

class _SportRow extends StatelessWidget {
  const _SportRow({required this.selected, required this.ref});

  final CourtType? selected;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final options = <_SportOption>[
      const _SportOption(label: 'Any', icon: Icons.auto_awesome, value: null),
      _SportOption(
        label: 'Badminton',
        icon: sportIcon(CourtType.badminton),
        value: CourtType.badminton,
      ),
      _SportOption(
        label: 'Pickleball',
        icon: sportIcon(CourtType.pickleball),
        value: CourtType.pickleball,
      ),
      _SportOption(
        label: 'Basketball',
        icon: sportIcon(CourtType.basketball),
        value: CourtType.basketball,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final o in options) ...[
            _SportPill(
              option: o,
              selected: o.value == selected,
              onTap: () =>
                  ref.read(onboardingSportProvider.notifier).state = o.value,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SportOption {
  const _SportOption({
    required this.label,
    required this.icon,
    required this.value,
  });
  final String label;
  final IconData icon;
  final CourtType? value;
}

class _SportPill extends StatelessWidget {
  const _SportPill({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _SportOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 14,
              color: selected ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              option.label.toUpperCase(),
              style: TextStyle(
                color: selected ? AppColors.primary : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date row ───────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.selectedDate,
    required this.dates,
    required this.onPick,
    required this.onCalendar,
  });

  final DateTime selectedDate;
  final List<DateTime> dates;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final today = OnboardingSheet._stripTime(DateTime.now());
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final d in dates) ...[
            _DateChip(
              date: d,
              label: _labelFor(d, today),
              selected: _sameDay(d, selectedDate),
              onTap: () => onPick(d),
            ),
            const SizedBox(width: 8),
          ],
          _CalendarChip(
            highlighted: !dates.any((d) => _sameDay(d, selectedDate)),
            onTap: onCalendar,
          ),
        ],
      ),
    );
  }

  String _labelFor(DateTime d, DateTime today) {
    if (_sameDay(d, today)) return 'TODAY';
    return DateFormat('EEE').format(d).toUpperCase();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: selected ? 0.8 : 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                color: fg,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarChip extends StatelessWidget {
  const _CalendarChip({required this.highlighted, required this.onTap});
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: highlighted
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: Colors.white.withValues(alpha: highlighted ? 1.0 : 0.7),
        ),
      ),
    );
  }
}

// ─── Time pill ──────────────────────────────────────────────────────────────

class _TimePill extends StatelessWidget {
  const _TimePill({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                time.format(context),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Primary CTA ────────────────────────────────────────────────────────────

class _FindCourtsButton extends StatelessWidget {
  const _FindCourtsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FIND COURTS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
