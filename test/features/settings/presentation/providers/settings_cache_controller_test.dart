import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/usecases/clear_settings_cache.dart';
import 'package:inkscroller_flutter/features/settings/domain/usecases/get_settings_cache_size.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_cache_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockClearSettingsCache extends Mock implements ClearSettingsCache {}

class _MockGetSettingsCacheSize extends Mock implements GetSettingsCacheSize {}

void main() {
  late ClearSettingsCache clearSettingsCache;
  late GetSettingsCacheSize getSettingsCacheSize;
  late SettingsCacheController controller;

  setUp(() {
    clearSettingsCache = _MockClearSettingsCache();
    getSettingsCacheSize = _MockGetSettingsCacheSize();
    controller = SettingsCacheController(
      clearSettingsCache: clearSettingsCache,
      getSettingsCacheSize: getSettingsCacheSize,
    );
  });

  test('clearLibraryCache delegates to clear use case', () async {
    when(() => clearSettingsCache()).thenAnswer((_) async => const Right(null));

    final Either<Failure, void> result = await controller.clearLibraryCache();

    expect(result, const Right<Failure, void>(null));
    verify(() => clearSettingsCache()).called(1);
  });

  test('getCacheSize delegates to size use case', () {
    when(() => getSettingsCacheSize()).thenReturn(1100);

    final int bytes = controller.getCacheSize();

    expect(bytes, 1100);
    verify(() => getSettingsCacheSize()).called(1);
  });

  test('cacheSizeProvider returns byte format under 1 KB', () {
    when(() => getSettingsCacheSize()).thenReturn(128);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsCacheControllerProvider.overrideWithValue(controller),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(cacheSizeProvider), '128 B');
  });

  test('cacheSizeProvider returns KB format between 1 KB and 1 MB', () {
    when(() => getSettingsCacheSize()).thenReturn(1536);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsCacheControllerProvider.overrideWithValue(controller),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(cacheSizeProvider), '1.5 KB');
  });
}
