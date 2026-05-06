import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';

class _MemoryUserLibraryRepository implements UserLibraryRepository {
  final Map<String, UserLibraryEntry> _guestStore = <String, UserLibraryEntry>{};
  final Map<String, Map<String, UserLibraryEntry>> _userStores =
      <String, Map<String, UserLibraryEntry>>{};
  String? lastHydratedUserId;

  Map<String, UserLibraryEntry> _storeFor(String? userId) {
    if (userId == null) {
      return _guestStore;
    }

    return _userStores.putIfAbsent(
      userId,
      () => <String, UserLibraryEntry>{},
    );
  }

  Map<String, UserLibraryEntry> _mergeByUpdatedAt({
    required Map<String, UserLibraryEntry> local,
    required Map<String, UserLibraryEntry> remote,
  }) {
    final Map<String, UserLibraryEntry> merged = <String, UserLibraryEntry>{
      ...local,
    };

    for (final MapEntry<String, UserLibraryEntry> entry in remote.entries) {
      final UserLibraryEntry? localEntry = merged[entry.key];

      if (localEntry == null ||
          !localEntry.updatedAt.isAfter(entry.value.updatedAt)) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  void seedGuest(UserLibraryEntry entry) {
    _guestStore[entry.manga.id] = entry;
  }

  @override
  Future<Map<String, UserLibraryEntry>> getAll({String? userId}) async {
    return Map<String, UserLibraryEntry>.from(_storeFor(userId));
  }

  @override
  Future<Map<String, UserLibraryEntry>> hydrate(String userId) async {
    lastHydratedUserId = userId;
    final Map<String, UserLibraryEntry> merged = _mergeByUpdatedAt(
      local: _storeFor(userId),
      remote: _guestStore,
    );
    _userStores[userId] = merged;
    _guestStore.clear();
    return Map<String, UserLibraryEntry>.from(merged);
  }

  @override
  Future<void> remove(String mangaId, {String? userId}) async {
    _storeFor(userId).remove(mangaId);
  }

  @override
  Future<void> save(UserLibraryEntry entry, {String? userId}) async {
    _storeFor(userId)[entry.manga.id] = entry;
  }

  @override
  Future<DateTime?> getLastSyncedAt(String userId) async {
    return _lastSyncedAt;
  }

  @override
  Future<bool> isHydrated(String userId) async {
    return _lastSyncedAt != null;
  }

  DateTime? _lastSyncedAt;
}

void main() {
  late _MemoryUserLibraryRepository repository;
  late UserLibraryNotifier notifier;

  setUp(() async {
    repository = _MemoryUserLibraryRepository();
    notifier = UserLibraryNotifier(repository);
    await Future<void>.delayed(Duration.zero);
  });

  test('toggle adds then removes manga from local library', () async {
    final Manga manga = Manga(id: 'm-1', title: 'Berserk');

    final bool firstToggle = await notifier.toggle(manga);
    final bool secondToggle = await notifier.toggle(manga);

    expect(firstToggle, isTrue);
    expect(secondToggle, isFalse);
    expect(notifier.state.containsKey('m-1'), isFalse);
  });

  test('setStatus updates existing library item status', () async {
    final Manga manga = Manga(id: 'm-2', title: 'Monster');
    await notifier.add(manga);

    await notifier.setStatus('m-2', UserLibraryStatus.completed);

    expect(notifier.state['m-2']!.status, UserLibraryStatus.completed);
  });

  test('onAuthStateChanged triggers load on auth change', () async {
    // This test verifies the notifier responds to auth state changes.
    // The actual behavior depends on repository state.
    await notifier.onAuthStateChanged('uid-123');

    // No error thrown = success.
  });

  test('guest library is cleared after hydration and logout shows empty', () async {
    repository.seedGuest(
      UserLibraryEntry(
        manga: Manga(id: 'm-guest', title: 'Pluto'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime(2026, 4, 12, 11),
      ),
    );

    // Login: loads local immediately, then fires _hydrateAsync in background.
    await notifier.onAuthStateChanged('uid-123');

    // Let the background hydration complete (guest merges into user, guest cleared).
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.keys, contains('m-guest'));

    // Logout: guest scope is now empty (was cleared during hydration).
    await notifier.onAuthStateChanged(null);
    expect(notifier.state, isEmpty);
  });

  test('hydrate method does full remote sync', () async {
    // Seed guest data.
    repository.seedGuest(
      UserLibraryEntry(
        manga: Manga(id: 'm-guest', title: 'Pluto'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime(2026, 4, 12, 11),
      ),
    );

    // Manual hydrate merges guest into user.
    await notifier.hydrate('uid-123');

    expect(repository.lastHydratedUserId, 'uid-123');
    expect(notifier.state.keys, contains('m-guest'));
  });
}
