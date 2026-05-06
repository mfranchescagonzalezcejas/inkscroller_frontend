import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/user_library_remote_ds.dart';
import 'package:inkscroller_flutter/features/library/data/repositories/user_library_repository_impl.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRemoteUserLibraryDataSource
    implements UserLibraryRemoteDataSource {
  final Map<String, UserLibraryEntry> remoteStore =
      <String, UserLibraryEntry>{};
  final List<String> addCalls = <String>[];
  final List<String> removeCalls = <String>[];
  final List<(String mangaId, UserLibraryStatus status)> statusCalls =
      <(String, UserLibraryStatus)>[];
  bool throwOnGet = false;

  @override
  Future<void> addToLibrary(
    String mangaId, {
    String? title,
    String? coverUrl,
    List<String> authors = const [],
  }) async {
    addCalls.add(mangaId);
  }

  @override
  Future<Map<String, UserLibraryEntry>> getLibrary() async {
    if (throwOnGet) {
      throw Exception('offline');
    }
    return Map<String, UserLibraryEntry>.from(remoteStore);
  }

  @override
  Future<void> removeFromLibrary(String mangaId) async {
    removeCalls.add(mangaId);
  }

  @override
  Future<void> updateLibraryStatus(
    String mangaId,
    UserLibraryStatus status,
  ) async {
    statusCalls.add((mangaId, status));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late UserLibraryRepositoryImpl repository;
  late _MemoryRemoteUserLibraryDataSource remote;

  UserLibraryEntry makeEntry(
    String mangaId,
    String title,
    DateTime updatedAt, {
    UserLibraryStatus status = UserLibraryStatus.reading,
  }) {
    return UserLibraryEntry(
      manga: Manga(id: mangaId, title: title),
      isInLibrary: true,
      status: status,
      updatedAt: updatedAt,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    remote = _MemoryRemoteUserLibraryDataSource();
    repository = UserLibraryRepositoryImpl(prefs, remote);
  });

  test('save and getAll persist local library entry', () async {
    final UserLibraryEntry entry = makeEntry(
      'm-1',
      'Vagabond',
      DateTime(2026, 4, 12, 10),
    );

    await repository.save(entry);
    final Map<String, UserLibraryEntry> loaded = await repository.getAll();

    expect(loaded, contains('m-1'));
    expect(loaded['m-1']!.manga.title, 'Vagabond');
    expect(loaded['m-1']!.status, UserLibraryStatus.reading);
  });

  test('hydrate keeps local value when local updatedAt is newer', () async {
    final UserLibraryEntry local = makeEntry(
      'm-1',
      'Local',
      DateTime(2026, 4, 12, 10),
      status: UserLibraryStatus.completed,
    );
    final UserLibraryEntry remoteEntry = makeEntry(
      'm-1',
      'Remote',
      DateTime(2026, 4, 12, 9),
    );

    await repository.save(local, userId: 'uid-1');
    remote.remoteStore['m-1'] = remoteEntry;

    final Map<String, UserLibraryEntry> merged = await repository.hydrate(
      'uid-1',
    );

    expect(merged['m-1']!.status, UserLibraryStatus.completed);
    expect(remote.statusCalls.any((entry) => entry.$1 == 'm-1'), isTrue);
  });

  test('hydrate promotes guest entries into authenticated scope on login', () async {
    final UserLibraryEntry guest = makeEntry(
      'm-guest',
      'Pluto',
      DateTime(2026, 4, 12, 10),
      status: UserLibraryStatus.completed,
    );

    await repository.save(guest);

    final Map<String, UserLibraryEntry> merged = await repository.hydrate(
      'uid-1',
    );
    final Map<String, UserLibraryEntry> authScope = await repository.getAll(
      userId: 'uid-1',
    );

    expect(merged, contains('m-guest'));
    expect(authScope, contains('m-guest'));
    expect(authScope['m-guest']!.status, UserLibraryStatus.completed);
    expect(remote.addCalls, contains('m-guest'));
    expect(
      remote.statusCalls.where((call) => call.$1 == 'm-guest').single.$2,
      UserLibraryStatus.completed,
    );
  });

  test('hydrate clears guest scope after successful promotion', () async {
    final UserLibraryEntry guest = makeEntry(
      'm-guest',
      'Ajin',
      DateTime(2026, 4, 12, 10),
    );

    await repository.save(guest);
    expect(prefs.getKeys().any((key) => key.contains('.guest.')), isTrue);

    await repository.hydrate('uid-1');

    expect(prefs.getKeys().any((key) => key.contains('.guest.')), isFalse);
    expect(await repository.getAll(), isEmpty);
  });

  test('hydrate prefers remote entry when remote updatedAt is newer', () async {
    final UserLibraryEntry guest = makeEntry(
      'm-1',
      'Local Guest',
      DateTime(2026, 4, 12, 9),
    );
    final UserLibraryEntry remoteEntry = makeEntry(
      'm-1',
      'Remote',
      DateTime(2026, 4, 12, 11),
      status: UserLibraryStatus.paused,
    );

    await repository.save(guest);
    remote.remoteStore['m-1'] = remoteEntry;

    final Map<String, UserLibraryEntry> merged = await repository.hydrate(
      'uid-1',
    );

    expect(merged['m-1']!.manga.title, 'Remote');
    expect(merged['m-1']!.status, UserLibraryStatus.paused);
  });

  test('hydrate falls back to local data when remote fails', () async {
    final UserLibraryEntry local = makeEntry(
      'm-1',
      'Fallback',
      DateTime(2026, 4, 12, 10),
    );
    await repository.save(local, userId: 'uid-1');
    remote.throwOnGet = true;

    final Map<String, UserLibraryEntry> merged = await repository.hydrate(
      'uid-1',
    );

    expect(merged.keys, contains('m-1'));
    expect(merged['m-1']!.manga.title, 'Fallback');
  });

  test('save with authenticated user triggers remote add + patch', () async {
    final UserLibraryEntry entry = makeEntry(
      'm-2',
      'Monster',
      DateTime(2026, 4, 12, 11),
      status: UserLibraryStatus.paused,
    );

    await repository.save(entry, userId: 'uid-1');

    expect(remote.addCalls, contains('m-2'));
    expect(
      remote.statusCalls.where((call) => call.$1 == 'm-2').single.$2,
      UserLibraryStatus.paused,
    );
  });

  test('remove with authenticated user triggers remote delete', () async {
    await repository.remove('m-3', userId: 'uid-1');

    expect(remote.removeCalls, contains('m-3'));
  });

  test('getAll removes corrupted values from storage', () async {
    await prefs.setString('library.user_library.v2.guest.bad', '{broken json');

    final Map<String, UserLibraryEntry> loaded = await repository.getAll();

    expect(loaded, isEmpty);
    expect(prefs.getString('library.user_library.v2.guest.bad'), isNull);
  });
}
