import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../../library/domain/entities/manga.dart';
import '../../../library/domain/usecases/get_manga_list.dart';
import '../../../library/domain/usecases/search_manga.dart';
import '../../../library/presentation/providers/library/library_notifier.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../../../library/presentation/providers/library/library_state.dart';
import '../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../preferences/presentation/providers/demographic_resolution_provider.dart';
import 'home_provider.dart';
import 'home_state.dart';

/// Discover filter options independent from [libraryProvider].
enum HomeDiscoverFilter { all, popular, romance, action }

/// Local filter selection for the Discover section.
final homeDiscoverFilterProvider =
    StateProvider<HomeDiscoverFilter>((_) => HomeDiscoverFilter.all);

/// Isolated notifier for the Home Discover section — identical to
/// [exploreProvider] but named so Home never contaminates Library/Explore.
final homeDiscoverProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final sl = GetIt.instance;
  final contentResolution = ref.watch(contentRatingResolutionProvider);
  final demographicResolution = ref.watch(demographicResolutionProvider);
  final notifier = LibraryNotifier(
    sl<GetMangaList>(),
    sl<SearchManga>(),
    initialContentRating: contentResolution.effectiveRating.wireValue,
    initialDemographics: demographicResolution.effectiveFilter
        .map((d) => d.toJson())
        .toList(),
  );
  // Load initial catalogue so Popular/Romance/Action have data.
  notifier.loadInitial();
  return notifier;
});

/// Mangas to show in the Discover section based on the current filter.
final homeDiscoverMangasProvider = Provider<List<Manga>>((ref) {
  final filter = ref.watch(homeDiscoverFilterProvider);
  final libraryState = ref.watch(homeDiscoverProvider);

  switch (filter) {
    case HomeDiscoverFilter.popular:
      // Display server-sorted popular results.
      // If still loading / empty, fall back to the home provider's popular.
      if (libraryState.mangas.isNotEmpty) return libraryState.mangas.take(20).toList();
      final homeState = ref.watch(homeProvider);
      return homeState.popular.take(20).toList();

    case HomeDiscoverFilter.romance:
      return _byGenre(libraryState.mangas, 'romance');

    case HomeDiscoverFilter.action:
      return _byGenre(libraryState.mangas, 'action');

    case HomeDiscoverFilter.all:
      if (libraryState.mangas.isNotEmpty) return libraryState.mangas.take(20).toList();
      final homeState = ref.watch(homeProvider);
      return _mergeAll(homeState);
  }
});

/// Triggers [homeDiscoverProvider] to load with the given filter.
///
/// Call from chip onTap — mirrors what Explore does.
void triggerDiscoverFilter(WidgetRef ref, HomeDiscoverFilter filter) {
  ref.read(homeDiscoverFilterProvider.notifier).state = filter;
  final notifier = ref.read(homeDiscoverProvider.notifier);

  switch (filter) {
    case HomeDiscoverFilter.popular:
      notifier.loadInitial(mode: LibraryMode.popular);
    case HomeDiscoverFilter.romance:
      notifier.setGenre('romance');
    case HomeDiscoverFilter.action:
      notifier.setGenre('action');
    case HomeDiscoverFilter.all:
      notifier.loadInitial();
  }
}

/// Merge all home sections, deduplicate by id, cap at 20.
List<Manga> _mergeAll(HomeState state) {
  final seen = <String>{};
  final result = <Manga>[];
  for (final list in [
    ...state.popular,
    ...state.shounen,
    ...state.shoujo,
    if (state.seinen.isNotEmpty) ...state.seinen,
    if (state.josei.isNotEmpty) ...state.josei,
  ]) {
    if (seen.add(list.id)) result.add(list);
    if (result.length >= 20) break;
  }
  return result;
}

/// Naive genre match against the library manga list.
List<Manga> _byGenre(List<Manga> mangas, String genre) {
  final lowerGenre = genre.toLowerCase();
  final result = <Manga>[];
  final seen = <String>{};
  for (final manga in mangas) {
    if (!seen.add(manga.id)) continue;
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
