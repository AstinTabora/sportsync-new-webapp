import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/data/alternate_slots_service.dart';

/// State H — slot expired. Show up to 3 nearest alternates.
class ExpiredState extends StatelessWidget {
  const ExpiredState({
    super.key,
    required this.alternates,
    required this.onPickAlternate,
    required this.onSeeAll,
  });

  final List<AlternateSlot> alternates;
  final ValueChanged<AlternateSlot> onPickAlternate;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("slot's gone.",
              style: AppTextStyles.headingBlack().copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            'we held it for 5 minutes. here\'s what\'s still open near the same time —',
            style: AppTextStyles.bodyBold(color: AppColors.slate500)
                .copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (alternates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'no nearby slots available right now.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyBold(color: AppColors.slate400),
              ),
            )
          else
            ...alternates.map((a) => _AltRow(slot: a, onTap: () => onPickAlternate(a))),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'SEE ALL AVAILABLE SLOTS',
              style: AppTextStyles.microLabel(color: AppColors.slate500)
                  .copyWith(fontSize: 10, letterSpacing: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AltRow extends StatelessWidget {
  const _AltRow({required this.slot, required this.onTap});
  final AlternateSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryExtralight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.sports_tennis,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${slot.court} · ${slot.time}',
                        style: AppTextStyles.pill().copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${slot.label} · ₱${slot.price}',
                        style: AppTextStyles.microLabel(color: AppColors.slate400)
                            .copyWith(fontSize: 10, letterSpacing: 0)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
