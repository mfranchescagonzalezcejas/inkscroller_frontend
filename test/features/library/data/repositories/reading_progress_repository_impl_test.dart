import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/repositories/reading_progress_repository_impl.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

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

    final String? raw = prefs.getString('library.reading_progress.guest.m-1');
    expect(raw, isNotNull);

    final Map<String, dynamic> json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['mangaId'], 'm-1');
    expect(json['readChapterIds'], <String>['c-1', 'c-2']);
    expect(json['totalChaptersCount'], 50);
  });

  test('getAll removes corrupted values from storage', () async {
    await prefs.setString('library.reading_progress.guest.bad', '{broken json');

    final Map<String, MangaReadingProgress> loaded = await repository.getAll();

    expect(loaded, isEmpty);
    expect(prefs.getString('library.reading_progress.guest.bad'), isNull);
  });

  test('migrates legacy progress to guest scope when signed out', () async {
    const MangaReadingProgress progress = MangaReadingProgress(mangaId: 'm-1');
    final String raw = jsonEncode(<String, Object>{
      'mangaId': progress.mangaId,
      'readChapterIds': <String>[],
      'totalChaptersCount': progress.totalChaptersCount,
      'manuallyMarkedCount': progress.manuallyMarkedCount,
      'batchSize': progress.batchSize,
    });
    await prefs.setString('library.reading_progress.m-1', raw);

    final Map<String, MangaReadingProgress> loaded = await repository.getAll();

    expect(loaded.keys, <String>['m-1']);
    expect(prefs.getString('library.reading_progress.m-1'), isNull);
    expect(prefs.getString('library.reading_progress.guest.m-1'), equals(raw));
  });

  test('does not migrate legacy progress for an authenticated user', () async {
    await prefs.setString(
      'library.reading_progress.m-1',
      jsonEncode(<String, Object>{'mangaId': 'm-1'}),
    );
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(_FakeUser('user-a'));
    repository = ReadingProgressRepositoryImpl(prefs, firebaseAuth: auth);

    final Map<String, MangaReadingProgress> loaded = await repository.getAll();

    expect(loaded, isEmpty);
    expect(prefs.getString('library.reading_progress.m-1'), isNotNull);
    expect(prefs.getString('library.reading_progress.guest.m-1'), isNull);
  });

  test('authenticated users load only their own scoped progress', () async {
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(_FakeUser('user-a'));
    final userARepository = ReadingProgressRepositoryImpl(
      prefs,
      firebaseAuth: auth,
    );
    await userARepository.save(const MangaReadingProgress(mangaId: 'a-manga'));

    when(() => auth.currentUser).thenReturn(_FakeUser('user-b'));
    await ReadingProgressRepositoryImpl(
      prefs,
      firebaseAuth: auth,
    ).save(const MangaReadingProgress(mangaId: 'b-manga'));

    when(() => auth.currentUser).thenReturn(null);
    await ReadingProgressRepositoryImpl(
      prefs,
      firebaseAuth: auth,
    ).save(const MangaReadingProgress(mangaId: 'guest-manga'));

    when(() => auth.currentUser).thenReturn(_FakeUser('user-a'));
    final Map<String, MangaReadingProgress> loaded = await userARepository
        .getAll();

    expect(loaded.keys, <String>['a-manga']);
  });
}
