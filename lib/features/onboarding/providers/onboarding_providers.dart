import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/models/court.dart';

/// Flips to `true` after the onboarding sheet has shown once during the
/// current app process. Resets on cold start.
final onboardingShownThisSessionProvider = StateProvider<bool>((_) => false);

/// `true` whenever something on screen wants the floating SportSync header
/// hidden — currently the onboarding bottom sheet and the recommendations
/// screen. Each consumer is responsible for setting it on entry and clearing
/// it on exit / dismiss.
final floatingHeaderHiddenProvider = StateProvider<bool>((_) => false);

/// Sport the user picked in the sheet. `null` = Any.
final onboardingSportProvider = StateProvider<CourtType?>((_) => null);

/// Date the user picked in the sheet. Defaults to today (date-only — no time).
final onboardingDateProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Time of day the user picked in the sheet. Defaults to 6:00 PM, matching
/// the mockup's initial state.
final onboardingTimeProvider =
    StateProvider<TimeOfDay>((_) => const TimeOfDay(hour: 18, minute: 0));
