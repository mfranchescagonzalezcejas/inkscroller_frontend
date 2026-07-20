import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

import 'core/l10n/app_locale_provider.dart';
import 'core/providers/session_startup_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/design/app_colors.dart';
import 'core/widgets/inkscroller_logo_loader.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'flavors/flavor_config.dart';

/// Raíz de la app. Muestra un splash de bienvenida durante ~2 segundos
/// mientras [homeDataProvider] precarga los datos de Home en background.
/// Cuando el splash desaparece, Home ya tiene datos en caché y se renderiza
/// sin shimmer.
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splashController;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Mínimo 2 segundos de splash para que homeDataProvider tenga tiempo
    // de cargar los datos. La animación de salida dura 400ms.
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _splashController.forward().then((_) {
        if (!mounted) return;
        setState(() => _splashDone = true);
      });
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activa providers de startup en segundo plano
    ref.watch(sessionStartupProvider);
    ref.watch(homeDataProvider);

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
        color: AppColors.voidLowest,
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
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
