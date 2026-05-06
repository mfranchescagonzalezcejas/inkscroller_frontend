import '../../domain/entities/manga.dart';
import '../models/manga_model.dart';

/// Extension that adds a [toEntity] conversion method to [MangaModel].
///
/// Keeps mapping logic co-located with the model while avoiding coupling between
/// the data and domain layers inside the model class itself.
extension MangaModelMapper on MangaModel {
  /// Converts this DTO into the corresponding [Manga] domain entity.
  Manga toEntity() {
    return Manga(
      id: id,
      title: title,
      description: description,
      coverUrl: coverUrl,
      demographic: demographic,
      status: status,
      genres: genres,
      score: score,
      rank: rank,
      // Note: popularity is stored in score for display, but we could add a
      // separate field in Manga entity if needed for sorting/filtering
      authors: authors,
      readChaptersCount: readChaptersCount,
      totalChaptersCount: totalChaptersCount,
    );
  }
}
