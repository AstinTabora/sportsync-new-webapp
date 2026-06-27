import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/booking/widgets/user_form_modal.dart';
import 'package:sportsync/features/payment/widgets/payment_sheet.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

/// Step 3 of 4 — payment. Single method: QR Ph (pay now) via PayMongo.
class PaymentView extends ConsumerWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final court = ref.watch(selectedCourtProvider)!;
    final slots = ref.watch(selectedSlotsProvider);
    final total = ref.watch(totalPriceProvider);
    final date = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              children: [
                _BookingHeader(courtName: court.name, onBack: () {
                  ref.read(bookingStepProvider.notifier).state =
                      BookingStep.calendar;
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl3),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: AppShadows.cardSubtle,
                  ),
                  child: Column(
                    children: [
                      Text('STEP 3 OF 4', style: AppTextStyles.eyebrow()),
                      const SizedBox(height: 4),
                      Text('CHOOSE PAYMENT',
                          style: AppTextStyles.headingBlack()),
                      const SizedBox(height: 4),
                      Text("Scan the QR code to pay and confirm instantly",
                          style:
                              AppTextStyles.bodyBold(color: AppColors.slate500)),
                      const SizedBox(height: 20),
                      _Summary(
                        venue: court.name,
                        date: DateFormat('EEE, MMM d').format(date),
                        slots: slots.length,
                        total: total,
                      ),
                      const SizedBox(height: 20),
                      _MethodCard(
                        highlighted: true,
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Center(
                            child: Icon(Icons.qr_code_2,
                                color: AppColors.white, size: 28),
                          ),
                        ),
                        title: 'PAY NOW',
                        subtitle: 'QR Ph · Scan to pay · Instant confirmation',
                        onTap: () async {
                          ref.read(paymentMethodProvider.notifier).state =
                              BookingPaymentMethod.gcash;
                          _prefillFromProfile(ref);
                          final submitted = await showUserFormModal(context);
                          if (submitted != true) return;
                          if (!context.mounted) return;
                          showPaymentSheet(context, ref);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('SECURED BY SPORTSYNC',
                          style:
                              AppTextStyles.microLabel(color: AppColors.slate300)
                                  .copyWith(fontSize: 9, letterSpacing: 1.6)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Seed the details form from the signed-in (non-anonymous) user's saved
/// profile so the "Your Details" modal opens pre-filled. Guests are left as-is.
void _prefillFromProfile(WidgetRef ref) {
  final auth = ref.read(authStateProvider).asData?.value;
  if (auth == null || auth.isAnonymous) return;
  final profile = ref.read(userProfileProvider).asData?.value;
  if (profile == null) return;
  if (profile.displayName.isNotEmpty) {
    ref.read(userNameProvider.notifier).state = profile.displayName;
  }
  if (profile.email.isNotEmpty) {
    ref.read(userEmailProvider.notifier).state = profile.email;
  }
  if (profile.phone.isNotEmpty) {
    ref.read(userPhoneProvider.notifier).state = profile.phone;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.venue,
    required this.date,
    required this.slots,
    required this.total,
  });
  final String venue;
  final String date;
  final int slots;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          _Row(label: 'VENUE', value: venue),
          const SizedBox(height: 8),
          _Row(label: 'DATE', value: date),
          const SizedBox(height: 8),
          _Row(label: 'SLOTS', value: '$slots × 1hr'),
          const SizedBox(height: 8),
          const Divider(color: AppColors.slate200, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: AppTextStyles.eyebrow()),
              Text('₱$total', style: AppTextStyles.priceMega()),
            ],
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
        Text(label, style: AppTextStyles.eyebrow()),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.eyebrow(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.highlighted,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool highlighted;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(
            color: highlighted ? AppColors.primary : AppColors.slate200,
            width: highlighted ? 2 : 1,
          ),
          boxShadow: highlighted ? AppShadows.card : null,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.pageTitle()),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodyBold(color: AppColors.slate400)
                          .copyWith(fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: highlighted ? AppColors.primary : AppColors.slate300,
                size: 18),
          ],
        ),
      ),
    );
  }
}

/// Shared back-header used across booking-flow steps. Mirrors `BookingHeader`
/// in `screens-booking.jsx`.
class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.courtName, required this.onBack});
  final String courtName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back,
                      color: AppColors.slate400, size: 14),
                  const SizedBox(width: 6),
                  Text('BACK',
                      style: AppTextStyles.microLabel(color: AppColors.slate400)
                          .copyWith(fontSize: 10, letterSpacing: 1.6)),
                ],
              ),
            ),
          ),
          Text(
            courtName.split(' ').take(2).join(' ').toUpperCase(),
            style: AppTextStyles.microLabel(color: AppColors.primary)
                .copyWith(fontSize: 10, letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }
}
