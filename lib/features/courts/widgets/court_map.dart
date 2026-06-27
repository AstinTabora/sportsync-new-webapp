import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';

// Conditional import: web uses an HTML iframe, all other platforms get a
// styled placeholder. Each side exports `buildCourtMap(Court court)`.
import 'court_map_stub.dart'
    if (dart.library.html) 'court_map_web.dart' as impl;

/// Inline map preview for a court detail screen.
///
/// On web this renders Google's iframe embed (same as the SportSync v2
/// website) — no API key required. On mobile platforms it falls back to a
/// styled placeholder; the surrounding screen still shows a Directions
/// button that opens Google Maps externally.
class CourtMap extends StatelessWidget {
  const CourtMap({super.key, required this.court});
  final Court court;

  @override
  Widget build(BuildContext context) => impl.buildCourtMap(court);
}
