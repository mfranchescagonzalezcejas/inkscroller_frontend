import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/home_chapter.dart';

/// Contract for retrieving home feed chapter data.
// ignore: one_member_abstracts
abstract class HomeRepository {
  /// Returns the latest available chapters for the home feed.
  Future<Either<Failure, List<HomeChapter>>> getLatestChapters({
    int limit = 10,
  });
}
