import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/booking/widgets/calendar_view.dart';
import 'package:sportsync/features/booking/widgets/confirmation_view.dart';
import 'package:sportsync/features/booking/widgets/court_detail_view.dart';
import 'package:sportsync/features/booking/widgets/payment_view.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  @override
  void initState() {
    super.initState();
    // Generate a single ref code for this booking session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final court = ref.read(selectedCourtProvider);
      final existing = ref.read(bookingRefCodeProvider);
      if (court != null && existing.isEmpty) {
        ref.read(bookingRefCodeProvider.notifier).state =
            generateRefCode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final court = ref.watch(selectedCourtProvider);
    final step = ref.watch(bookingStepProvider);

    if (court == null) return const _EmptyState();

    return switch (step) {
      BookingStep.details      => const CourtDetailView(),
      BookingStep.calendar     => const CalendarView(),
      BookingStep.payment      => const PaymentView(),
      BookingStep.confirmation => const ConfirmationView(),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryExtralight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(Icons.sports_tennis,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text('NO COURT SELECTED', style: AppTextStyles.pageTitle()),
              const SizedBox(height: 8),
              Text(
                'Go to Home and tap BOOK or DETAILS\non a court to get started.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyBold(color: AppColors.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
