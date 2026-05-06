import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_cache_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/usecases/get_settings_cache_size.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCacheRepository extends Mock
    implements SettingsCacheRepository {}

void main() {
  late SettingsCacheRepository repository;
  late GetSettingsCacheSize useCase;

  setUp(() {
    repository = _MockSettingsCacheRepository();
    useCase = GetSettingsCacheSize(repository);
  });

  test('returns bytes from repository', () {
    when(() => repository.getLibraryCacheSize()).thenReturn(1536);

    final int result = useCase();

    expect(result, 1536);
    verify(() => repository.getLibraryCacheSize()).called(1);
  });

  test('returns zero when repository returns zero', () {
    when(() => repository.getLibraryCacheSize()).thenReturn(0);

    final int result = useCase();

    expect(result, 0);
  });
}
