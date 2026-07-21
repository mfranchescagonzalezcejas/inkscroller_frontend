import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/manga.dart';
import '../../domain/entities/user_library_entry.dart';
import '../../domain/repositories/user_library_repository.dart';
import '../datasources/user_library_remote_ds.dart';
import '../models/user_library_entry_model.dart';

/// SharedPreferences implementation for user library local persistence.
class UserLibraryRepositoryImpl implements UserLibraryRepository {
  UserLibraryRepositoryImpl(this._prefs, this._remoteDataSource);

  final SharedPreferences _prefs;
  final UserLibraryRemoteDataSource _remoteDataSource;

  static const String _legacyPrefix = 'library.user_library.';
  static const String _prefix = 'library.user_library.v2.';
  static const String _lastSyncPrefix = 'library.last_synced_at.';

  bool _legacyMigrated = false;

  /// Tracks manga IDs that have already been pushed for enrichment this
  /// session so permanently nullable metadata (e.g. unrated manga) does not
  /// trigger a re-push on every hydration cycle.
  final Set<String> _enrichmentAttempted = {};

  @override
  Future<Map<String, UserLibraryEntry>> getAll({String? userId}) async {
    await _migrateLegacyGuestDataIfNeeded();

    final Map<String, UserLibraryEntry> entriesByMangaId =
        <String, UserLibraryEntry>{};
    final String scopePrefix = _scopePrefix(userId);

    for (final String key in _prefs.getKeys().where(
      (entry) => entry.startsWith(scopePrefix),
    )) {
      final String? raw = _prefs.getString(key);
      if (raw == null) {
        continue;
      }

      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        final UserLibraryEntryModel model = UserLibraryEntryModel.fromJson(
          json,
        );
        final UserLibraryEntry entry = model.toEntity();
        entriesByMangaId[entry.manga.id] = entry;
      } on Object {
        await _prefs.remove(key);
      }
    }

