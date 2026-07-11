import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import 'providers/auth_notifier.dart';

/// Resolves an [AuthState.error] value to a human-readable string.
///
/// Known internal keys such as [authSessionVerificationErrorKey] and the
/// Firebase auth error codes in [auth_notifier.dart] are mapped to localized
/// strings via [AppLocalizations]. Unknown or legacy error messages (e.g. raw
/// server errors) are returned unchanged so callers do not lose existing error
/// visibility.
///
/// This helper lives in the presentation layer so it may freely import
/// [AppLocalizations] and the notifier key constants without coupling domain or
/// data layers.
String authErrorText(BuildContext context, String? error) {
  if (error == null) return '';
  final l10n = AppLocalizations.of(context)!;
  return switch (error) {
    authSessionVerificationErrorKey => l10n.authSessionVerificationFailed,
    authInvalidCredentialsKey => l10n.authInvalidCredentials,
    authEmailAlreadyInUseKey => l10n.authEmailAlreadyInUse,
    authWeakPasswordKey => l10n.authWeakPassword,
    authTooManyRequestsKey => l10n.authTooManyRequests,
    authNetworkErrorKey => l10n.authNetworkError,
    authUnknownErrorKey => l10n.authUnknownError,
    _ => error,
  };
}
