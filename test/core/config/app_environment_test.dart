import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/api_config.dart';
import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';

void main() {
  const oldRailwayUrls = <String>{
    'https://inkscrollerbackend-dev.up.railway.app',
    'https://inkscrollerbackend-stg.up.railway.app',
    'https://inkscrollerbackend-pro.up.railway.app',
  };

  const expectedCloudEntrypoints = <String, String>{
    '.run/Flutter Dev Cloud.run.xml': 'https://api.dev.inkscroller.devdigi.dev',
    '.run/Flutter Staging Cloud.run.xml':
        'https://api.stg.inkscroller.devdigi.dev',
    '.run/Flutter Pro Cloud.run.xml': 'https://api.inkscroller.devdigi.dev',
    'scripts/run_dev_cloud.sh': 'https://api.dev.inkscroller.devdigi.dev',
    'scripts/run_staging_cloud.sh': 'https://api.stg.inkscroller.devdigi.dev',
    'scripts/run_pro_cloud.sh': 'https://api.inkscroller.devdigi.dev',
  };

  group('AppEnvironment cloud API defaults', () {
    test('uses the custom backend domains for every flavor', () {
      expect(
        AppEnvironment.devApiBaseUrl,
        'https://api.dev.inkscroller.devdigi.dev',
      );
      expect(
        AppEnvironment.stagingApiBaseUrl,
        'https://api.stg.inkscroller.devdigi.dev',
      );
      expect(
        AppEnvironment.proApiBaseUrl,
        'https://api.inkscroller.devdigi.dev',
      );
    });

    test('does not regress cloud defaults to Railway or localhost URLs', () {
      final cloudDefaults = <String>{
        AppEnvironment.devApiBaseUrl,
        AppEnvironment.stagingApiBaseUrl,
        AppEnvironment.proApiBaseUrl,
      };

      expect(cloudDefaults.intersection(oldRailwayUrls), isEmpty);
      expect(cloudDefaults, isNot(contains(AppEnvironment.localBaseUrl)));
      expect(
        cloudDefaults,
        isNot(contains(AppEnvironment.androidEmulatorBaseUrl)),
      );
      expect(cloudDefaults, isNot(contains('http://localhost:8000')));
    });

    test('keeps local development URLs only in fallback candidates', () {
      expect(
        AppEnvironment.apiBaseUrlCandidates,
        contains(AppEnvironment.localBaseUrl),
      );
      expect(
        AppEnvironment.apiBaseUrlCandidates,
        contains('http://localhost:8000'),
      );
      expect(
        AppEnvironment.apiBaseUrlCandidates.where(oldRailwayUrls.contains),
        isEmpty,
      );
    });

    test(
      'ApiConfig uses the active flavor custom domain as first candidate',
      () {
        FlavorConfig(
          flavor: Flavor.pro,
          apiBaseUrl: AppEnvironment.proApiBaseUrl,
          name: 'InkScroller Test',
        );

        expect(ApiConfig.baseUrl, AppEnvironment.proApiBaseUrl);
        expect(ApiConfig.baseUrlCandidates.first, AppEnvironment.proApiBaseUrl);
        expect(
          ApiConfig.baseUrlCandidates.where(oldRailwayUrls.contains),
          isEmpty,
        );
      },
    );

    test('tracked cloud entrypoints do not use stale Railway URLs', () {
      for (final MapEntry<String, String> entry
          in expectedCloudEntrypoints.entries) {
        final file = File(entry.key);

        expect(file.existsSync(), isTrue, reason: '${entry.key} is tracked');

        final content = file.readAsStringSync();
        expect(content, contains(entry.value), reason: entry.key);

        for (final oldRailwayUrl in oldRailwayUrls) {
          expect(
            content,
            isNot(contains(oldRailwayUrl)),
            reason: '${entry.key} must not use stale Railway URL',
          );
        }
      }
    });
  });
}
