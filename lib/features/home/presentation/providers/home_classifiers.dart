import '../../../library/domain/entities/manga_tags.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../library/domain/entities/manga.dart';
import 'home_state.dart';

/// Pure-logic helper that classifies a flat manga list into [HomeState] sections.
///
/// All methods are stateless and free of side-effects. The cap of items per
/// section is enforced by the shared [takeSafe] helper.
class HomeClassifier {
  /// Public compatibility alias for the shared home carousel item limit.
  static const int showMany = AppConstants.homeCarouselItemLimit;

  /// Returns [list] unchanged when it fits within the shared home carousel
  /// limit; otherwise returns only the first items that fit.
  static List<Manga> takeSafe(List<Manga> list) {
    if (list.length <= AppConstants.homeCarouselItemLimit) return list;
    return list.take(AppConstants.homeCarouselItemLimit).toList();
  }

  /// Returns up to the configured limit from [all] without additional filtering.
  static List<Manga> featured(List<Manga> all) => takeSafe(all);

  /// Returns up to the configured limit from [all] in reverse order.
  static List<Manga> latest(List<Manga> all) => takeSafe(all.reversed.toList());

  /// Returns up to the configured limit of items that have both a cover and a description.
  static List<Manga> popular(List<Manga> all) => takeSafe(
        all
            .where((m) => m.coverUrl != null && m.description != null)
            .toList(),
      );

  /// Returns up to the configured limit whose [Manga.demographic] matches [demo].
  static List<Manga> byDemographic(List<Manga> all, String demo) =>
      takeSafe(all.where((m) => m.demographic == demo).toList());

  /// Classifies [all] into a complete [HomeState] ready for the home screen.
  static HomeState classify(List<Manga> all) => HomeState(
        featured: featured(all),
        latest: latest(all),
        popular: popular(all),
        shounen: byDemographic(all, MangaDemographic.shounen),
        shoujo: byDemographic(all, MangaDemographic.shoujo),
        seinen: byDemographic(all, MangaDemographic.seinen),
        josei: byDemographic(all, MangaDemographic.josei),
      );
}
