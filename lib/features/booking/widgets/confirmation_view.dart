import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/widgets/app_logo.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';

const _primary = Color(0xFF005F02);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);

class ConfirmationView extends ConsumerWidget {
  const ConfirmationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final court = ref.watch(selectedCourtProvider)!;
    final refCode = ref.watch(bookingRefCodeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlots = ref.watch(selectedSlotsProvider);
    final total = ref.watch(totalPriceProvider);
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userPhone = ref.watch(userPhoneProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCF9),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 64, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo + ref code header
            Row(
              children: [
                const AppLogo(size: 28),
                const SizedBox(width: 8),
                const Text(
                  'SPORTSYNC',
                  style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Reference Code', style: TextStyle(color: _slate400, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(
                        refCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Booking Confirmation.',
              style: TextStyle(color: _primary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
            ),
            const SizedBox(height: 6),
            const Text(
              'A copy of this receipt has been sent to your email.',
              style: TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Info grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _slate100),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Venue', value: court.name),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _InfoRow(
                    label: 'Date & Time',
                    value: '${DateFormat('EEE, MMM d').format(selectedDate)} • ${selectedSlots.length} slot${selectedSlots.length > 1 ? 's' : ''}',
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _InfoRow(label: 'Booked By', value: userName.isEmpty ? 'Guest' : userName),
                  if (userEmail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(userEmail, style: const TextStyle(color: _slate400, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (userPhone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(userPhone, style: const TextStyle(color: _slate400, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _InfoRow(
                    label: 'Amount Paid',
                    value: '₱$total.00',
                    valueLarge: true,
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  const _InfoRow(label: 'Payment Method', value: 'QR Ph'),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  const _InfoRow(
                    label: 'Status',
                    value: 'Verified',
                    valueColor: Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(selectedCourtProvider.notifier).state = null;
                  ref.read(bookingStepProvider.notifier).state = BookingStep.details;
                  ref.read(selectedSlotsProvider.notifier).state = [];
                  ref.read(paymentMethodProvider.notifier).state = null;
                  ref.read(bookingRefCodeProvider.notifier).state = '';
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: _primary.withValues(alpha: 0.35),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                child: const Text('BACK TO HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor, this.valueLarge = false});
  final String label, value;
  final Color? valueColor;
  final bool valueLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _slate400, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? _primary,
              fontSize: valueLarge ? 20 : 13,
              fontWeight: FontWeight.w900,
              letterSpacing: valueLarge ? -0.5 : 0,
            ),
          ),
        ),
      ],
    );
  }
}
