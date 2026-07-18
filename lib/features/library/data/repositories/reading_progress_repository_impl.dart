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
    await _prefs.setString(
      '$_prefix${progress.mangaId}',
      jsonEncode(model.toJson()),
    );

    // Then push to backend when authenticated.
    if (_canSyncRemote) {
      await _remoteDataSource!.updateProgress(
        progress.mangaId,
        progress.readChaptersCount,
      );
    }
  }
}
