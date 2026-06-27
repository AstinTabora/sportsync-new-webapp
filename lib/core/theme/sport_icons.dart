import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';

/// Maps a sport type to a Material icon. The design uses Font Awesome glyphs;
/// these are the closest Material equivalents that ship with Flutter without
/// adding a font asset.
IconData sportIcon(CourtType type) {
  switch (type) {
    case CourtType.badminton:
      return Icons.sports_tennis;
    case CourtType.pickleball:
      return Icons.sports_baseball;
    case CourtType.basketball:
      return Icons.sports_basketball;
  }
}

IconData sportIconForName(String name) {
  switch (name.toLowerCase()) {
    case 'badminton':
      return Icons.sports_tennis;
    case 'pickleball':
      return Icons.sports_baseball;
    case 'basketball':
      return Icons.sports_basketball;
    default:
      return Icons.sports;
  }
}
