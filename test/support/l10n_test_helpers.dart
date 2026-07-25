import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

/// Wraps [child] in a [MaterialApp] pre-configured with [AppLocalizations]
/// delegates and supported locales for l10n-dependent widget tests.
///
/// The [locale] parameter determines the active locale for the test.
/// When supplied, [theme] is forced so tests can verify either brightness.
Widget wrapWithL10n(Widget child, {required Locale locale, ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    themeMode: theme == null ? ThemeMode.system : ThemeMode.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
