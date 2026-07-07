import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'flavors/flavor_config.dart';

class FirebaseOptionsSelector {
  static FirebaseOptions get current {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    //show a log of witch flavor is being used in terminal
    if (kDebugMode) {
      debugPrint('Flavor: ${FlavorConfig.instance.flavor}');
    }    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android();
      case TargetPlatform.iOS:
        return _ios();
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // ---------- ANDROID ----------
  static FirebaseOptions _android() {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.dev:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_ANDROID_DEV_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_ANDROID_DEV_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_ANDROID_DEV_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_ANDROID_DEV_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_ANDROID_DEV_STORAGE_BUCKET'),
        );

      case Flavor.staging:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_ANDROID_STAGING_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_ANDROID_STAGING_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_ANDROID_STAGING_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_ANDROID_STAGING_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_ANDROID_STAGING_STORAGE_BUCKET'),
        );

      case Flavor.pro:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_ANDROID_PRO_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_ANDROID_PRO_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_ANDROID_PRO_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_ANDROID_PRO_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_ANDROID_PRO_STORAGE_BUCKET'),
        );
    }
  }

  // ---------- iOS ----------
  static FirebaseOptions _ios() {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.dev:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_IOS_DEV_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_IOS_DEV_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_IOS_DEV_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_IOS_DEV_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_IOS_DEV_STORAGE_BUCKET'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_DEV_BUNDLE_ID'),
        );

      case Flavor.staging:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_IOS_STAGING_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_IOS_STAGING_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_IOS_STAGING_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_IOS_STAGING_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_IOS_STAGING_STORAGE_BUCKET'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_STAGING_BUNDLE_ID'),
        );

      case Flavor.pro:
        return const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_IOS_PRO_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_IOS_PRO_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_IOS_PRO_MESSAGING_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_IOS_PRO_PROJECT_ID'),
          storageBucket: String.fromEnvironment('FIREBASE_IOS_PRO_STORAGE_BUCKET'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_PRO_BUNDLE_ID'),
        );
    }
  }
}
