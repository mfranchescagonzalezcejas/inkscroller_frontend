import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chapters_with_languages.dart';
import '../repositories/library_repository.dart';

/// Use case that fetches available languages and the best-matching chapter
/// list for a manga in a single call.
///
/// This replaces the initial `getMangaLanguages` + `getMangaChapters` round
/// trip when opening a manga detail page.
class GetMangaChaptersWithLanguages {
  final LibraryRepository repository;

  GetMangaChaptersWithLanguages(this.repository);

  /// Returns available languages, matched language, and chapters for [mangaId].
  ///
  /// [preferredLang] is the user's default language preference (e.g. "es").
  /// The backend selects the best match when the preference is not available.
  Future<Either<Failure, ChaptersWithLanguages>> call(
    String mangaId, {
    String? preferredLang,
  }) {
    return repository.getMangaChaptersWithLanguages(
      mangaId,
      preferredLang: preferredLang,
    );
  }
}
