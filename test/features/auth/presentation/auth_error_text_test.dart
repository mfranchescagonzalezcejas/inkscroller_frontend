import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/presentation/auth_error_text.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  Widget wrapWithL10n(Widget child, {required Locale locale}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) => child),
    );
  }

  group('authErrorText', () {
    testWidgets('resolves session verification key to EN message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authSessionVerificationErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Session could not be verified. Sign in again.');
    });

    testWidgets('resolves session verification key to ES message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authSessionVerificationErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(
        result,
        'No se pudo verificar la sesión. Inicia sesión nuevamente.',
      );
    });

    testWidgets('passes through unknown error strings unchanged', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, 'Invalid credentials');
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Invalid credentials');
    });

    testWidgets('returns empty string for null error', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, null);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, '');
    });
  });
}
