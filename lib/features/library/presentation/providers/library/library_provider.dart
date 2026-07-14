import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/usecases/get_manga_list.dart';
import '../../../domain/usecases/search_manga.dart';
import '../../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../../preferences/presentation/providers/demographic_resolution_provider.dart';
import '../../../../preferences/domain/entities/demographic_resolution.dart';
import 'library_notifier.dart';
import 'library_state.dart';

/// Riverpod provider that wires [LibraryNotifier] with its use-case dependencies.
///
/// Resolves [GetMangaList] and [SearchManga] from get_it and exposes
/// the reactive [LibraryState] to the widget tree.
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>(
      (ref) {
    final contentResolution = ref.read(contentRatingResolutionProvider);
    final demographicResolution = ref.read(demographicResolutionProvider);
    final notifier = LibraryNotifier(
      sl<GetMangaList>(),
      sl<SearchManga>(),
      initialContentRating: contentResolution.effectiveRating.wireValue,
      initialDemographics: demographicResolution.effectiveFilter
          .map((d) => d.toJson())
          .toList(),
    );

    // Listen for content rating changes and trigger a refresh.
    ref.listen<ContentRatingResolution>(
      contentRatingResolutionProvider,
      (previous, next) {
        if (previous?.effectiveRating != next.effectiveRating) {
          notifier.refresh(contentRating: next.effectiveRating.wireValue);
        }
      },
    );

    // Listen for demographic filter changes and trigger a refresh.
    ref.listen<DemographicResolution>(
      demographicResolutionProvider,
      (previous, next) {
        final prevDemos = previous?.effectiveFilter ?? [];
        final nextDemos = next.effectiveFilter;
        if (prevDemos != nextDemos) {
          notifier.refresh(
            demographics: nextDemos.map((d) => d.toJson()).toList(),
          );
        }
      },
    );

    return notifier;
  },
);

/// Explore tab's own provider — identical to [libraryProvider] but isolated
/// so ExplorePage state never leaks into Home/Library.
final exploreProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>(
      (ref) {
    final contentResolution = ref.read(contentRatingResolutionProvider);
    final demographicResolution = ref.read(demographicResolutionProvider);
    final notifier = LibraryNotifier(
      sl<GetMangaList>(),
      sl<SearchManga>(),
      initialContentRating: contentResolution.effectiveRating.wireValue,
      initialDemographics: demographicResolution.effectiveFilter
          .map((d) => d.toJson())
          .toList(),
    );

    ref.listen<ContentRatingResolution>(
      contentRatingResolutionProvider,
      (previous, next) {
        if (previous?.effectiveRating != next.effectiveRating) {
          notifier.refresh(contentRating: next.effectiveRating.wireValue);
        }
      },
    );

    ref.listen<DemographicResolution>(
      demographicResolutionProvider,
      (previous, next) {
        final prevDemos = previous?.effectiveFilter ?? [];
        final nextDemos = next.effectiveFilter;
        if (prevDemos != nextDemos) {
          notifier.refresh(
            demographics: nextDemos.map((d) => d.toJson()).toList(),
          );
        }
      },
    );

    return notifier;
  },
);
