import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/models/court.dart';
import 'package:sportsync/features/courts/data/courts_repository.dart';

/// `null` means All sports.
final homeFilterProvider = StateProvider<CourtType?>((ref) => null);

enum CourtSortMode {
  defaultOrder,
  price,
  courts,
  rating,
}

final homeSortProvider = StateProvider<CourtSortMode>(
  (ref) => CourtSortMode.defaultOrder,
);

/// Sort direction for the active [homeSortProvider] mode. Irrelevant while the
/// mode is [CourtSortMode.defaultOrder].
final homeSortAscendingProvider = StateProvider<bool>((ref) => true);

/// 3-state sort cycle for [mode], driven by tapping a sort chip:
/// not-selected → ascending → descending → reset (back to default order).
/// Only one sort mode is ever active at a time.
void cycleSort(WidgetRef ref, CourtSortMode mode) {
  final current = ref.read(homeSortProvider);
  if (current != mode) {
    ref.read(homeSortProvider.notifier).state = mode;
    ref.read(homeSortAscendingProvider.notifier).state = true;
  } else if (ref.read(homeSortAscendingProvider)) {
    ref.read(homeSortAscendingProvider.notifier).state = false;
  } else {
    ref.read(homeSortProvider.notifier).state = CourtSortMode.defaultOrder;
    ref.read(homeSortAscendingProvider.notifier).state = true;
  }
}

final homeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Home court-list density: full [CourtCard] vs the compact horizontal row.
enum HomeViewMode { regular, compact }

final homeViewModeProvider =
    StateProvider<HomeViewMode>((ref) => HomeViewMode.regular);

/// Sync facade over the Firestore stream — empty while loading. Callers that
/// need to distinguish loading from empty should watch [courtsStreamProvider]
/// directly.
final courtsListProvider = Provider<List<Court>>(
  (ref) => ref.watch(courtsStreamProvider).asData?.value ?? const <Court>[],
);

final filteredCourtsProvider = Provider<List<Court>>((ref) {
  final courts = ref.watch(courtsListProvider);
  final filter = ref.watch(homeFilterProvider);
  final sort = ref.watch(homeSortProvider);
  final ascending = ref.watch(homeSortAscendingProvider);
  final query = ref.watch(homeSearchQueryProvider).trim().toLowerCase();

  var list = List<Court>.from(courts);

  if (filter != null) {
    list = list.where((c) => c.type == filter).toList();
  }

  if (query.isNotEmpty) {
    list = list.where((c) {
      final n = c.name.toLowerCase();
      final loc = c.location.toLowerCase();
      final amenities = c.amenities.join(' ').toLowerCase();
      final desc = c.description.toLowerCase();
      return n.contains(query) ||
          loc.contains(query) ||
          amenities.contains(query) ||
          desc.contains(query);
    }).toList();
  }

  if (sort != CourtSortMode.defaultOrder) {
    int ascCompare(Court a, Court b) {
      switch (sort) {
        case CourtSortMode.price:
          return a.price.compareTo(b.price);
        case CourtSortMode.courts:
          return a.numberOfCourts.compareTo(b.numberOfCourts);
        case CourtSortMode.rating:
          return a.rating.compareTo(b.rating);
        case CourtSortMode.defaultOrder:
          return 0;
      }
    }

    list.sort((a, b) => ascending ? ascCompare(a, b) : ascCompare(b, a));
  }

  return list;
});
