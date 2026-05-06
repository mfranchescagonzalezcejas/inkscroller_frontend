import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_cache_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/usecases/clear_settings_cache.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCacheRepository extends Mock
    implements SettingsCacheRepository {}

void main() {
  late SettingsCacheRepository repository;
  late ClearSettingsCache useCase;

  setUp(() {
    repository = _MockSettingsCacheRepository();
    useCase = ClearSettingsCache(repository);
  });

  test('delegates cache clearing to repository', () async {
    when(() => repository.clearLibraryCache()).thenAnswer(
      (_) async => const Right(null),
    );

    final Either<Failure, void> result = await useCase();

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.clearLibraryCache()).called(1);
  });

  test('returns repository failure without modification', () async {
    const CacheFailure failure = CacheFailure(message: 'boom');
    when(() => repository.clearLibraryCache()).thenAnswer(
      (_) async => const Left(failure),
    );

    final Either<Failure, void> result = await useCase();

    expect(result, const Left<Failure, void>(failure));
  });
}
