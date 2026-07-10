import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/presentation/auth_error_text.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';

import '../../../support/l10n_test_helpers.dart';

void main() {
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

    // ── Firebase auth error codes (EN) ────────────────────────────────────

    testWidgets('resolves invalid credentials key to EN message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authInvalidCredentialsKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Invalid email or password.');
    });

    testWidgets('resolves email already in use key to EN message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authEmailAlreadyInUseKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'This email is already registered.');
    });

    testWidgets('resolves weak password key to EN message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authWeakPasswordKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Password is too weak — use at least 6 characters.');
    });

    testWidgets('resolves too many requests key to EN message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authTooManyRequestsKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Too many attempts. Please wait and try again.');
    });

    testWidgets('resolves network error key to EN message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authNetworkErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'No internet connection. Check your network.');
    });

    testWidgets('resolves unknown error key to EN message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authUnknownErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(result, 'Authentication failed. Please try again.');
    });

    // ── Firebase auth error codes (ES) ────────────────────────────────────

    testWidgets('resolves invalid credentials key to ES message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authInvalidCredentialsKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'Email o contraseña inválidos.');
    });

    testWidgets('resolves email already in use key to ES message', (
      tester,
    ) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authEmailAlreadyInUseKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'Este email ya está registrado.');
    });

    testWidgets('resolves weak password key to ES message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authWeakPasswordKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'La contraseña es muy débil. Usa al menos 6 caracteres.');
    });

    testWidgets('resolves too many requests key to ES message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authTooManyRequestsKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'Demasiados intentos. Espera e intenta de nuevo.');
    });

    testWidgets('resolves network error key to ES message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authNetworkErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'Sin conexión a internet. Verifica tu red.');
    });

    testWidgets('resolves unknown error key to ES message', (tester) async {
      late String result;
      await tester.pumpWidget(
        wrapWithL10n(
          Builder(
            builder: (context) {
              result = authErrorText(context, authUnknownErrorKey);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('es'),
        ),
      );

      expect(result, 'Error de autenticación. Intenta de nuevo.');
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
