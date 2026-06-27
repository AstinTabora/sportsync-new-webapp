import 'package:flutter/material.dart';

/// Renders a court cover image from either a network URL (admin-uploaded to
/// Firebase Storage — `https://…`) or a bundled asset path (legacy seed
/// courts — `assets/…`). Picks the right loader from the path scheme so both
/// sources work after the Firestore migration.
class CourtImage extends StatelessWidget {
  const CourtImage({
    super.key,
    required this.path,
    required this.errorBuilder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final ImageErrorWidgetBuilder errorBuilder;
  final BoxFit fit;
  final double? width;
  final double? height;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFE6F0E6),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF005F02),
              ),
            ),
          );
        },
      );
    }
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
