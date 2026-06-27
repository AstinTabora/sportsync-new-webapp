import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/payment/widgets/booking_summary.dart';

/// State B (default first-time user) + C (final-60s warning). The slot
/// clock above already swaps to alert colors based on remaining time, so
/// this widget can stay color-stable. QRPh is the only enabled method, so a
/// single "scan to pay" CTA is shown.
class FirstTimePayState extends StatelessWidget {
  const FirstTimePayState({
    super.key,
    required this.totalCents,
    required this.summary,
    required this.onPay,
    this.warning = false,
  });

  final int totalCents;
  final BookingSummary summary;
  final VoidCallback onPay;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final pesos = totalCents ~/ 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('pay ₱$pesos.',
              style: AppTextStyles.headingBlack().copyWith(fontSize: 26)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: summary,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _QrphTile(onTap: onPay),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Scan the QR with any GCash, Maya, or bank app that supports QR Ph.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold(color: AppColors.slate400)
                .copyWith(fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _QrphTile extends StatelessWidget {
  const _QrphTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_2,
                  color: AppColors.white, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCAN TO PAY',
                      style: AppTextStyles.microLabel(color: AppColors.primary)
                          .copyWith(fontSize: 13, letterSpacing: 1.6)),
                  const SizedBox(height: 2),
                  Text('QR Ph · Instant confirmation',
                      style: AppTextStyles.bodyBold(color: AppColors.slate400)
                          .copyWith(fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
