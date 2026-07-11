// #149 — About page l10n and dynamic version tests.
//
// Verifies that [AboutPage] renders all localized sections (identity,
// disclaimer, credits) and shows the real app version when package info is
// available.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inkscroller_flutter/core/constants/app_constants.dart';
import 'package:inkscroller_flutter/features/about/presentation/pages/about_page.dart';

import '../../../../support/l10n_test_helpers.dart';

/// Creates the PlatformChannel mock JSON that [PackageInfo.fromPlatform]
/// expects on Android / Linux / Windows.
Map<String, dynamic> _mockPackageInfoData({
  String appName = 'InkScroller',
  String packageName = 'com.inkscroller.app',
  String version = '1.2.3',
  String buildNumber = '42',
  String buildSignature = 'debug',
}) {
  return <String, dynamic>{
    'appName': appName,
    'packageName': packageName,
    'version': version,
    'buildNumber': buildNumber,
    'buildSignature': buildSignature,
  };
}

/// Pumps an [AboutPage] wrapped in l10n with an optional package-info mock.
Future<void> pumpAboutPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Map<String, dynamic>? mockPackageInfo,
}) async {
  // Channel name used by package_info_plus on all desktop / linux platforms.
  // We set it up before every test run.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (methodCall) async {
      if (methodCall.method == 'getAll') {
        return mockPackageInfo ?? _mockPackageInfoData();
      }
      return null;
    },
  );

  await tester.pumpWidget(
    wrapWithL10n(const AboutPage(), locale: locale),
  );
  // Let the async PackageInfo.fromPlatform() resolve.
  await tester.pumpAndSettle();
}

/// Checks that a specific text string appears exactly once on page.
void expectText(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget);
}

void main() {
  // ── App identity ───────────────────────────────────────────────────────

  group('app identity section', () {
    testWidgets('renders app name', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, AppConstants.appName);
    });

    testWidgets('renders version string when package info resolves', (
      tester,
    ) async {
      await pumpAboutPage(tester);
      expectText(tester, 'Version 1.2.3 (Build 42)');
    });

    testWidgets('renders version string in Spanish when package info resolves', (
      tester,
    ) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'Versión 1.2.3 (Build 42)');
    });

    testWidgets('renders app description', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, 'Personal manga reader — open source');
    });

    testWidgets('renders app description in Spanish', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'Lector de manga personal — código abierto');
    });
  });

  // ── Disclaimer section (English) ───────────────────────────────────────

  group('disclaimer section (en)', () {
    testWidgets('renders section title', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, 'DISCLAIMER');
    });

    testWidgets('renders MangaDex disclaimer', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, 'Not affiliated with MangaDex');
    });

    testWidgets('renders MyAnimeList disclaimer', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, 'Not affiliated with MyAnimeList');
    });

    testWidgets('renders copyright disclaimer', (tester) async {
      await pumpAboutPage(tester);
      expectText(tester, 'Content copyright');
    });
  });

  // ── Disclaimer section (Spanish) ───────────────────────────────────────

  group('disclaimer section (es)', () {
    testWidgets('renders section title', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'AVISO LEGAL');
    });

    testWidgets('renders MangaDex disclaimer', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'Sin afiliación a MangaDex');
    });

    testWidgets('renders MyAnimeList disclaimer', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'Sin afiliación a MyAnimeList');
    });

    testWidgets('renders copyright disclaimer', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      expectText(tester, 'Derechos de autor del contenido');
    });
  });

  // ── Credits section ────────────────────────────────────────────────────

  group('credits section', () {
    /// Scrolls the [ListView] down so lazy-built credit items are in the tree.
    Future<void> scrollToCredits(WidgetTester tester) async {
      // Drag up ~400px to bring the credits section into view.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    testWidgets('renders section title in English', (tester) async {
      await pumpAboutPage(tester);
      await scrollToCredits(tester);
      expectText(tester, 'CREDITS AND APIs');
    });

    testWidgets('renders section title in Spanish', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      await scrollToCredits(tester);
      expectText(tester, 'CRÉDITOS Y APIs');
    });

    testWidgets('renders all four credit rows', (tester) async {
      await pumpAboutPage(tester);
      await scrollToCredits(tester);

      // Each credit appears as a name+description pair.
      expectText(tester, 'MangaDex API');
      expectText(tester, 'Jikan API');
      expectText(tester, 'Google Cloud Run');
      expectText(tester, 'Firebase Auth');
    });

    testWidgets('renders credit descriptions in Spanish', (tester) async {
      await pumpAboutPage(tester, locale: const Locale('es'));
      await scrollToCredits(tester);
      expectText(tester, 'Catálogo, capítulos y portadas');
      expectText(tester, 'Metadatos adicionales (MAL)');
      expectText(tester, 'Infraestructura de backend');
      expectText(tester, 'Autenticación de usuarios');
    });
  });

  // ── Structural smoke tests ─────────────────────────────────────────────

  group('structural', () {
    testWidgets('page renders Scaffold with AppBar', (tester) async {
      await pumpAboutPage(tester);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
