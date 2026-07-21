import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/continue_reading_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:mocktail/mocktail.dart';

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockSendEmailVerification extends Mock
    implements SendEmailVerification {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

AuthNotifier _stubAuthNotifier({AppUser? user}) {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => Stream<AppUser?>.value(user));
  final getUserProfile = _MockGetUserProfile();
  when(() => getUserProfile()).thenAnswer(
    (_) async => Right<Failure, UserProfile>(
      UserProfile(
        firebaseUid: 'user-1',
        email: 'user@example.com',
        createdAt: DateTime.utc(2026),
      ),
    ),
  );
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: _MockSendPasswordReset(),
    reloadUser: _MockReloadUser(),
    getUserProfile: getUserProfile,
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

AuthNotifier _guestAuthNotifier() => _stubAuthNotifier();

AuthNotifier _authenticatedAuthNotifier() => _stubAuthNotifier(
  user: const AppUser(
    uid: 'user-1',
    email: 'user@example.com',
    isEmailVerified: true,
  ),
);

ReadingProgressNotifier _makeProgressNotifier(
  Map<String, MangaReadingProgress> progress,
) {
  final repository = _MockReadingProgressRepository();
  when(() => repository.getAll()).thenAnswer((_) async => progress);
  when(() => repository.save(any())).thenAnswer((_) async {});
  return ReadingProgressNotifier(repository);
}

UserLibraryNotifier _makeUserLibraryNotifier(
  Map<String, UserLibraryEntry> entries,
) {
  final repository = _MockUserLibraryRepository();
  when(
    () => repository.getAll(userId: any(named: 'userId')),
  ).thenAnswer((_) async => entries);
  when(() => repository.hydrate(any())).thenAnswer((_) async => entries);
  when(
    () => repository.save(any(), userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  return UserLibraryNotifier(repository);
}

Manga _manga({required String id, String? coverUrl}) =>
    Manga(id: id, title: 'Manga $id', coverUrl: coverUrl);

UserLibraryEntry _libraryEntry(Manga manga) => UserLibraryEntry(
  manga: manga,
  isInLibrary: true,
  status: UserLibraryStatus.reading,
  updatedAt: DateTime.utc(2026),
);

MangaReadingProgress _progress({
  required String mangaId,
  int read = 0,
  int total = 0,
  DateTime? updatedAt,
}) => MangaReadingProgress(
  mangaId: mangaId,
  readChapterIds: read > 0
      ? List.generate(read, (i) => 'c-$i').toSet()
      : const <String>{},
  totalChaptersCount: total,
  manuallyMarkedCount: read,
  updatedAt: updatedAt,
);

Widget _buildProviderScope({
  required AuthNotifier authNotifier,
  required ReadingProgressNotifier progressNotifier,
  required UserLibraryNotifier userLibraryNotifier,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((_) => authNotifier),
      readingProgressProvider.overrideWith((_) => progressNotifier),
      userLibraryProvider.overrideWith((_) => userLibraryNotifier),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _continueReadingConsumer(
  ValueChanged<List<ContinueReadingItem>> onData,
) {
  return Consumer(
    builder: (context, ref, _) {
      final async = ref.watch(continueReadingProvider);
      return async.when(
        data: (items) {
          onData(items);
          return Text('count:${items.length}');
        },
        loading: () => const Text('loading'),
        error: (_, __) => const Text('error'),
      );
    },
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  group('continueReadingProvider', () {
    testWidgets('returns empty for guests', (tester) async {
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _guestAuthNotifier(),
          progressNotifier: _makeProgressNotifier(const {}),
          userLibraryNotifier: _makeUserLibraryNotifier(const {}),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('returns empty when there is no progress', (tester) async {
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier(const {}),
          userLibraryNotifier: _makeUserLibraryNotifier(const {}),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('filters unresolved manga', (tester) async {
      final manga = _manga(id: 'm1');
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier({
            'm1': _progress(mangaId: 'm1', read: 5, total: 10),
            'missing': _progress(mangaId: 'missing', read: 3, total: 10),
          }),
          userLibraryNotifier: _makeUserLibraryNotifier({
            manga.id: _libraryEntry(manga),
          }),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('filters zero progress', (tester) async {
      final manga = _manga(id: 'm1');
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier({
            'm1': _progress(mangaId: 'm1', total: 10),
          }),
          userLibraryNotifier: _makeUserLibraryNotifier({
            manga.id: _libraryEntry(manga),
          }),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('filters completed entries', (tester) async {
      final manga = _manga(id: 'm1');
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier({
            'm1': _progress(mangaId: 'm1', read: 10, total: 10),
          }),
          userLibraryNotifier: _makeUserLibraryNotifier({
            manga.id: _libraryEntry(manga),
          }),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('sorts by updatedAt descending', (tester) async {
      final mangaA = _manga(id: 'a');
      final mangaB = _manga(id: 'b');
      late List<ContinueReadingItem> captured;
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier({
            'a': _progress(
              mangaId: 'a',
              read: 2,
              total: 10,
              updatedAt: DateTime.utc(2026, 7, 18),
            ),
            'b': _progress(
              mangaId: 'b',
              read: 2,
              total: 10,
              updatedAt: DateTime.utc(2026, 7, 19),
            ),
          }),
          userLibraryNotifier: _makeUserLibraryNotifier({
            'a': _libraryEntry(mangaA),
            'b': _libraryEntry(mangaB),
          }),
          child: _continueReadingConsumer((items) => captured = items),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:2'), findsOneWidget);
      expect(captured.first.manga.id, 'b');
      expect(captured.last.manga.id, 'a');
    });

    testWidgets('caps at 8 items', (tester) async {
      final entries = <String, UserLibraryEntry>{};
      final progress = <String, MangaReadingProgress>{};
      for (var i = 0; i < 10; i++) {
        final id = 'm$i';
        final manga = _manga(id: id);
        entries[id] = _libraryEntry(manga);
        progress[id] = _progress(
          mangaId: id,
          read: 2,
          total: 10,
          updatedAt: DateTime.utc(2026, 7, 19, 12, i),
        );
      }

      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier(progress),
          userLibraryNotifier: _makeUserLibraryNotifier(entries),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:8'), findsOneWidget);
    });

    testWidgets('does not initialize the catalog for unresolved progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildProviderScope(
          authNotifier: _authenticatedAuthNotifier(),
          progressNotifier: _makeProgressNotifier({
            'm1': _progress(mangaId: 'm1', read: 2, total: 10),
          }),
          userLibraryNotifier: _makeUserLibraryNotifier(const {}),
          child: _continueReadingConsumer((items) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('count:0'), findsOneWidget);
    });
  });
}
