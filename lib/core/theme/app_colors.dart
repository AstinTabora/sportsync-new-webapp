import 'package:flutter/material.dart';

/// Design tokens — colors. Mirrors Tailwind palette in
/// `Sportsync claude design/index.html` plus the slate/status scales used
/// throughout the JSX screens.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF005F02);
  static const Color primaryDark = Color(0xFF004001);
  static const Color primaryLight = Color(0xFF008003);
  static const Color primaryExtralight = Color(0xFFE6F0E6);

  // Surface
  static const Color canvas = Color(0xFFF0EEE9); // page bg outside cards
  static const Color surface = Color(0xFFFAFAF7); // tab body bg
  static const Color white = Color(0xFFFFFFFF);

  // Slate (Tailwind-equivalent)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Status (booking pills / slot states)
  static const Color statusAmber = Color(0xFFF59E0B);
  static const Color statusAmberBg = Color(0xFFFEF3C7);
  static const Color statusEmerald = Color(0xFF10B981);
  static const Color statusEmeraldBg = Color(0xFFD1FAE5);
  static const Color statusBlue = Color(0xFF3B82F6);
  static const Color statusBlueBg = Color(0xFFDBEAFE);
  static const Color statusPurple = Color(0xFFA855F7);
  static const Color statusPurpleBg = Color(0xFFF4E6FF);

  // Booked-slot accent (matches design's `#00a651` slot color)
  static const Color slotBooked = Color(0xFF00A651);
  static const Color slotBookedBg = Color(0xFFE6F7ED);

  // Brand accents from booking flow
  static const Color gcashBlue = Color(0xFF0070E0);
}
