import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';
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
        onSyncStart: () =>
            ref.read(userLibrarySyncingProvider.notifier).state = true,
        onSyncEnd: () =>
            ref.read(userLibrarySyncingProvider.notifier).state = false,
      );

      // Hydrate immediately if user is already authenticated (during splash).
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        notifier.onAuthStateChanged(authState.user!.uid);
      }

      // Also listen for future auth changes.
      ref.listen<AuthState>(authProvider, (_, authState) {
        notifier.onAuthStateChanged(authState.user?.uid);
      });

      return notifier;
    });

class UserLibraryNotifier extends StateNotifier<Map<String, UserLibraryEntry>> {
  UserLibraryNotifier(
    this._repository, {
    VoidCallback? onSyncStart,
    VoidCallback? onSyncEnd,
  })  : _onSyncStart = onSyncStart,
        _onSyncEnd = onSyncEnd,
        super(const <String, UserLibraryEntry>{}) {
    _load();
  }

  final UserLibraryRepository _repository;
  final VoidCallback? _onSyncStart;
  final VoidCallback? _onSyncEnd;
  String? _activeUserId;

  Future<void> _load() async {
    state = await _repository.getAll(userId: _activeUserId);
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
  }

  /// Public hydration for explicit refresh from UI.
  Future<void> hydrate(String userId) async {
    state = await _repository.hydrate(userId);
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
}
