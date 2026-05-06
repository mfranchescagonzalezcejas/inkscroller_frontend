import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';

/// Use case that fetches the ordered page image URLs for a chapter.
///
/// Throws if the chapter is external-only and cannot be read in-app.
class GetChapterPages {
  final LibraryRepository repository;

  GetChapterPages(this.repository);

  /// Returns a list of image URLs representing each page of [chapterId], in reading order.
  Future<Either<Failure, List<String>>> call(String chapterId) {
    return repository.getChapterPages(chapterId);
  }
}
