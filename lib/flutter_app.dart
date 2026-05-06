import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

import 'core/l10n/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'flavors/flavor_config.dart';

/// Root [MaterialApp.router] that configures theming and declarative routing.
///
/// Reads the active flavor name for the app title, applies [AppTheme] light
/// and dark themes, and wires the centralized [appRouter].
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: FlavorConfig.instance.name,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
