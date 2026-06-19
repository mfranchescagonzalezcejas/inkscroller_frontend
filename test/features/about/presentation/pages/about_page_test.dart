import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/app_version_provider.dart';
import 'package:inkscroller_flutter/features/about/presentation/pages/about_page.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpAboutPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appVersionProvider.overrideWith(
            (ref) async =>
                const AppVersionInfo(version: '1.2.3', buildNumber: '45'),
          ),
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
    await pumpAboutPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Versión 1.2.3 (Build 45)'), findsOneWidget);
    expect(find.text('Versión 0.4.2 (Build 20)'), findsNothing);
  });
}
