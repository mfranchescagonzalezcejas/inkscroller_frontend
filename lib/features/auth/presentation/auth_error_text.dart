import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import 'providers/auth_notifier.dart';

/// Resolves an [AuthState.error] value to a human-readable string.
///
/// Known internal keys such as [authSessionVerificationErrorKey] are mapped to
/// localized strings via [AppLocalizations]. Unknown or legacy error messages
/// (e.g. raw server errors) are returned unchanged so callers do not lose
/// existing error visibility.
///
/// This helper lives in the presentation layer so it may freely import
/// [AppLocalizations] and the notifier key constant without coupling domain or
/// data layers.
String authErrorText(BuildContext context, String? error) {
  if (error == null) return '';
  if (error == authSessionVerificationErrorKey) {
    return AppLocalizations.of(context)!.authSessionVerificationFailed;
  }
  return error;
}
