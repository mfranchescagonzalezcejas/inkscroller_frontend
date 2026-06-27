// Issue #1 — Audit: Android Package Identity
//
// Verifies the deterministic package IDs that map Flutter flavors to the
// Google Play package identity. This protects release automation from silently
// drifting away from the already-created Play Console application IDs.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _basePackageId = 'dev.devdigi.inkscroller';
const String _devPackageId = 'dev.devdigi.inkscroller.dev';
const String _stagingPackageId = 'dev.devdigi.inkscroller.stg';
const String _mainActivityPackage = 'package dev.devdigi.inkscroller';

void main() {
  group('Issue #1: Android package identity', () {
    test('Gradle declares deterministic package IDs for every flavor', () {
      final gradleFile = File('android/app/build.gradle.kts');

      expect(gradleFile.existsSync(), isTrue);

      final gradle = gradleFile.readAsStringSync();
      final defaultConfigBlock = _blockFor(gradle, 'defaultConfig');
      final devFlavorBlock = _requiredFlavorBlockFor(gradle, 'dev');
      final stagingFlavorBlock = _requiredFlavorBlockFor(gradle, 'staging');
      final proFlavorBlock = _requiredFlavorBlockFor(gradle, 'pro');

      expect(_assignedString(gradle, 'namespace'), _basePackageId);
      expect(_assignedString(defaultConfigBlock, 'applicationId'), _basePackageId);

      final devSuffix = _assignedString(devFlavorBlock, 'applicationIdSuffix');
      final stagingSuffix =
          _assignedString(stagingFlavorBlock, 'applicationIdSuffix');
      final proSuffix = _assignedString(proFlavorBlock, 'applicationIdSuffix');

      expect(devSuffix, '.dev');
      expect(stagingSuffix, '.stg');
      expect(proSuffix, isNull);

      expect(_effectivePackageId(_basePackageId, devSuffix), _devPackageId);
      expect(_effectivePackageId(_basePackageId, stagingSuffix), _stagingPackageId);
      expect(_effectivePackageId(_basePackageId, proSuffix), _basePackageId);
    });

    test('MainActivity exists only at the approved package path', () {
      final approvedMainActivity = File(
        'android/app/src/main/kotlin/dev/devdigi/inkscroller/MainActivity.kt',
      );
      final oldMainActivity = File(
        'android/app/src/main/kotlin/com/example/inkscroller_flutter/MainActivity.kt',
      );

      expect(approvedMainActivity.existsSync(), isTrue);
      expect(
        approvedMainActivity.readAsStringSync(),
        contains(_mainActivityPackage),
      );
      expect(oldMainActivity.existsSync(), isFalse);
    });
  });
}

String _blockFor(String source, String blockName) {
  final match = RegExp('$blockName\\s*\\{').firstMatch(source);

  if (match == null) {
    return '';
  }

  return _bracedBlockFrom(source, match.end - 1);
}

String _requiredFlavorBlockFor(String source, String flavorName) {
  final flavorBlock = _flavorBlockFor(source, flavorName);

  if (flavorBlock == null) {
    fail('Missing required Android flavor: $flavorName');
  }

  return flavorBlock;
}

String? _flavorBlockFor(String source, String flavorName) {
  final match = RegExp(
    'create\\("${RegExp.escape(flavorName)}"\\)\\s*\\{',
  ).firstMatch(source);

  if (match == null) {
    return null;
  }

  return _bracedBlockFrom(source, match.end - 1);
}

String _bracedBlockFrom(String source, int openingBraceIndex) {
  var depth = 0;

  for (var index = openingBraceIndex; index < source.length; index++) {
    final character = source[index];

    if (character == '{') {
      depth++;
    }

    if (character == '}') {
      depth--;
    }

    if (depth == 0) {
      return source.substring(openingBraceIndex, index + 1);
    }
  }

  return '';
}

String? _assignedString(String source, String propertyName) {
  final match = RegExp(
    '${RegExp.escape(propertyName)}\\s*=\\s*"([^"]+)"',
  ).firstMatch(source);

  return match?.group(1);
}

String _effectivePackageId(String basePackageId, String? suffix) {
  return suffix == null ? basePackageId : '$basePackageId$suffix';
}
