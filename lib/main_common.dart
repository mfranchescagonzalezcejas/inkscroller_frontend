import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_environment.dart';
import 'core/config/startup_config_validator.dart';
import 'core/di/injection.dart';
import 'core/network/ipv4_http_override.dart';
import 'firebase_options.dart';
import 'flavors/flavor_banner.dart';
import 'flavors/flavor_config.dart';
import 'flutter_app.dart';

/// Shared bootstrap logic executed by every flavor entry point (`main_dev`, `main_staging`, `main_pro`).
///
/// Performs the following initialization steps in order:
/// 1. Initializes Flutter bindings and defers the first frame to avoid a blank flash.
/// 2. Forces global IPv4-only DNS resolution via [IPv4HttpOverrides].
/// 3. Creates the [FlavorConfig] singleton for the given [flavor] and [apiBaseUrl].
/// 4. Initializes Firebase and sets a user property identifying the current flavor.
/// 5. Runs the GetIt dependency injection setup via [initDI].
/// 6. Launches the app inside [ProviderScope] and [FlavorBanner], then allows the first frame.
Future<void> mainCommon({
  required Flavor flavor,
  required String apiBaseUrl,
  required String name,
}) async {
  assert(
    !AppEnvironment.kIsE2E || flavor == Flavor.dev,
    'E2E mode requires dev flavor',
  );

  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // ⛔ Evita que Flutter renderice la primera frame
  widgetsBinding.deferFirstFrame();

  // 🔥 FORZAR IPv4 GLOBALMENTE
  HttpOverrides.global = IPv4HttpOverrides();

  FlavorConfig(
    flavor: flavor,
    apiBaseUrl: apiBaseUrl,
    name: name,
  );

  final FirebaseOptions firebaseOptions = FirebaseOptionsSelector.current;
  StartupConfigValidator.validate(
    flavor: flavor,
    apiBaseUrl: apiBaseUrl,
    firebaseOptions: firebaseOptions,
  );

  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  await FirebaseAnalytics.instance.setUserProperty(
    name: 'flavor',
    value: flavor.name,
  );

  await initDI();

  runApp(
    const ProviderScope(
      child: FlavorBanner(
        child: MyApp(),
      ),
    ),
  );

  // ✅ Permite renderizar
  widgetsBinding.allowFirstFrame();
}
