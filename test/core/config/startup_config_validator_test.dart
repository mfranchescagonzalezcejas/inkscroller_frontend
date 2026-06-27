import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/startup_config_validator.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';

void main() {
  group('StartupConfigValidator', () {
    test(
      'allows dev builds to use local API URLs and empty Firebase values',
      () {
        expect(
          () => StartupConfigValidator.validate(
            flavor: Flavor.dev,
            apiBaseUrl: 'http://127.0.0.1:8000',
            firebaseOptions: _firebaseOptions(apiKey: ''),
            platform: TargetPlatform.android,
          ),
          returnsNormally,
        );
      },
    );

    test('allows staging with HTTPS API URL and complete Firebase values', () {
      for (final apiBaseUrl in <String>[
        'https://api.stg.inkscroller.devdigi.dev',
        'https://api.inkscroller.devdigi.dev',
        'https://api.example.com',
      ]) {
        expect(
          () => StartupConfigValidator.validate(
            flavor: Flavor.staging,
            apiBaseUrl: apiBaseUrl,
            firebaseOptions: _firebaseOptions(),
            platform: TargetPlatform.android,
          ),
          returnsNormally,
          reason: '$apiBaseUrl must be accepted as a public HTTPS domain',
        );
      }
    });

    test('rejects non-HTTPS API URLs for production', () {
      expect(
        () => StartupConfigValidator.validate(
          flavor: Flavor.pro,
          apiBaseUrl: 'http://api.inkscroller.devdigi.dev',
          firebaseOptions: _firebaseOptions(),
          platform: TargetPlatform.android,
        ),
        throwsA(isA<StartupConfigException>()),
      );
    });

    test('rejects local and private API URLs for staging', () {
      for (final localUrl in <String>[
        'https://localhost:8000',
        'https://localhost.',
        'https://api.localhost',
        'https://api.local.',
        'https://127.0.0.1:8000',
        'https://127.0.0.1.',
        'https://0177.0.0.1',
        'https://0x7f.0.0.1',
        'https://127.1',
        'https://2130706433',
        'https://10.0.2.2:8000',
        'https://10.1.2.3',
        'https://172.16.0.10',
        'https://192.168.1.10',
        'https://169.254.1.1',
        'https://8.8.8.8',
        'https://[::1]',
        'https://[0:0:0:0:0:0:0:1]',
        'https://[::]',
        'https://[fd00::1]',
        'https://[fe80::1]',
        'https://[fe80::1%25eth0]',
        'https://[fe80::1%eth0]',
        'https://[::ffff:192.168.1.10]',
        'https://[2001:db8::1]',
        'https://[2001:0:1234::1]',
        'https://[2002:c0a8:010a::1]',
        'https://[2606:4700:4700::1111]',
      ]) {
        expect(
          () => StartupConfigValidator.validate(
            flavor: Flavor.staging,
            apiBaseUrl: localUrl,
            firebaseOptions: _firebaseOptions(),
            platform: TargetPlatform.android,
          ),
          throwsA(isA<StartupConfigException>()),
          reason: '$localUrl must not be accepted for staging',
        );
      }
    });

    test('rejects missing Firebase dart-defines for non-dev builds', () {
      expect(
        () => StartupConfigValidator.validate(
          flavor: Flavor.pro,
          apiBaseUrl: 'https://api.inkscroller.devdigi.dev',
          firebaseOptions: _firebaseOptions(projectId: ''),
          platform: TargetPlatform.android,
        ),
        throwsA(isA<StartupConfigException>()),
      );
    });

    test('rejects missing iOS bundle ID for non-dev iOS builds', () {
      expect(
        () => StartupConfigValidator.validate(
          flavor: Flavor.staging,
          apiBaseUrl: 'https://api.stg.inkscroller.devdigi.dev',
          firebaseOptions: _firebaseOptions(iosBundleId: ''),
          platform: TargetPlatform.iOS,
        ),
        throwsA(isA<StartupConfigException>()),
      );
    });

    test('rejects placeholder Firebase values for non-dev builds', () {
      expect(
        () => StartupConfigValidator.validate(
          flavor: Flavor.staging,
          apiBaseUrl: 'https://api.stg.inkscroller.devdigi.dev',
          firebaseOptions: _firebaseOptions(apiKey: 'TODO_FIREBASE_KEY'),
          platform: TargetPlatform.android,
        ),
        throwsA(isA<StartupConfigException>()),
      );
    });
  });
}

FirebaseOptions _firebaseOptions({
  String apiKey = 'firebase-api-key',
  String appId = '1:123456789:android:abcdef',
  String messagingSenderId = '123456789',
  String projectId = 'inkscroller-test',
  String storageBucket = 'inkscroller-test.firebasestorage.app',
  String iosBundleId = 'com.inkscroller.test',
}) {
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: iosBundleId,
  );
}
