import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';

/// Design tokens — shadows. Tuned to match the Tailwind shadow profile in the
/// design package (`shadow-sm`, `shadow-xl`, `shadow-2xl`, plus the colored
/// `shadow-primary/30` glow used on CTAs).
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> pillFloating = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cta = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> imageHero = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 60,
      offset: Offset(0, 20),
    ),
  ];

  // Inverse drop-shadow for floating bottom bars (Court Detail Book-Now,
  // Booking calendar Proceed bar).
  static const List<BoxShadow> floatingBar = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];
}
