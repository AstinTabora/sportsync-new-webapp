import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';

const _primary = Color(0xFF005F02);
const _slate50 = Color(0xFFF8FAFC);
const _slate400 = Color(0xFF94A3B8);

const List<String> _timeSlots = [
  '8am - 9am', '9am - 10am', '10am - 11am', '11am - 12pm',
  '12pm - 1pm', '1pm - 2pm', '2pm - 3pm', '3pm - 4pm',
  '4pm - 5pm', '5pm - 6pm', '6pm - 7pm', '7pm - 8pm',
  '8pm - 9pm', '9pm - 10pm', '10pm - 11pm', '11pm - 12am',
];

enum _SlotStatus { available, selected, booked, blocked, openPlay, closing, past }

class TimeSlotGrid extends ConsumerWidget {
  const TimeSlotGrid({super.key, required this.courtCount});
  final int courtCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlots = ref.watch(selectedSlotsProvider);
    // Merge session-local booked slots with the Firestore source of truth
    // (paid bookings written server-side).
    final bookedSlots = <BookedSlot>[
      ...ref.watch(bookedSlotsProvider),
      ...?ref.watch(courtBookedSlotsProvider).asData?.value,
    ];
    final blockouts =
        ref.watch(courtBlockoutsProvider).asData?.value ?? const [];
    final court = ref.watch(selectedCourtProvider)!;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(now) == dateStr;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _headerCell('TIME', width: 90),
              for (var i = 1; i <= courtCount; i++)
                _headerCell('Court $i', width: 100),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Slot rows
          for (final time in _timeSlots)
            Row(
              children: [
                _timeCell(time),
                for (var i = 1; i <= courtCount; i++) ...[
                  Builder(builder: (context) {
                    final courtName = 'Court $i';
                    final status = _getStatus(
                      courtName: courtName,
                      time: time,
                      dateStr: dateStr,
                      facilityId: court.id,
                      isToday: isToday,
                      now: now,
                      selectedSlots: selectedSlots,
                      bookedSlots: bookedSlots,
                      blockouts: blockouts,
                      courtIndex: i,
                    );
                    return _SlotCell(
                      status: status,
                      time: time,
                      courtName: courtName,
                      onTap: status == _SlotStatus.available || status == _SlotStatus.selected
                          ? () => _toggleSlot(ref, courtName, time, selectedSlots)
                          : null,
                    );
                  }),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {required double width}) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        color: _slate50,
        child: Text(
          label,
          style: const TextStyle(
            color: _slate400,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _timeCell(String time) => Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: const BoxDecoration(
          color: _slate50,
          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Text(
          time,
          style: const TextStyle(
            color: _slate400,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      );

  _SlotStatus _getStatus({
    required String courtName,
    required String time,
    required String dateStr,
    required String facilityId,
    required bool isToday,
    required DateTime now,
    required List<SelectedSlot> selectedSlots,
    required List<BookedSlot> bookedSlots,
    required List<CourtBlockout> blockouts,
    required int courtIndex,
  }) {
    // past check
    if (isToday) {
      final hour = _parseStartHour(time);
      if (hour < now.hour) return _SlotStatus.past;
    }
    final dateIsPast = _isDateBefore(dateStr, now);
    if (dateIsPast) return _SlotStatus.past;

    // selected
    if (selectedSlots.any((s) => s.court == courtName && s.time == time)) {
      return _SlotStatus.selected;
    }

    // booked
    if (bookedSlots.any((s) =>
        s.facilityId == facilityId &&
        s.date == dateStr &&
        s.court == courtName &&
        s.time == time)) {
      return _SlotStatus.booked;
    }

    // blocked-out by the court owner (whole-day or specific slot times)
    final hhmm = _toHHmm(time);
    for (final b in blockouts) {
      if (dateStr.compareTo(b.startDate) < 0) continue;
      if (dateStr.compareTo(b.endDate) > 0) continue;
      if (b.slots == null || b.slots!.contains(hhmm)) {
        return _SlotStatus.blocked;
      }
    }

    // open-play: 5pm-8pm on courts 4-6
    if (courtIndex >= 4 && courtIndex <= 6) {
      final hour = _parseStartHour(time);
      if (hour >= 17 && hour < 20) return _SlotStatus.openPlay;
    }

    // closing: 10pm-11pm
    if (time == '10pm - 11pm') return _SlotStatus.closing;

    return _SlotStatus.available;
  }

  void _toggleSlot(
    WidgetRef ref,
    String courtName,
    String time,
    List<SelectedSlot> current,
  ) {
    final notifier = ref.read(selectedSlotsProvider.notifier);
    final exists = current.any((s) => s.court == courtName && s.time == time);
    if (exists) {
      notifier.state = current.where((s) => !(s.court == courtName && s.time == time)).toList();
    } else {
      if (current.length >= 9) return;
      notifier.state = [...current, (court: courtName, time: time)];
    }
  }

  int _parseStartHour(String time) {
    final start = time.split(' - ').first.trim().toLowerCase();
    if (start == '12am') return 0;
    if (start == '12pm') return 12;
    final num = int.tryParse(start.replaceAll(RegExp(r'[apm]'), '')) ?? 0;
    return start.endsWith('pm') ? num + 12 : num;
  }

  String _toHHmm(String label) {
    final h = _parseStartHour(label);
    return '${h.toString().padLeft(2, '0')}:00';
  }

  bool _isDateBefore(String dateStr, DateTime now) {
    final today = DateFormat('yyyy-MM-dd').format(now);
    return dateStr.compareTo(today) < 0;
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.status,
    required this.time,
    required this.courtName,
    required this.onTap,
  });
  final _SlotStatus status;
  final String time;
  final String courtName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Widget? child;

    switch (status) {
      case _SlotStatus.available:
        bg = Colors.white;
        border = const Color(0xFFE2E8F0);
      case _SlotStatus.selected:
        bg = _primary;
        border = _primary;
        child = const Icon(Icons.check, color: Colors.white, size: 14);
      case _SlotStatus.booked:
        bg = const Color(0xFFE6F7ED);
        border = const Color(0xFF00A651);
        child = const Icon(Icons.access_time, color: Color(0xFF00A651), size: 14);
      case _SlotStatus.blocked:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFEF4444);
        child = const Icon(Icons.block, color: Color(0xFFEF4444), size: 12);
      case _SlotStatus.openPlay:
        bg = const Color(0xFFF4E6FF);
        border = const Color(0xFFA855F7);
        child = const Text(
          'OPEN\nPLAY',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFA855F7), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        );
      case _SlotStatus.closing:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        child = const Text(
          'Closing',
          style: TextStyle(color: _slate400, fontSize: 8, fontWeight: FontWeight.w700),
        );
      case _SlotStatus.past:
        bg = _slate50;
        border = const Color(0xFFE2E8F0);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 0.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
