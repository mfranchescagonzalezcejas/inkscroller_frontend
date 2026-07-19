import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/domain/entities/manga.dart';
import 'home_provider.dart';
import 'home_state.dart';

/// Discover filter options independent from [libraryProvider].
///
/// Home manages its own filter state so genre changes never leak into
/// the Library tab.
enum HomeDiscoverFilter { all, popular, romance, action }

/// Local filter selection for the Discover section.
final homeDiscoverFilterProvider =
    StateProvider<HomeDiscoverFilter>((_) => HomeDiscoverFilter.all);

/// Mangas to show in the Discover section based on the current filter.
///
/// Feeds entirely from [homeProvider] data so it never touches
/// [libraryProvider]'s internal pagination or mode.
final homeDiscoverMangasProvider = Provider<List<Manga>>((ref) {
  final filter = ref.watch(homeDiscoverFilterProvider);
  final homeState = ref.watch(homeProvider);

  switch (filter) {
    case HomeDiscoverFilter.popular:
      return homeState.popular;
    case HomeDiscoverFilter.romance:
      return _byGenre(homeState, 'romance');
    case HomeDiscoverFilter.action:
      return _byGenre(homeState, 'action');
    case HomeDiscoverFilter.all:
      // Merge all sections, deduplicate by id, up to a reasonable count.
      final seen = <String>{};
      final result = <Manga>[];
      for (final list in [
        ...homeState.popular,
        ...homeState.shounen,
        ...homeState.shoujo,
        if (homeState.seinen.isNotEmpty) ...homeState.seinen,
        if (homeState.josei.isNotEmpty) ...homeState.josei,
      ]) {
        if (seen.add(list.id)) result.add(list);
        if (result.length >= 20) break;
      }
      return result;
  }
});

/// Simple genre match against the manga's genre tags or demographic.
///
/// ponytail: naive substring match — backend tag IDs would be more precise,
/// but this keeps the implementation provider-local with no new API contract.
List<Manga> _byGenre(HomeState state, String genre) {
  final all = <Manga>[
    ...state.popular,
    ...state.shounen,
    ...state.shoujo,
    ...state.seinen,
    ...state.josei,
  ];
  final seen = <String>{};
  final result = <Manga>[];
  for (final manga in all) {
    if (!seen.add(manga.id)) continue;
    final lowerGenre = genre.toLowerCase();
    final matchesGenre = manga.genres.any(
      (g) => g.toLowerCase().contains(lowerGenre),
    );
    final matchesDemographic = manga.demographic?.toLowerCase() == lowerGenre;
    if (matchesGenre || matchesDemographic) {
      result.add(manga);
    }
    if (result.length >= 20) break;
  }
  return result;
}
