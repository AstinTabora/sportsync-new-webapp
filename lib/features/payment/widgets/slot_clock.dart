import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';

/// Thin horizontal countdown bar that drains across the top of the sheet.
/// Calm warm yellow → alert orange in the final 60 seconds.
class SlotClock extends StatefulWidget {
  const SlotClock({
    super.key,
    required this.expiresAt,
    this.ttl = const Duration(minutes: 5),
  });

  final DateTime expiresAt;
  final Duration ttl;

  @override
  State<SlotClock> createState() => _SlotClockState();
}

class _SlotClockState extends State<SlotClock> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final progress =
        (clamped.inMilliseconds / widget.ttl.inMilliseconds).clamp(0.0, 1.0);
    final alert = clamped.inSeconds <= 60 && clamped.inSeconds > 0;
    final expired = clamped == Duration.zero;

    final m = clamped.inMinutes;
    final s = clamped.inSeconds % 60;
    final label = expired
        ? 'slot released'
        : 'slot held for $m:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 3, color: AppColors.slate100),
                LayoutBuilder(builder: (context, c) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    width: c.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: alert
                            ? const [Color(0xFFF59E0B), Color(0xFFF97316)]
                            : const [Color(0xFFF5C443), Color(0xFFF0A93B)],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.microLabel(
                  color: alert
                      ? const Color(0xFFEA580C)
                      : AppColors.slate500,
                ).copyWith(fontSize: 10, letterSpacing: 1.6),
              ),
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: alert
                    ? const Color(0xFFF97316)
                    : AppColors.slate300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
