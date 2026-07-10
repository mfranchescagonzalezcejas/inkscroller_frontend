import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

/// Wraps [child] in a [MaterialApp] pre-configured with [AppLocalizations]
/// delegates and supported locales for l10n-dependent widget tests.
///
/// The [locale] parameter determines the active locale for the test.
Widget wrapWithL10n(Widget child, {required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
