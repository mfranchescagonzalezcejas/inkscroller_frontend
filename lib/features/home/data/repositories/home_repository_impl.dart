import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/home_chapter.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_ds.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;

  const HomeRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, List<HomeChapter>>> getLatestChapters({
    int limit = 10,
  }) async {
    try {
      final models = await remote.getLatestChapters(limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (error) {
      return Left(
        ServerFailure(message: error.message, code: error.code),
      );
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }
}
