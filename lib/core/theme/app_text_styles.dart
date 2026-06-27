import 'package:flutter/material.dart';
import 'package:sportsync/core/theme/app_colors.dart';

/// Design tokens — semantic text styles. All app typography flows through
/// here so a single change ripples everywhere.
///
/// Font: Apple system font stack (SF Pro on iOS/macOS, system-ui on web,
/// Roboto fallback on Android). Avoids bundling a custom font.
class AppTextStyles {
  AppTextStyles._();

  /// Primary font family. iOS/macOS resolve `-apple-system` → SF Pro.
  /// Web browsers resolve via the CSS system-font stack. On Android,
  /// `fontFamilyFallback` reaches `Roboto`.
  static const String _fontFamily = '-apple-system';
  static const List<String> _fallback = [
    'BlinkMacSystemFont',
    'SF Pro Text',
    'SF Pro Display',
    'system-ui',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle _base(
    double size,
    FontWeight weight, {
    double letterSpacing = 0,
    Color color = AppColors.primary,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fallback,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  // ─── Display / heading scale ──────────────────────────────────────────────
  // Big, heavy, brand-forward. Reserved for hero text and top-of-page titles.

  /// Hero — "PLAN LESS / PLAY MORE."  (text-5xl black, very tight tracking).
  static TextStyle displayBlack({Color color = AppColors.primary}) =>
      _base(40, FontWeight.w900,
          letterSpacing: -1.6, color: color, height: 0.9);

  /// Page heading — "MY BOOKINGS", "EDIT PROFILE".
  static TextStyle headingBlack({Color color = AppColors.primary}) =>
      _base(28, FontWeight.w900,
          letterSpacing: -1.0, color: color, height: 1.0);

  /// Card / section title — court name on a card.
  static TextStyle cardTitle({Color color = AppColors.primary}) =>
      _base(20, FontWeight.w800,
          letterSpacing: -0.4, color: color, height: 1.15);

  /// Sub-page title — "ABOUT SPORTSYNC".
  static TextStyle pageTitle({Color color = AppColors.primary}) =>
      _base(17, FontWeight.w800,
          letterSpacing: -0.3, color: color, height: 1.1);

  // ─── Body scale ───────────────────────────────────────────────────────────

  /// Body — descriptions, paragraph copy.
  static TextStyle body({Color color = AppColors.slate600}) =>
      _base(13, FontWeight.w400, color: color, height: 1.5);

  /// Body bold — list rows, strong inline copy.
  static TextStyle bodyBold({Color color = AppColors.slate600}) =>
      _base(13, FontWeight.w600, color: color, height: 1.4);

  // ─── Eyebrow / micro labels ───────────────────────────────────────────────
  // Tiny uppercase labels for chips, pills, captions, "step n of n", etc.

  /// Eyebrow — "MEMBER SINCE 2026", "STEP 3 OF 4".
  static TextStyle eyebrow({Color color = AppColors.slate400}) =>
      _base(10, FontWeight.w700, letterSpacing: 1.8, color: color);

  /// Micro label — chip text, tab badges. Smaller than eyebrow.
  static TextStyle microLabel({Color color = AppColors.slate400}) =>
      _base(9, FontWeight.w700, letterSpacing: 1.2, color: color);

  /// Pill / row label — menu rows, contact rows.
  static TextStyle pill({Color color = AppColors.primary}) =>
      _base(12, FontWeight.w700, letterSpacing: 1.0, color: color);

  // ─── Numbers + CTAs ───────────────────────────────────────────────────────

  /// Price — "₱350" on a court card.
  static TextStyle price({Color color = AppColors.primary}) =>
      _base(22, FontWeight.w800, letterSpacing: -0.6, color: color, height: 1.0);

  /// Mega price — Court Detail floating bar, payment summary total.
  static TextStyle priceMega({Color color = AppColors.primary}) =>
      _base(26, FontWeight.w900, letterSpacing: -0.8, color: color, height: 1.0);

  /// Stat number — "12" / "24h" / "4.9" on Profile.
  static TextStyle statNumber({Color color = AppColors.primary}) =>
      _base(22, FontWeight.w800, letterSpacing: -0.6, color: color, height: 1.0);

  /// CTA button label — "BOOK NOW", "SAVE CHANGES".
  static TextStyle ctaLabel({Color color = AppColors.white}) =>
      _base(13, FontWeight.w800, letterSpacing: 1.6, color: color);

  /// Wordmark — "SPORTSYNC".
  static TextStyle wordmark({Color color = AppColors.primary, double size = 16}) =>
      _base(size, FontWeight.w900, letterSpacing: -0.3, color: color);
}
