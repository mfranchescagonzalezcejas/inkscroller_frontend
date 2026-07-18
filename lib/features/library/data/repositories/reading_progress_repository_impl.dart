import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/reading_progress_remote_ds.dart';
import '../mappers/manga_reading_progress_mapper.dart';
import '../models/manga_reading_progress_model.dart';
import '../../domain/entities/manga_reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  ReadingProgressRepositoryImpl(
    SharedPreferences prefs, {
    ReadingProgressRemoteDataSource? remoteDataSource,
    FirebaseAuth? firebaseAuth,
  }) : _prefs = prefs,
       _remoteDataSource = remoteDataSource,
       _firebaseAuth = firebaseAuth;

  final SharedPreferences _prefs;
  final ReadingProgressRemoteDataSource? _remoteDataSource;
  final FirebaseAuth? _firebaseAuth;

  static const String _prefix = 'library.reading_progress.';

  bool get _canSyncRemote =>
      _remoteDataSource != null &&
      _firebaseAuth != null &&
      _firebaseAuth.currentUser != null;

  @override
  Future<Map<String, MangaReadingProgress>> getAll() async {
    final Map<String, MangaReadingProgress> progressByManga =
        <String, MangaReadingProgress>{};

    for (final key in _prefs.getKeys().where(
      (entry) => entry.startsWith(_prefix),
    )) {
      final String? raw = _prefs.getString(key);
      if (raw == null) {
        continue;
      }

      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        final MangaReadingProgress progress =
            MangaReadingProgressModel.fromJson(json).toEntity();
        debugPrint('[ProgressRepo] loaded $key: '
            'readChapterIds=${progress.readChapterIds.length} '
            'manual=${progress.manuallyMarkedCount} '
            'total=${progress.totalChaptersCount}');
        progressByManga[progress.mangaId] = progress;
      } on Object {
        await _prefs.remove(key);
      }
    }

    return progressByManga;
  }

  @override
  Future<void> save(MangaReadingProgress progress) async {
    // Always persist locally first.
    final MangaReadingProgressModel model = progress.toModel();
    debugPrint('[ProgressRepo] save: '
        '${progress.mangaId} '
        'readChapterIds=${progress.readChapterIds.length} '
        'manual=${progress.manuallyMarkedCount} '
        'total=${progress.totalChaptersCount}');
    await _prefs.setString(
      '$_prefix${progress.mangaId}',
      jsonEncode(model.toJson()),
    );

    // Fire-and-forget remote sync: local save never blocks on the network.
    // Consecutive rapid updates for the same manga each push their own
    // snapshot; the backend receives the last-written value which is the
    // most recent state.
    if (_canSyncRemote) {
      unawaited(
        _remoteDataSource!.updateProgress(
          progress.mangaId,
          progress.readChaptersCount,
        ),
      );
    }
  }
}
