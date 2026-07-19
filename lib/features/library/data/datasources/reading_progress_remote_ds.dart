/// Remote data source for reading progress sync with the backend.
// ignore: one_member_abstracts
abstract class ReadingProgressRemoteDataSource {
  /// Pushes [chaptersRead] for [mangaId] to the backend.
  ///
  /// Only valid when the manga is in the user's library. Returns `true` on
  /// success, `false` if the manga is not in the library (404).
  Future<bool> updateProgress(String mangaId, int chaptersRead);
}