    return entriesByMangaId;
  }

  @override
  Future<Map<String, UserLibraryEntry>> hydrate(String userId) async {
    final Map<String, UserLibraryEntry> localUser = await getAll(userId: userId);
    final Map<String, UserLibraryEntry> guest = await getAll();
    final Map<String, UserLibraryEntry> local = mergeByUpdatedAt(
      local: localUser,
      remote: guest,
    );

    try {
      final Map<String, UserLibraryEntry> remote = await _remoteDataSource
          .getLibrary();
      final Map<String, UserLibraryEntry> merged = mergeByUpdatedAt(
        local: local,
        remote: remote,
      );

      await _replaceScopedEntries(userId: userId, entriesByMangaId: merged);
      await _syncLocalWins(local: local, remote: remote);
      await _clearGuestEntries();
      await _setLastSyncedAt(userId);

      return merged;
    } on Object {
      // Keep local-first behavior when unauthenticated or remote fails.
      return local;
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String userId) async {
    final String? raw = _prefs.getString('$_lastSyncPrefix$userId');
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  @override
  Future<bool> isHydrated(String userId) async {
    return _prefs.containsKey('$_lastSyncPrefix$userId');
  }

  @override
  Future<void> save(UserLibraryEntry entry, {String? userId}) async {
    await _migrateLegacyGuestDataIfNeeded();

    final UserLibraryEntryModel model = UserLibraryEntryModel.fromEntity(entry);
    await _prefs.setString(
      _entryKey(entry.manga.id, userId),
      jsonEncode(model.toJson()),
    );

    if (userId == null) {
      return;
    }

    // Remote sync in background — optimistic UI: caller updates state immediately.
    unawaited(_syncSaveToRemote(entry, userId));
  }

  Future<void> _syncSaveToRemote(UserLibraryEntry entry, String userId) async {
    try {
      if (entry.isInLibrary) {
        await _remoteDataSource.addToLibrary(
          entry.manga.id,
          title: entry.manga.title,
          coverUrl: entry.manga.coverUrl,
          authors: entry.manga.authors,
          type: entry.manga.type,
          demographic: entry.manga.demographic,
          genres: entry.manga.genres,
          status: entry.manga.status,
        );
        await _remoteDataSource.updateLibraryStatus(
          entry.manga.id,
          entry.status,
        );
      } else {
        await _remoteDataSource.removeFromLibrary(entry.manga.id);
      }
    } on Object {
      // Local-first fallback: remote sync is best-effort.
    }
  }

  @override
  Future<void> remove(String mangaId, {String? userId}) async {
    await _migrateLegacyGuestDataIfNeeded();

    await _prefs.remove(_entryKey(mangaId, userId));

    if (userId == null) {
      return;
    }

    // Remote sync in background — optimistic UI: caller updates state immediately.
    unawaited(_syncRemoveFromRemote(mangaId));
  }

  Future<void> _syncRemoveFromRemote(String mangaId) async {
    try {
      await _remoteDataSource.removeFromLibrary(mangaId);
    } on Object {
      // Local-first fallback: remote sync is best-effort.
    }
  }

  Map<String, UserLibraryEntry> mergeByUpdatedAt({
    required Map<String, UserLibraryEntry> local,
    required Map<String, UserLibraryEntry> remote,
  }) {
    final Map<String, UserLibraryEntry> merged = <String, UserLibraryEntry>{
      ...local,
    };

    for (final MapEntry<String, UserLibraryEntry> entry in remote.entries) {
      final UserLibraryEntry? localEntry = merged[entry.key];

      if (localEntry == null) {
        merged[entry.key] = entry.value;
      } else if (!localEntry.updatedAt.isAfter(entry.value.updatedAt)) {
        // Remote is newer or equal — use remote BUT preserve local metadata
        // enrichment (type, demographic, genres) that the library endpoint
        // may not return.
        merged[entry.key] = _withLocalEnrichment(localEntry, entry.value);
      }
      // else: local is newer → keep local (already in merged from ...local)
    }

    return merged;
  }

  /// Merges richer manga metadata from [local] into [remote] when remote is
  /// missing fields that local has (e.g. type, demographic after a sync with
  /// a backend that doesn't return them in the library endpoint).
  UserLibraryEntry _withLocalEnrichment(
    UserLibraryEntry local,
    UserLibraryEntry remote,
  ) {
    final Manga lm = local.manga;
    final Manga rm = remote.manga;

    // If local already has everything remote has, skip.
    if (lm.type == null && lm.demographic == null && lm.genres.isEmpty) {
      return remote;
    }

    return UserLibraryEntry(
      manga: Manga(
        id: rm.id,
        title: rm.title,
        description: lm.description ?? rm.description,
        coverUrl: rm.coverUrl,
        demographic: lm.demographic ?? rm.demographic,
        status: lm.status ?? rm.status,
        genres: lm.genres.isNotEmpty ? lm.genres : rm.genres,
        score: lm.score ?? rm.score,
        rank: lm.rank ?? rm.rank,
        type: lm.type ?? rm.type,
        year: lm.year ?? rm.year,
        authors: lm.authors.isNotEmpty ? lm.authors : rm.authors,
        readChaptersCount: rm.readChaptersCount,
        totalChaptersCount: rm.totalChaptersCount,
        malId: lm.malId ?? rm.malId,
      ),
      isInLibrary: remote.isInLibrary,
      status: remote.status,
      updatedAt: remote.updatedAt,
    );
  }

  Future<void> _replaceScopedEntries({
    required String userId,
    required Map<String, UserLibraryEntry> entriesByMangaId,
  }) async {
    for (final String key in _prefs.getKeys().where(
      (entry) => entry.startsWith(_scopePrefix(userId)),
    )) {
      await _prefs.remove(key);
    }

    for (final UserLibraryEntry entry in entriesByMangaId.values) {
      final UserLibraryEntryModel model = UserLibraryEntryModel.fromEntity(
        entry,
      );
      await _prefs.setString(
        _entryKey(entry.manga.id, userId),
        jsonEncode(model.toJson()),
      );
    }
  }

  Future<void> _clearGuestEntries() async {
    for (final String key in _prefs.getKeys().where(
      (entry) => entry.startsWith(_scopePrefix(null)),
    )) {
      await _prefs.remove(key);
    }
  }

  Future<void> _syncLocalWins({
    required Map<String, UserLibraryEntry> local,
    required Map<String, UserLibraryEntry> remote,
  }) async {
    for (final MapEntry<String, UserLibraryEntry> localEntry in local.entries) {
      final UserLibraryEntry? remoteEntry = remote[localEntry.key];

      // ponytail: re-push entries whose remote metadata is critically null
      // (score, malId) so the backend enriches from MangaDex.
      // Tracks attempted IDs to avoid re-pushing permanently nullable metadata
      // (e.g. unrated manga) on every hydration.
      final bool needsEnrichment = remoteEntry != null &&
          !_enrichmentAttempted.contains(localEntry.key) &&
          _hasNullCoreMetadata(remoteEntry.manga);

      final bool shouldPush =
          remoteEntry == null ||
          localEntry.value.updatedAt.isAfter(remoteEntry.updatedAt) ||
          needsEnrichment;

      if (!shouldPush) {
        continue;
      }

      if (needsEnrichment) {
        _enrichmentAttempted.add(localEntry.key);
      }

      try {
        await _remoteDataSource.addToLibrary(
          localEntry.key,
          title: localEntry.value.manga.title,
          coverUrl: localEntry.value.manga.coverUrl,
          authors: localEntry.value.manga.authors,
        );
        await _remoteDataSource.updateLibraryStatus(
          localEntry.key,
          localEntry.value.status,
        );
      } on Object {
        // Best-effort background sync.
      }
    }
  }

  /// Returns true when the manga entry has null for at least one core
  /// enrichment field, indicating the cached metadata was never enriched.
  static bool _hasNullCoreMetadata(Manga manga) {
    return manga.score == null || manga.malId == null;
  }

  Future<void> _migrateLegacyGuestDataIfNeeded() async {
    if (_legacyMigrated) {
      return;
    }

    final List<String> legacyKeys = _prefs
        .getKeys()
        .where(
          (entry) =>
              entry.startsWith(_legacyPrefix) && !entry.startsWith(_prefix),
        )
        .toList(growable: false);

    for (final String legacyKey in legacyKeys) {
      final String? raw = _prefs.getString(legacyKey);
      if (raw == null) {
        await _prefs.remove(legacyKey);
        continue;
      }

      final String mangaId = legacyKey.substring(_legacyPrefix.length);
      await _prefs.setString(_entryKey(mangaId, null), raw);
      await _prefs.remove(legacyKey);
    }

    _legacyMigrated = true;
  }

  String _entryKey(String mangaId, String? userId) {
    return '${_scopePrefix(userId)}$mangaId';
  }

  String _scopePrefix(String? userId) {
    final String scope = userId == null ? 'guest' : 'user.$userId';
    return '$_prefix$scope.';
  }

  Future<void> _setLastSyncedAt(String userId) async {
    await _prefs.setString(
      '$_lastSyncPrefix$userId',
      DateTime.now().toIso8601String(),
    );
  }
}
