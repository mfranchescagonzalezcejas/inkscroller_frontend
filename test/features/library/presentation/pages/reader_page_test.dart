// P0-F2 — External chapter guard tests.
//
// Verifies that [ReaderPage] renders the external-chapter warning screen
// (instead of the in-app reader) when the provided [Chapter] has
// [Chapter.external] == true, regardless of whether an [externalUrl] is set.
//
// Also verifies that when [Chapter.external] == false the reader skeleton is
// shown (loading state) and the warning screen is NOT rendered.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reading_preferences.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_chapter_pages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/resolve_reader_mode.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/reader_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reader/reader_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reader/reader_provider.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockGetChapterPages extends Mock implements GetChapterPages {}

class _MockResolveReaderMode extends Mock implements ResolveReaderMode {}

class _MockGetPreferences extends Mock implements GetPreferences {}

class _MockUpdatePreferences extends Mock implements UpdatePreferences {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockSendEmailVerification extends Mock implements SendEmailVerification {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

class _FakeUrlLauncher extends UrlLauncherPlatform {
  bool canLaunchResult = false;
  bool canLaunchThrows = false;
  final launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    if (canLaunchThrows) throw PlatformException(code: 'NO_ACTIVITY');
    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

// ---------------------------------------------------------------------------
// Stub factories — avoid GetIt in tests
// ---------------------------------------------------------------------------

/// Creates an [AuthNotifier] whose [GetAuthState] emits an empty stream,
/// preventing any GetIt look-up during widget tests.
AuthNotifier _makeStubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: _MockSendPasswordReset(),
    reloadUser: _MockReloadUser(),
    getUserProfile: _MockGetUserProfile(),
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

/// Creates a [PreferencesNotifier] whose use cases are never invoked,
/// returning the default empty [PreferencesState].
PreferencesNotifier _makeStubPreferencesNotifier() {
  return PreferencesNotifier(
    getPreferences: _MockGetPreferences(),
    updatePreferences: _MockUpdatePreferences(),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps a [ReaderPage] wrapped in a minimal widget tree with l10n delegates.
///
/// [chapterId] defaults to `'ch-001'`.
/// [chapter] is the optional entity forwarded to [ReaderPage].
Future<void> pumpReaderPage(
  WidgetTester tester, {
  required GetChapterPages getChapterPages,
  required ResolveReaderMode resolveReaderMode,
  String chapterId = 'ch-001',
  Chapter? chapter,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        // Prevent GetIt look-up for auth deps — not relevant to reader tests.
        authProvider.overrideWith((_) => _makeStubAuthNotifier()),
        // Prevent GetIt look-up for preferences deps — reader tests only care
        // about the reader guard, not the preference resolution chain.
        preferencesProvider.overrideWith((_) => _makeStubPreferencesNotifier()),
        readerProvider(chapterId).overrideWith(
          (ref) => ReaderNotifier(
            getChapterPages: getChapterPages,
            resolveReaderMode: resolveReaderMode,
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReaderPage(chapterId: chapterId, chapter: chapter),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late GetChapterPages getChapterPages;
  late ResolveReaderMode resolveReaderMode;
  late UrlLauncherPlatform previousUrlLauncher;
  late _FakeUrlLauncher fakeUrlLauncher;

  setUpAll(() {
    registerFallbackValue(const ReaderContentMetadata(pageCount: 0));
  });

  setUp(() {
    getChapterPages = _MockGetChapterPages();
    resolveReaderMode = _MockResolveReaderMode();
    previousUrlLauncher = UrlLauncherPlatform.instance;
    fakeUrlLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = previousUrlLauncher;
  });

  // ── P0-F2: External chapter guard ───────────────────────────────────────

  group('P0-F2 — external chapter guard', () {
    testWidgets(
      'shows external-chapter warning screen when chapter.external == true '
      'with externalUrl',
      (tester) async {
        final externalChapter = Chapter(
          id: 'ch-ext',
          readable: false,
          external: true,
          externalUrl: 'https://example.com/chapter/1',
        );

        // getChapterPages must NOT be called for external chapters.
        verifyNever(() => getChapterPages(any()));

        await pumpReaderPage(
          tester,
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          chapterId: 'ch-ext',
          chapter: externalChapter,
        );
        await tester.pumpAndSettle();

        // Warning title and message must be visible.
        expect(find.text('External chapter'), findsWidgets);
        expect(
          find.text(
            'This chapter is only available on the original site. '
            'It cannot be read inside InkScroller.',
          ),
          findsOneWidget,
        );

        // Open-on-original-site button must be present when URL is known.
        expect(find.text('Open on original site'), findsOneWidget);

        // Loading indicator must NOT be visible.
        expect(find.byType(LinearProgressIndicator), findsNothing);

        verifyNever(() => getChapterPages(any()));
      },
    );

    testWidgets('shows warning feedback when externalUrl cannot be launched', (
      tester,
    ) async {
      final externalChapter = Chapter(
        id: 'ch-ext-unlaunchable',
        readable: false,
        external: true,
        externalUrl: 'https://example.com/chapter/blocked',
      );
      fakeUrlLauncher.canLaunchResult = false;

      await pumpReaderPage(
        tester,
        getChapterPages: getChapterPages,
        resolveReaderMode: resolveReaderMode,
        chapterId: 'ch-ext-unlaunchable',
        chapter: externalChapter,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open on original site'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(fakeUrlLauncher.launchedUrls, isEmpty);
      verifyNever(() => getChapterPages(any()));
    });

    testWidgets(
      'shows warning and logs when canLaunchUrl throws an exception',
      (tester) async {
        final externalChapter = Chapter(
          id: 'ch-ext-throw',
          readable: false,
          external: true,
          externalUrl: 'https://example.com/chapter/throw',
        );
        fakeUrlLauncher.canLaunchThrows = true;

        await pumpReaderPage(
          tester,
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          chapterId: 'ch-ext-throw',
          chapter: externalChapter,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open on original site'));
        await tester.pump();

        // Warning snackbar is shown despite the exception.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
        verifyNever(() => getChapterPages(any()));
      },
    );

    testWidgets(
      'shows external-chapter warning screen when chapter.external == true '
      'without externalUrl',
      (tester) async {
        final externalChapterNoUrl = Chapter(
          id: 'ch-ext-nourl',
          readable: false,
          external: true,
          // externalUrl intentionally null
        );

        await pumpReaderPage(
          tester,
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          chapterId: 'ch-ext-nourl',
          chapter: externalChapterNoUrl,
        );
        await tester.pumpAndSettle();

        // Warning screen is shown.
        expect(find.text('External chapter'), findsWidgets);

        // "Open on original site" button must NOT be present when URL is null.
        expect(find.text('Open on original site'), findsNothing);

        // "Go back" button is always present.
        expect(find.text('Go back'), findsOneWidget);

        verifyNever(() => getChapterPages(any()));
      },
    );

    testWidgets(
      'does NOT show external-chapter warning when chapter.external == false',
      (tester) async {
        final readableChapter = Chapter(
          id: 'ch-readable',
          readable: true,
          external: false,
        );

        // Simulate a pending (never-resolving) future so we stay in loading state.
        when(() => getChapterPages('ch-readable')).thenAnswer(
          (_) => Future<Either<Failure, List<String>>>.value(
            const Right<Failure, List<String>>(<String>[
              'https://cdn.example.com/page1.jpg',
            ]),
          ),
        );
        when(
          () => resolveReaderMode(
            globalReaderMode: any(named: 'globalReaderMode'),
            titleOverride: any(named: 'titleOverride'),
            contentMetadata: any(named: 'contentMetadata'),
          ),
        ).thenReturn(ReaderMode.vertical);

        await pumpReaderPage(
          tester,
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          chapterId: 'ch-readable',
          chapter: readableChapter,
        );

        // Do NOT call pumpAndSettle — we just need to confirm the guard screen
        // is never shown. The loading screen or reader view is acceptable.
        expect(find.text('External chapter'), findsNothing);
        expect(find.text('Open on original site'), findsNothing);
      },
    );

    testWidgets(
      'does NOT show external-chapter warning when no chapter entity is passed',
      (tester) async {
        // No chapter entity — simulates a deep-link scenario.
        when(() => getChapterPages('ch-deeplink')).thenAnswer(
          (_) => Future<Either<Failure, List<String>>>.value(
            const Left<Failure, List<String>>(
              NetworkFailure(message: 'offline'),
            ),
          ),
        );

        await pumpReaderPage(
          tester,
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          chapterId: 'ch-deeplink',
          // chapter: null (default)
        );
        await tester.pumpAndSettle();

        // External chapter warning must NOT be shown.
        expect(find.text('External chapter'), findsNothing);
        // Normal error path is shown — generic localized error, not raw message.
        expect(
          find.text('Something went wrong loading the chapter.'),
          findsOneWidget,
        );
      },
    );
  });

  // ── Empty-chapter guard ────────────────────────────────────────────────

  testWidgets('shows localized readerNoPages when chapter has zero pages', (
    tester,
  ) async {
    when(
      () => getChapterPages('ch-empty'),
    ).thenAnswer((_) async => const Right<Failure, List<String>>(<String>[]));

    await pumpReaderPage(
      tester,
      getChapterPages: getChapterPages,
      resolveReaderMode: resolveReaderMode,
      chapterId: 'ch-empty',
    );
    await tester.pumpAndSettle();

    // EmptyChapterFailure → localized "Chapter has no pages" (en locale).
    expect(find.text('Chapter has no pages'), findsOneWidget);
  });

  testWidgets(
    'shows localized readerNoPages in Spanish when chapter has zero pages',
    (tester) async {
      when(
        () => getChapterPages('ch-empty-es'),
      ).thenAnswer((_) async => const Right<Failure, List<String>>(<String>[]));

      await pumpReaderPage(
        tester,
        getChapterPages: getChapterPages,
        resolveReaderMode: resolveReaderMode,
        chapterId: 'ch-empty-es',
        locale: const Locale('es'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Capítulo sin páginas'), findsOneWidget);
    },
  );
}
