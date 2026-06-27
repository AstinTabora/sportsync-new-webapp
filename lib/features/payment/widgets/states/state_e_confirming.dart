import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';

/// State E — webhook race. User came back via deep link; we're waiting for
/// PayMongo's webhook to land and the Firestore stream to flip the booking
/// status to `paid`.
class ConfirmingState extends StatelessWidget {
  const ConfirmingState({
    super.key,
    required this.summary,
    required this.onCheckStatus,
  });

  final BookingSummary summary;

  /// Manual reconcile trigger, in case the webhook is slow or never arrives.
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: AppColors.slate100,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryExtralight,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.primary, size: 24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('confirming…',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingBlack().copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            'we got your payment. just locking in the slot.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold(color: AppColors.slate500)
                .copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusAmberBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.statusAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.statusAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AWAITING PAYMENT CONFIRMATION',
                    style: AppTextStyles.microLabel(
                            color: const Color(0xFFB45309))
                        .copyWith(fontSize: 9, letterSpacing: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCheckStatus,
            child: Text(
              'CHECK STATUS NOW',
              style: AppTextStyles.microLabel(color: AppColors.primary)
                  .copyWith(fontSize: 10, letterSpacing: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
