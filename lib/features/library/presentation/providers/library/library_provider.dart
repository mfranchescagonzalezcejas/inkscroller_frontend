import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/usecases/get_manga_list.dart';
import '../../../domain/usecases/search_manga.dart';
import '../../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import 'library_notifier.dart';
import 'library_state.dart';

/// Riverpod provider that wires [LibraryNotifier] with its use-case dependencies.
///
/// Resolves [GetMangaList] and [SearchManga] from get_it and exposes
/// the reactive [LibraryState] to the widget tree.
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>(
      (ref) {
    // Use ref.read (not ref.watch) to avoid recreating LibraryNotifier
    // when the resolution updates — ref.listen below handles reactivity.
    final resolution = ref.read(contentRatingResolutionProvider);
    final notifier = LibraryNotifier(
      sl<GetMangaList>(),
      sl<SearchManga>(),
      initialContentRating: resolution.effectiveRating.wireValue,
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

    return notifier;
  },
);

/// Explore tab's own provider — identical to [libraryProvider] but isolated
/// so ExplorePage state never leaks into Home/Library.
final exploreProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>(
      (ref) {
    final resolution = ref.read(contentRatingResolutionProvider);
    final notifier = LibraryNotifier(
      sl<GetMangaList>(),
      sl<SearchManga>(),
      initialContentRating: resolution.effectiveRating.wireValue,
    );

    ref.listen<ContentRatingResolution>(
      contentRatingResolutionProvider,
      (previous, next) {
        if (previous?.effectiveRating != next.effectiveRating) {
          notifier.refresh(contentRating: next.effectiveRating.wireValue);
        }
      },
    );

    return notifier;
  },
);
