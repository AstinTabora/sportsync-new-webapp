import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';

/// State F — "paid. you're in." Calm utility, no celebration confetti.
class SuccessState extends StatelessWidget {
  const SuccessState({
    super.key,
    required this.refCode,
    required this.userEmail,
    required this.summary,
    required this.onAddToCalendar,
    required this.onViewBooking,
  });

  final String refCode;
  final String userEmail;
  final BookingSummary summary;
  final VoidCallback onAddToCalendar;
  final VoidCallback onViewBooking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl2),
                boxShadow: AppShadows.card,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: AppColors.white, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          Text("paid. you're in.",
              textAlign: TextAlign.center,
              style: AppTextStyles.headingBlack().copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyBold(color: AppColors.slate500)
                  .copyWith(fontSize: 12),
              children: [
                const TextSpan(text: 'ref '),
                TextSpan(
                  text: refCode,
                  style: AppTextStyles.bodyBold(color: AppColors.primary)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                TextSpan(text: ' · sent to $userEmail'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddToCalendar,
                  icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: Text(
                    'ADD TO CALENDAR',
                    style: AppTextStyles.microLabel(color: AppColors.primary)
                        .copyWith(fontSize: 10, letterSpacing: 1.6),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl2),
                    ),
                    side: const BorderSide(color: AppColors.slate200),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onViewBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl2),
                    ),
                  ),
                  child: Text('VIEW BOOKING',
                      style: AppTextStyles.ctaLabel().copyWith(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
