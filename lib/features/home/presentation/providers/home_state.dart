import '../../../library/domain/entities/manga.dart';

/// Immutable snapshot of the home page curated sections.
///
/// Groups manga lists by category (featured, latest, popular) and demographic
/// (shounen, shoujo, seinen, josei) for the [HomePage] horizontal carousels.
class HomeState {
  final List<Manga> featured;
  final List<Manga> latest;
  final List<Manga> popular;

  final List<Manga> shounen;
  final List<Manga> shoujo;
  final List<Manga> seinen;
  final List<Manga> josei;

  const HomeState({
    required this.featured,
    required this.latest,
    required this.popular,
    required this.shounen,
    required this.shoujo,
    required this.seinen,
    required this.josei,
  });
}
