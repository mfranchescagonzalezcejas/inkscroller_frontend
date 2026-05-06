import '../entities/manga_reading_progress.dart';

abstract class ReadingProgressRepository {
  Future<Map<String, MangaReadingProgress>> getAll();

  Future<void> save(MangaReadingProgress progress);
}
