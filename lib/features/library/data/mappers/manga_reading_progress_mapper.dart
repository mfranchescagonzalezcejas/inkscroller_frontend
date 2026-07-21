import '../../domain/entities/manga_reading_progress.dart';
import '../models/manga_reading_progress_model.dart';

/// Converts persisted reading-progress models into domain entities.
extension MangaReadingProgressModelMapper on MangaReadingProgressModel {
  /// Maps this model to the corresponding [MangaReadingProgress] entity.
  MangaReadingProgress toEntity() {
    return MangaReadingProgress(
      mangaId: mangaId,
      readChapterIds: readChapterIds,
      totalChaptersCount: totalChaptersCount,
      manuallyMarkedCount: manuallyMarkedCount,
      batchSize: batchSize,
      updatedAt: updatedAt,
    );
  }
}

/// Converts domain reading-progress entities into persistence models.
extension MangaReadingProgressEntityMapper on MangaReadingProgress {
  /// Maps this entity to a [MangaReadingProgressModel] for storage.
  MangaReadingProgressModel toModel() {
    return MangaReadingProgressModel(
      mangaId: mangaId,
      readChapterIds: readChapterIds,
      totalChaptersCount: totalChaptersCount,
      manuallyMarkedCount: manuallyMarkedCount,
      batchSize: batchSize,
      updatedAt: updatedAt,
    );
  }
}
