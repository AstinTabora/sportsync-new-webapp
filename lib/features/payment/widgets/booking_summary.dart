import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';

/// Collapsible booking summary chip used at the top of every payment-sheet
/// state. Tap to expand the venue/address/duration breakdown.
class BookingSummary extends StatefulWidget {
  const BookingSummary({
    super.key,
    required this.courtName,
    required this.date,
    required this.timeRange,
    required this.totalCents,
    required this.facilityAddress,
    required this.durationLabel,
    this.initiallyExpanded = false,
  });

  final String courtName;
  final String date;
  final String timeRange;
  final int totalCents;
  final String facilityAddress;
  final String durationLabel;
  final bool initiallyExpanded;

  @override
  State<BookingSummary> createState() => _BookingSummaryState();
}

class _BookingSummaryState extends State<BookingSummary> {
  late bool _expanded = widget.initiallyExpanded;

  String get _formattedTotal {
    final pesos = widget.totalCents ~/ 100;
    return '₱$pesos';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.sports_tennis,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.courtName} · ${widget.date} ${widget.timeRange} · $_formattedTotal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.pill().copyWith(
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.slate300,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.slate200),
                  const SizedBox(height: 8),
                  _Row(label: 'FACILITY', value: widget.courtName),
                  const SizedBox(height: 6),
                  _Row(label: 'ADDRESS', value: widget.facilityAddress),
                  const SizedBox(height: 6),
                  _Row(label: 'DURATION', value: widget.durationLabel),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.microLabel()),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.microLabel(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
