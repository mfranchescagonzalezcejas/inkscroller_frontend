import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/repositories/reading_progress_repository_impl.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ReadingProgressRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    repository = ReadingProgressRepositoryImpl(prefs);
  });

  test('save persists progress as serialized JSON', () async {
    const MangaReadingProgress progress = MangaReadingProgress(
      mangaId: 'm-1',
      readChapterIds: <String>{'c-2', 'c-1'},
      totalChaptersCount: 50,
    );

    await repository.save(progress);

    final String? raw = prefs.getString('library.reading_progress.m-1');
    expect(raw, isNotNull);

    final Map<String, dynamic> json =
        jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['mangaId'], 'm-1');
    expect(json['readChapterIds'], <String>['c-1', 'c-2']);
    expect(json['totalChaptersCount'], 50);
  });

  test('getAll removes corrupted values from storage', () async {
    await prefs.setString('library.reading_progress.bad', '{broken json');

    final Map<String, MangaReadingProgress> loaded = await repository.getAll();

    expect(loaded, isEmpty);
    expect(prefs.getString('library.reading_progress.bad'), isNull);
  });
}
