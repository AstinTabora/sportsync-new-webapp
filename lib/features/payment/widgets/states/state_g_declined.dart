import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';

/// State G — declined / cancelled. The hold is still active so the user
/// can retry. Header turns rose; body stays calm.
class DeclinedState extends StatelessWidget {
  const DeclinedState({
    super.key,
    required this.reason,
    required this.summary,
    required this.onRetry,
  });

  final String reason;
  final BookingSummary summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('try again.',
              style: AppTextStyles.headingBlack(
                      color: const Color(0xFFE11D48))
                  .copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyBold(color: AppColors.slate500)
                  .copyWith(fontSize: 12),
              children: [
                const TextSpan(text: 'we couldn’t complete that one — '),
                TextSpan(
                  text: reason,
                  style: AppTextStyles.bodyBold(
                          color: const Color(0xFFE11D48))
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const TextSpan(text: '. your slot is still held.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, color: AppColors.white, size: 20),
                const SizedBox(width: 12),
                Text('RETRY PAYMENT',
                    style: AppTextStyles.ctaLabel().copyWith(fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, color: AppColors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
