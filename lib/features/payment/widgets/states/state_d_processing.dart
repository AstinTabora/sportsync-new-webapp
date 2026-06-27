import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';

/// State D — "opening checkout…". The user has been redirected to the QR Ph
/// checkout page. We wait for them to come back via deep link.
class ProcessingState extends StatelessWidget {
  const ProcessingState({
    super.key,
    required this.summary,
    required this.onCancel,
    required this.onCheckStatus,
  });

  final BookingSummary summary;
  final VoidCallback onCancel;

  /// "I've paid — check status": asks the server to confirm with PayMongo,
  /// for when the automatic return / webhook were missed.
  final VoidCallback onCheckStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _Spinner()),
          const SizedBox(height: 16),
          Text('opening checkout…',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingBlack().copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            'scan the QR to pay, then come back here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold(color: AppColors.slate500)
                .copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCheckStatus,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl2),
              ),
            ),
            child: Text(
              "I'VE PAID — CHECK STATUS",
              style: AppTextStyles.microLabel(color: AppColors.primary)
                  .copyWith(fontSize: 10, letterSpacing: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'CANCEL PAYMENT',
              style: AppTextStyles.microLabel(color: AppColors.slate400)
                  .copyWith(fontSize: 10, letterSpacing: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.qr_code_2,
                color: AppColors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
