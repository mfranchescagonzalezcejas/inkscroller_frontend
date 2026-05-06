import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/data/repositories/settings_cache_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late SettingsCacheRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'library.list': 'abc',
      'library.detail': '12345',
      'profile.theme': 'dark',
    });
    preferences = await SharedPreferences.getInstance();
    repository = SettingsCacheRepositoryImpl(sharedPreferences: preferences);
  });

  test('clearLibraryCache removes only library.* entries', () async {
    final Either<Failure, void> result = await repository.clearLibraryCache();

    expect(result.isRight(), isTrue);
    expect(preferences.getString('library.list'), isNull);
    expect(preferences.getString('library.detail'), isNull);
    expect(preferences.getString('profile.theme'), 'dark');
  });

  test('getLibraryCacheSize returns combined byte length for library keys', () {
    final int bytes = repository.getLibraryCacheSize();

    expect(bytes, 8);
  });
}
