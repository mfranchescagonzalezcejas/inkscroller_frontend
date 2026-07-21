import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_local_ds_impl.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LibraryLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    dataSource = LibraryLocalDataSourceImpl(prefs);
  });

  const manga = MangaModel(id: '1', title: 'One');

  test('reordered demographics use the same persisted key', () async {
    await dataSource.cacheMangaList(
      limit: 20,
      offset: 0,
      demographics: ['shoujo', 'shounen'],
      mangas: [manga],
    );

    final cached = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      demographics: ['shounen', 'shoujo'],
      maxAge: const Duration(minutes: 10),
    );

    expect(cached, isNotNull);
    expect(cached!.single.id, '1');
  });

  test('different demographic selections use different persisted keys', () async {
    await dataSource.cacheMangaList(
      limit: 20,
      offset: 0,
      demographics: ['shounen'],
      mangas: [manga],
    );

    final cached = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      demographics: ['shoujo'],
      maxAge: const Duration(minutes: 10),
    );

    expect(cached, isNull);
  });

  test('different genre uses a different persisted key', () async {
    await dataSource.cacheMangaList(
      limit: 20,
      offset: 0,
      genre: 'action',
      mangas: [manga],
    );

    final cached = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      genre: 'romance',
      maxAge: const Duration(minutes: 10),
    );

    expect(cached, isNull);
  });

  test('different content rating uses a different persisted key', () async {
    await dataSource.cacheMangaList(
      limit: 20,
      offset: 0,
      contentRating: 'safe',
      mangas: [manga],
    );

    final cached = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      contentRating: 'suggestive',
      maxAge: const Duration(minutes: 10),
    );

    expect(cached, isNull);
  });

  test('combined filters produce distinct keys', () async {
    await dataSource.cacheMangaList(
      limit: 20,
      offset: 0,
      genre: 'action',
      contentRating: 'safe',
      demographics: ['shounen'],
      mangas: [manga],
    );

    final same = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      genre: 'action',
      contentRating: 'safe',
      demographics: ['shounen'],
      maxAge: const Duration(minutes: 10),
    );
    final differentGenre = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      genre: 'romance',
      contentRating: 'safe',
      demographics: ['shounen'],
      maxAge: const Duration(minutes: 10),
    );
    final differentRating = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      genre: 'action',
      contentRating: 'suggestive',
      demographics: ['shounen'],
      maxAge: const Duration(minutes: 10),
    );
    final reorderedDemographics = await dataSource.getCachedMangaList(
      limit: 20,
      offset: 0,
      genre: 'action',
      contentRating: 'safe',
      demographics: ['shounen'],
      maxAge: const Duration(minutes: 10),
    );

    expect(same, isNotNull);
    expect(same!.single.id, '1');
    expect(differentGenre, isNull);
    expect(differentRating, isNull);
    expect(reorderedDemographics, isNotNull);
  });
}
