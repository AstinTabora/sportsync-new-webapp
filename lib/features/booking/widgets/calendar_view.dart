import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/booking/widgets/time_slot_grid.dart';

const _primary = Color(0xFF005F02);
const _slate400 = Color(0xFF94A3B8);

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final court = ref.watch(selectedCourtProvider)!;
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlots = ref.watch(selectedSlotsProvider);
    final total = ref.watch(totalPriceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCF9),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, MediaQuery.of(context).padding.top + 64, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${court.name}',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a date and time to reserve your slot.',
                        style: TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      _DateSelector(selectedDate: selectedDate, ref: ref),
                      const SizedBox(height: 24),
                      _Legend(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: TimeSlotGrid(courtCount: court.numberOfCourts.clamp(1, 8)),
                ),
              ),
            ],
            ),
          ),
          // Floating action bar
          if (selectedSlots.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _FloatingBar(
                slots: selectedSlots.length,
                total: total,
                onProceed: () {
                  ref.read(bookingStepProvider.notifier).state = BookingStep.payment;
                  ref.read(paymentMethodProvider.notifier).state = null;
                  // Ref code is generated once in BookingScreen.initState
                  // and persists for the duration of the booking session.
                  if (ref.read(bookingRefCodeProvider).isEmpty) {
                    ref.read(bookingRefCodeProvider.notifier).state =
                        generateRefCode();
                  }
                },
                onClear: () => ref.read(selectedSlotsProvider.notifier).state = [],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Date selector ───────────────────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.ref});
  final DateTime selectedDate;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...days.map((d) {
            final isSelected = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(selectedDate);
            final label = d.day == today.day && d.month == today.month ? 'TODAY' : DateFormat('EEE').format(d).toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ref.read(selectedDateProvider.notifier).state = d,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? _primary : const Color(0xFFE2E8F0)),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _slate400,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : _primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: _primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).state = picked;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Text('MORE', style: TextStyle(color: _slate400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  SizedBox(height: 2),
                  Icon(Icons.calendar_month, color: _primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend ──────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(label: 'Available', color: Colors.white, borderColor: Color(0xFFE2E8F0)),
        _LegendItem(label: 'Selected', color: _primary, borderColor: _primary),
        _LegendItem(label: 'Booked', color: Color(0xFFE6F7ED), borderColor: Color(0xFF00A651)),
        _LegendItem(label: 'Open-Play', color: Color(0xFFF4E6FF), borderColor: Color(0xFFA855F7)),
        _LegendItem(label: 'Closing', color: Color(0xFFF8FAFC), borderColor: Color(0xFFE2E8F0)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color, required this.borderColor});
  final String label;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _slate400, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Floating action bar ─────────────────────────────────────────────────────

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.slots,
    required this.total,
    required this.onProceed,
    required this.onClear,
  });
  final int slots;
  final int total;
  final VoidCallback onProceed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$slots slot${slots > 1 ? 's' : ''} selected',
                  style: const TextStyle(color: _slate400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                Text(
                  '₱$total total',
                  style: const TextStyle(color: _primary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: _slate400, size: 18),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: _primary.withValues(alpha: 0.35),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            child: const Text('PROCEED TO PAY'),
          ),
        ],
      ),
    );
  }
}
