import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

import 'core/l10n/app_locale_provider.dart';
import 'core/providers/session_startup_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/inkscroller_logo_loader.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/library/presentation/providers/library/library_state.dart';
import 'flavors/flavor_config.dart';

/// Raíz de la app. Muestra un splash de bienvenida mientras [homeDataProvider]
/// precarga los datos de Home en background. Cuando los datos están listos,
/// el splash hace fade out.
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splashController;
  bool _splashDone = false;
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Tiempo mínimo para que el splash no parpadee
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _minSplashElapsed = true);
      _tryFadeOut();
    });
  }

  void _tryFadeOut() {
    if (!_minSplashElapsed || _splashDone) return;
    final homeData = ref.read(homeDataProvider);
    if (!homeData.isLoading) {
      _splashController.forward().then((_) {
        if (!mounted) return;
        setState(() => _splashDone = true);
      });
    }
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activa providers de startup en segundo plano
    ref.listen<LibraryState>(homeDataProvider, (_, next) {
      if (!next.isLoading) _tryFadeOut();
    });
    ref.watch(sessionStartupProvider);

    final locale = ref.watch(appLocaleProvider);

    final app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: FlavorConfig.instance.name,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );

    if (_splashDone) return app;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        app,
        // Splash overlay — cubre toda la pantalla mientras carga
        if (!_splashDone)
          Positioned.fill(
            child: FadeTransition(
              opacity: _splashController.drive(
                Tween<double>(begin: 1, end: 0),
              ),
              child: const _SplashScreen(),
            ),
          ),
      ],
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        // Fondo oscuro constante — el splash es branding, no parte del tema
        color: const Color(0xFF0D1516),
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkScrollerLogoLoader(),
              SizedBox(height: 24),
              Text(
                'InkScroller',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFFE2E4E6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
