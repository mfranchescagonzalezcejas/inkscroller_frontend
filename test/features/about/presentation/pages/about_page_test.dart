import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/app_version_provider.dart';
import 'package:inkscroller_flutter/features/about/presentation/pages/about_page.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpAboutPage(
    WidgetTester tester, {
    required Future<AppVersionInfo> Function() loadVersion,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appVersionProvider.overrideWith((ref) => loadVersion()),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AboutPage(),
        ),
      ),
    );
  }

  testWidgets('renders runtime version and build number', (tester) async {
    await pumpAboutPage(
      tester,
      loadVersion: () async =>
          const AppVersionInfo(version: '1.2.3', buildNumber: '45'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Versión 1.2.3 (Build 45)'), findsOneWidget);
    expect(find.text('Versión 0.4.2 (Build 20)'), findsNothing);
  });

  testWidgets('renders placeholder while version is loading', (tester) async {
    final completer = Completer<AppVersionInfo>();

    await pumpAboutPage(tester, loadVersion: () => completer.future);
    await tester.pump();

    expect(find.text('Versión - (Build -)'), findsOneWidget);

    completer.complete(
      const AppVersionInfo(version: '1.2.3', buildNumber: '45'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('renders placeholder when version lookup fails', (tester) async {
    await pumpAboutPage(
      tester,
      loadVersion: () => Future<AppVersionInfo>.error(Exception('failed')),
    );
    await tester.pump();

    expect(find.text('Versión - (Build -)'), findsOneWidget);
  });
}
