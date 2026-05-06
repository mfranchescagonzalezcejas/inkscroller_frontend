import 'package:flutter/widgets.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

/// Convenience access to generated localized strings.
extension AppLocalizationsX on BuildContext {
  /// Returns the active [AppLocalizations] instance.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
