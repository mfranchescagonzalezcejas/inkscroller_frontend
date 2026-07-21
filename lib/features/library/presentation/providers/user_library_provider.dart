import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';
import '../../domain/usecases/get_manga_detail.dart';
import '../../domain/repositories/user_library_repository.dart';
import 'reading_progress_provider.dart';

/// True while a background hydration (remote sync) is in progress.
final userLibrarySyncingProvider = StateProvider<bool>((ref) => false);

/// Riverpod source of truth for user local library state.
final userLibraryProvider =
    StateNotifierProvider<UserLibraryNotifier, Map<String, UserLibraryEntry>>((
      ref,
    ) {
      // Warm up reading progress from SharedPreferences in parallel so the
      // data is ready by the time Library tiles are rendered.
      ref.read(readingProgressProvider);

      final UserLibraryNotifier notifier = UserLibraryNotifier(
        sl<UserLibraryRepository>(),
        language: () =>
            ref.read(preferencesProvider).preferences?.defaultLanguage ?? 'en',
        onSyncStart: () =>
            ref.read(userLibrarySyncingProvider.notifier).state = true,
        onSyncEnd: () =>
            ref.read(userLibrarySyncingProvider.notifier).state = false,
      );

      // Hydrate immediately if user is already verified (during splash).
      // Skip hydrate for unverified users — the backend returns 403.
      final authState = ref.read(authProvider);
      if (authState.user != null && authState.user!.isEmailVerified) {
        notifier.onAuthStateChanged(authState.user!.uid);
      }

      // Also listen for future auth changes.
      ref.listen<AuthState>(authProvider, (_, authState) {
        if (authState.user != null && authState.user!.isEmailVerified) {
          notifier.onAuthStateChanged(authState.user!.uid);
        } else if (authState.user == null) {
          notifier.onAuthStateChanged(null);
        }
      });

      return notifier;
    });

class UserLibraryNotifier extends StateNotifier<Map<String, UserLibraryEntry>> {
  UserLibraryNotifier(
    this._repository, {
    String Function()? language,
    VoidCallback? onSyncStart,
    VoidCallback? onSyncEnd,
  }) : _language = language ?? _defaultLanguage,
       _onSyncStart = onSyncStart,
       _onSyncEnd = onSyncEnd,
       super(const <String, UserLibraryEntry>{}) {
    _load();
  }

  final UserLibraryRepository _repository;
  final String Function() _language;
  final VoidCallback? _onSyncStart;
  final VoidCallback? _onSyncEnd;
  String? _activeUserId;

  Future<void> _load() async {
    final entries = await _repository.getAll(userId: _activeUserId);
    if (!mounted) return;
    state = entries;
  }

  Future<void> onAuthStateChanged(String? userId) async {
    if (_activeUserId == userId) {
      return;
    }

    _activeUserId = userId;

    if (userId == null) {
      state = await _repository.getAll();
      return;
    }

    // Hydrate with local-first: load local data immediately, then sync in background.
    state = await _repository.getAll(userId: userId);

    // Background async hydration (fire and forget, updates state when done).
    // ignore: unawaited_futures
    _hydrateAsync(userId);
  }

  Future<void> _hydrateAsync(String userId) async {
    _onSyncStart?.call();
    try {
      state = await _repository.hydrate(userId);
    } on Object {
      // Best-effort background sync; keep local data on failure.
    } finally {
      _onSyncEnd?.call();
    }
    // Fire-and-forget: backfill missing type/demographic without blocking UI.
    unawaited(_enrichMissingMetadata());
  }

  /// Public hydration for explicit refresh from UI.
  Future<void> hydrate(String userId) async {
    state = await _repository.hydrate(userId);
    // Fire-and-forget enrichment so the UI shows data immediately.
    unawaited(_enrichMissingMetadata());
  }

  /// Fetches full manga detail for library entries missing type or demographic.
  /// Runs as fire-and-forget after hydration so the UI gets complete metadata
  /// without blocking the refresh.
  Future<void> _enrichMissingMetadata() async {
    if (!sl.isRegistered<GetMangaDetail>()) return;
    final getDetail = sl<GetMangaDetail>();
    // Preferences are loaded during session startup; never issue another GET
    // while metadata enrichment is running.
    final lang = _language();
    // Snapshot the keys so state mutations in the loop don't affect iteration.
    final ids = state.keys.toList();
    final Map<String, UserLibraryEntry> updates = <String, UserLibraryEntry>{};

    for (final id in ids) {
      final entry = state[id];
      if (entry == null) continue;
      final m = entry.manga;
      if (m.type != null && m.demographic != null) continue;

      final result = await getDetail(m.id, language: lang);
      result.fold((_) {}, (full) {
        if (full.type == null && full.demographic == null) return;

        updates[id] = UserLibraryEntry(
          manga: Manga(
            id: m.id,
            title: m.title,
            description: full.description ?? m.description,
            coverUrl: m.coverUrl,
            demographic: full.demographic ?? m.demographic,
            status: full.status ?? m.status,
            genres: full.genres.isNotEmpty ? full.genres : m.genres,
            score: full.score ?? m.score,
            rank: full.rank ?? m.rank,
            type: full.type ?? m.type,
            year: full.year ?? m.year,
            authors: full.authors.isNotEmpty ? full.authors : m.authors,
            readChaptersCount: m.readChaptersCount,
            totalChaptersCount: m.totalChaptersCount,
            malId: full.malId ?? m.malId,
          ),
          isInLibrary: entry.isInLibrary,
          status: entry.status,
          updatedAt: entry.updatedAt,
        );
      });
    }

    if (updates.isNotEmpty) {
      state = <String, UserLibraryEntry>{...state, ...updates};
    }
  }

  UserLibraryEntry? entryFor(String mangaId) {
    return state[mangaId];
  }

  bool isInLibrary(String mangaId) {
    final UserLibraryEntry? entry = state[mangaId];
    return entry?.isInLibrary ?? false;
  }

  Future<void> add(
    Manga manga, {
    UserLibraryStatus status = UserLibraryStatus.reading,
  }) async {
    final UserLibraryEntry entry = UserLibraryEntry(
      manga: manga,
      isInLibrary: true,
      status: status,
      updatedAt: DateTime.now(),
    );

    await _save(entry);
  }

  Future<void> remove(String mangaId) async {
    await _repository.remove(mangaId, userId: _activeUserId);
    final Map<String, UserLibraryEntry> next =
        Map<String, UserLibraryEntry>.from(state);
    next.remove(mangaId);
    state = next;
  }

  Future<bool> toggle(Manga manga) async {
    if (isInLibrary(manga.id)) {
      await remove(manga.id);
      return false;
    }

    await add(manga);
    return true;
  }

  Future<void> setStatus(String mangaId, UserLibraryStatus status) async {
    final UserLibraryEntry? current = state[mangaId];
    if (current == null || !current.isInLibrary) {
      return;
    }

    await _save(current.copyWith(status: status, updatedAt: DateTime.now()));
  }

  Future<void> _save(UserLibraryEntry entry) async {
    await _repository.save(entry, userId: _activeUserId);
    state = <String, UserLibraryEntry>{...state, entry.manga.id: entry};
  }

  static String _defaultLanguage() => 'en';
}
