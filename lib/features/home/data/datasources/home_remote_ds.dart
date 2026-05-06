import '../models/home_chapter_model.dart';

/// Remote datasource contract for Home-specific data.
class HomeRemoteDataSource {
  /// Returns latest uploaded chapters for Home section.
  Future<List<HomeChapterModel>> getLatestChapters({int limit = 10}) {
    throw UnimplementedError();
  }
}
