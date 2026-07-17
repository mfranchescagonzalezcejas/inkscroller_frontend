import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/language_selector.dart';

void main() {
  group('LanguageSelector', () {
    testWidgets('renders available languages as dropdown items', (
      tester,
    ) async {
      final languages = <String>['en', 'es', 'ja'];
      String selected = 'en';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: languages,
              selectedLanguage: selected,
              onLanguageChanged: (lang) => selected = lang,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Inglés'), findsWidgets);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Japonés'), findsOneWidget);
    });

    testWidgets('shows plain text label when only one language available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['it'],
              selectedLanguage: 'it',
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Italiano'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('shows dropdown when multiple languages available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es'],
              selectedLanguage: 'en',
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows disabled dropdown with loading text when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es'],
              selectedLanguage: 'en',
              isLoading: true,
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Cargando…'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('calls onLanguageChanged when a language is selected', (
      tester,
    ) async {
      String? changedLanguage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es'],
              selectedLanguage: 'en',
              onLanguageChanged: (lang) => changedLanguage = lang,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Español').last);
      await tester.pumpAndSettle();

      expect(changedLanguage, equals('es'));
    });

    testWidgets('displays the selectedLanguage value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es', 'ja'],
              selectedLanguage: 'ja',
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Japonés'), findsOneWidget);
    });

    testWidgets('falls back to first language when selectedLanguage is not available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es'],
              selectedLanguage: 'fr',
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Inglés'), findsOneWidget);
      expect(find.text('Francés'), findsNothing);
    });

    testWidgets('dropdown is disabled while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              availableLanguages: const ['en', 'es'],
              selectedLanguage: 'en',
              isLoading: true,
              onLanguageChanged: (_) {},
            ),
          ),
        ),
      );

      // Shows loading placeholder instead of language options
      expect(find.text('Cargando…'), findsOneWidget);
      expect(find.text('Inglés'), findsNothing);
      expect(find.text('Español'), findsNothing);
    });
  });
}
