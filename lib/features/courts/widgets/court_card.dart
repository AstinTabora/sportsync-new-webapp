import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/theme/sport_icons.dart';
import 'package:sportsync/core/widgets/court_image.dart';

const _primary = Color(0xFF005F02);
const _primaryExtralight = Color(0xFFE6F0E6);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);

class CourtCard extends StatelessWidget {
  const CourtCard({
    super.key,
    required this.court,
    required this.openToday,
    required this.onDetails,
    required this.onBook,
  });

  final Court court;
  final int openToday;
  final VoidCallback onDetails;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: _slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageSection(court: court, openToday: openToday),
          _BodySection(
            court: court,
            onDetails: onDetails,
            onBook: onBook,
          ),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.court, required this.openToday});

  final Court court;
  final int openToday;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CourtImage(
            path: court.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _primaryExtralight,
              child: const Icon(Icons.sports, color: _primary, size: 48),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                _Badge(
                  bgColor: _primary,
                  child: Icon(sportIcon(court.type),
                      color: Colors.white, size: 13),
                ),
                const SizedBox(width: 6),
                _Badge(
                  bgColor: Colors.white.withValues(alpha: 0.95),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${court.numberOfCourts}',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/icons/court.png',
                        width: 12,
                        height: 12,
                        color: _primary,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _Badge(
              bgColor: openToday > 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFF1E293B).withValues(alpha: 0.80),
              child: Text(
                openToday > 0 ? '$openToday open today' : 'Full today',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child, required this.bgColor});

  final Widget child;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BodySection extends StatelessWidget {
  const _BodySection({
    required this.court,
    required this.onDetails,
    required this.onBook,
  });

  final Court court;
  final VoidCallback onDetails;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  court.name,
                  style: AppTextStyles.cardTitle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryExtralight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: _primary, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      court.rating.toString(),
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: _primary, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  court.location.toUpperCase(),
                  style: const TextStyle(
                    color: _slate400,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: court.amenities.take(3).map((a) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _slate100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  a.toUpperCase(),
                  style: const TextStyle(
                    color: _slate400,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₱${court.price.toInt()}',
                        style: AppTextStyles.price(),
                      ),
                      const TextSpan(
                        text: '/hr',
                        style: TextStyle(
                          color: _slate400,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    child: const Text('DETAILS'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    child: const Text('BOOK'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
