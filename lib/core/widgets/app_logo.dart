import 'package:flutter/material.dart';

/// The official SportSync logo mark (pickleball + S/C monogram).
///
/// Transparent PNG — render it on a light surface for best contrast. On dark
/// surfaces, wrap it in a light badge (see the About header).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sportsync_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
