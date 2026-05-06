import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../di/injection.dart';

/// Riverpod controller for app-level UI locale.
///
/// Persists the selected locale in SharedPreferences and restores it on app
/// startup.
class AppLocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences sharedPreferences;

  AppLocaleNotifier({required this.sharedPreferences})
    : super(_loadInitialLocale(sharedPreferences));

  static Locale? _loadInitialLocale(SharedPreferences sharedPreferences) {
    final code = sharedPreferences.getString(
      AppConstants.appLocalePreferenceKey,
    );
    if (code == null || code.isEmpty) return null;
    return supportedUiLocaleFromLanguage(code);
  }

  /// Applies and persists a supported app locale.
  Future<void> setAppLanguage(String languageCode) async {
    final locale = supportedUiLocaleFromLanguage(languageCode);
    if (locale == null) return;
    state = locale;
    await sharedPreferences.setString(
      AppConstants.appLocalePreferenceKey,
      languageCode,
    );
  }
}

/// Global UI locale override for [MaterialApp].
///
/// `null` means "follow device locale".
final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale?>(
  (ref) => AppLocaleNotifier(sharedPreferences: sl<SharedPreferences>()),
);

/// Maps a language code to a UI locale supported by the app.
///
/// Returns `null` when the language is not currently supported by app l10n.
Locale? supportedUiLocaleFromLanguage(String languageCode) {
  switch (languageCode) {
    case 'en':
      return const Locale('en');
    case 'es':
      return const Locale('es');
    default:
      return null;
  }
}
