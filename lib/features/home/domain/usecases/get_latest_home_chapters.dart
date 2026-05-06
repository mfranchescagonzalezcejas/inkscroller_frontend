import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/home_chapter.dart';
import '../repositories/home_repository.dart';

class GetLatestHomeChapters {
  final HomeRepository repository;

  const GetLatestHomeChapters(this.repository);

  Future<Either<Failure, List<HomeChapter>>> call({int limit = 10}) {
    return repository.getLatestChapters(limit: limit);
  }
}
