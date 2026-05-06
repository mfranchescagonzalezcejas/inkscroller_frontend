import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../library/domain/entities/reader_mode.dart';
import '../../domain/entities/user_reading_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_local_ds.dart';
import '../datasources/preferences_remote_ds.dart';

/// Local-first repository for authenticated reading preferences.
///
/// Read strategy: try remote first for fresh data, fall back to local cache
/// if remote fails. Update local cache when remote succeeds.
///
/// Write strategy: optimistic local write first, then attempt remote sync.
/// If remote fails, the change is still persisted locally and will sync later.
class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDataSource remoteDataSource;
  final PreferencesLocalDataSource localDataSource;

  const PreferencesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserReadingPreferences>> getPreferences() async {
    // Try remote first for fresh data.
    final remoteResult = await _getFromRemote();

    if (remoteResult.isRight()) {
      final remotePrefs = remoteResult.fold((l) => null, (r) => r)!;

      // Check if local has a newer unsynced change.
      final cached = await localDataSource.getCachedPreferences();
      if (cached != null && cached.updatedAt.isAfter(remotePrefs.updatedAt)) {
        // Local is newer — keep it and push to remote in background.
        await _pushToRemote(cached);
        return Right(cached);
      }

      // Remote is fresher — update local cache.
      await localDataSource.savePreferences(remotePrefs);
      return Right(remotePrefs);
    }

    // Remote failed — fall back to local cache.
    final cached = await localDataSource.getCachedPreferences();
    if (cached != null) return Right(cached);

    return remoteResult.fold(
      (failure) => Left<Failure, UserReadingPreferences>(failure),
      (_) => throw StateError('unreachable'),
    );
  }

  @override
  Future<Either<Failure, UserReadingPreferences>> updatePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
  }) async {
    // Read current cached preferences to preserve fields we're not updating.
    final cached = await localDataSource.getCachedPreferences();

    // Determine effective values: new value > cached value > default.
    final effectiveReaderMode = ReaderMode.values.byName(
      defaultReaderMode ??
          cached?.defaultReaderMode.name ??
          ReaderMode.vertical.name,
    );
    final effectiveLanguage =
        defaultLanguage ?? cached?.defaultLanguage ?? 'en';

    // Build the optimistic preferences with current timestamp.
    final optimistic = UserReadingPreferences(
      defaultReaderMode: effectiveReaderMode,
      defaultLanguage: effectiveLanguage,
      updatedAt: DateTime.now(),
    );

    // Optimistic write: persist to local immediately.
    await localDataSource.savePreferences(optimistic);

    // Attempt remote sync in background. If it succeeds, update local with
    // the server's response (authoritative timestamp). If it fails, local
    // already has the user's change.
    try {
      final model = await remoteDataSource.updatePreferences(
        defaultReaderMode: defaultReaderMode,
        defaultLanguage: defaultLanguage,
      );
      final preferences = model.toEntity();
      await localDataSource.savePreferences(preferences);
      return Right(preferences);
    } on AppException {
      // Remote failed but local already has the change — return optimistic.
      return Right(optimistic);
    } on Exception {
      // Remote failed but local already has the change — return optimistic.
      return Right(optimistic);
    }
  }

  Future<Either<Failure, UserReadingPreferences>> _getFromRemote() async {
    try {
      final model = await remoteDataSource.getPreferences();
      return Right(model.toEntity());
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  /// Pushes local preferences to the remote server (background sync).
  /// Used when local data is newer than remote (offline change).
  Future<void> _pushToRemote(UserReadingPreferences prefs) async {
    try {
      await remoteDataSource.updatePreferences(
        defaultReaderMode: prefs.defaultReaderMode.name,
        defaultLanguage: prefs.defaultLanguage,
      );
    } on Object {
      // Best-effort push — if it fails, next sync will retry.
    }
  }

  Failure _mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      ServerException() => ServerFailure(
        message: exception.message,
        code: exception.code,
      ),
      NetworkException() => NetworkFailure(
        message: exception.message,
        code: exception.code,
      ),
      CacheException() => CacheFailure(
        message: exception.message,
        code: exception.code,
      ),
      UnexpectedException() => UnexpectedFailure(
        message: exception.message,
        code: exception.code,
      ),
    };
  }
}
