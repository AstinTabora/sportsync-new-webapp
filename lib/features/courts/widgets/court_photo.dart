import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/sport_icons.dart';
import 'package:sportsync/core/widgets/court_image.dart';

/// Photo placeholder for a court. Mirrors the JSX `CourtPhoto` in
/// `screens-shared.jsx`: dotted texture + green gradient + giant sport icon.
/// Falls back to the asset image if it loads, otherwise renders the placeholder.
class CourtPhoto extends StatelessWidget {
  const CourtPhoto({
    super.key,
    required this.court,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final Court court;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(court: court);

    final asset = CourtImage(
      path: court.image,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );

    if (borderRadius == null) return asset;
    return ClipRRect(borderRadius: borderRadius!, child: asset);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x4D005F02), // primary/30
            Color(0x1A005F02), // primary/10
            Color(0x66005F02), // primary/40
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sportIcon(court.type),
              color: AppColors.white.withValues(alpha: 0.9),
              size: 56,
            ),
            const SizedBox(height: 8),
            Text(
              court.type.label,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 2.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
