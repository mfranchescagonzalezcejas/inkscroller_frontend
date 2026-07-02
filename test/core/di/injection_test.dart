import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkscroller_flutter/core/di/injection.dart';
import 'package:inkscroller_flutter/core/network/dio_client.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_cache_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';

void main() {
  late GetIt sl;

  setUp(() async {
    sl = GetIt.instance;
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('initDI idempotency', () {
    test('calling initDI twice does not throw duplicate registration errors',
        () async {
      SharedPreferences.setMockInitialValues({});

      await initDI();
      // Second call must succeed — every registration is individually guarded.
      await initDI();
    });

    test(
        'if SharedPreferences is pre-registered, initDI still registers '
        'later dependencies like DioClient and SettingsRepository', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      sl.registerLazySingleton<SharedPreferences>(() => prefs);

      await initDI();

      expect(sl.isRegistered<DioClient>(), isTrue);
      expect(sl.isRegistered<SettingsRepository>(), isTrue);
      expect(sl.isRegistered<SettingsCacheRepository>(), isTrue);
      expect(sl.isRegistered<GetMangaList>(), isTrue);
    });
  });
}
