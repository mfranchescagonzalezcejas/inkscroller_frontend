import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../flavors/flavor_config.dart';

/// Thrown when a startup configuration is unsafe for the active flavor.
class StartupConfigException extends StateError {
  /// Creates a startup configuration failure with a clear [message].
  StartupConfigException(super.message);
}

/// Validates flavor-specific configuration before Firebase and DI startup.
abstract final class StartupConfigValidator {
  static const List<String> _localHostnameSuffixes = <String>[
    '.localhost',
    '.local',
  ];

  static const List<String> _placeholderMarkers = <String>[
    'placeholder',
    'replace',
    'todo',
    'your_',
    '<',
    '>',
  ];

  /// Validates [apiBaseUrl] and [firebaseOptions] for staging/pro builds.
  ///
  /// Dev builds intentionally remain flexible for local development.
  static void validate({
    required Flavor flavor,
    required String apiBaseUrl,
    required FirebaseOptions firebaseOptions,
    TargetPlatform? platform,
  }) {
    if (flavor == Flavor.dev) {
      return;
    }

    _validateApiBaseUrl(flavor: flavor, apiBaseUrl: apiBaseUrl);
    _validateFirebaseOptions(
      flavor: flavor,
      firebaseOptions: firebaseOptions,
      platform: platform ?? defaultTargetPlatform,
    );
  }

  static void _validateApiBaseUrl({
    required Flavor flavor,
    required String apiBaseUrl,
  }) {
    final normalizedUrl = apiBaseUrl.trim();
    final uri = Uri.tryParse(normalizedUrl);

    if (normalizedUrl.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      throw StartupConfigException(
        '${flavor.name} requires a valid API_BASE_URL dart-define.',
      );
    }

    if (uri.scheme.toLowerCase() != 'https') {
      throw StartupConfigException(
        '${flavor.name} API_BASE_URL must use HTTPS. Current value: $normalizedUrl',
      );
    }

    if (_isLocalOrSpecialUseHost(uri.host)) {
      throw StartupConfigException(
        '${flavor.name} API_BASE_URL must not point to local or private infrastructure. Current value: $normalizedUrl',
      );
    }
  }

  static bool _isLocalOrSpecialUseHost(String host) {
    final normalizedHost = _normalizeHostForClassification(host);
    if (normalizedHost == 'localhost' ||
        _localHostnameSuffixes.any(normalizedHost.endsWith)) {
      return true;
    }

    return _isIpLiteral(normalizedHost) ||
        _isNonCanonicalNumericIpv4Host(normalizedHost) ||
        _isSpecialUseIpv4(normalizedHost) ||
        _isSpecialUseIpv6(normalizedHost);
  }

  static String _normalizeHostForClassification(String host) {
    var normalizedHost = host.toLowerCase();
    while (normalizedHost.endsWith('.')) {
      normalizedHost = normalizedHost.substring(0, normalizedHost.length - 1);
    }

    final zoneStart = normalizedHost.indexOf('%');
    if (zoneStart == -1) {
      return normalizedHost;
    }

    return normalizedHost.substring(0, zoneStart);
  }

  static bool _isIpLiteral(String host) {
    return InternetAddress.tryParse(host) != null;
  }

  static bool _isNonCanonicalNumericIpv4Host(String host) {
    if (host.contains(':')) {
      return false;
    }

    final parts = host.split('.');
    if (parts.any((part) => part.isEmpty)) {
      return false;
    }

    final hasHexPart = parts.any(_isHexIpv4Part);
    if (hasHexPart) {
      return true;
    }

    final allDecimalParts = parts.every(_isDecimalIpv4Part);
    if (!allDecimalParts) {
      return false;
    }

    if (parts.length != 4) {
      return true;
    }

    return parts.any((part) {
      if (part.length > 1 && part.startsWith('0')) {
        return true;
      }

      final value = int.tryParse(part);
      return value == null || value < 0 || value > 255;
    });
  }

  static bool _isDecimalIpv4Part(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  static bool _isHexIpv4Part(String value) {
    return RegExp(r'^0x[0-9a-f]+$').hasMatch(value);
  }

  static bool _isSpecialUseIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) {
        return false;
      }

      octets.add(octet);
    }

    return _isSpecialUseIpv4Octets(octets);
  }

  static bool _isSpecialUseIpv4Octets(List<int> octets) {
    final first = octets[0];
    final second = octets[1];
    final third = octets[2];

    return first == 0 ||
        first == 10 ||
        first == 127 ||
        (first == 100 && second >= 64 && second <= 127) ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 0 && third == 0) ||
        (first == 192 && second == 0 && third == 2) ||
        (first == 192 && second == 168) ||
        (first == 198 && second >= 18 && second <= 19) ||
        (first == 198 && second == 51 && third == 100) ||
        (first == 203 && second == 0 && third == 113) ||
        first >= 224;
  }

  static bool _isSpecialUseIpv6(String host) {
    final address = InternetAddress.tryParse(host);
    if (address == null || address.type != InternetAddressType.IPv6) {
      return false;
    }

    final bytes = address.rawAddress;
    final isUnspecified = bytes.every((byte) => byte == 0);
    final isLoopback =
        bytes.take(15).every((byte) => byte == 0) && bytes[15] == 1;
    final isIpv4Mapped =
        bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 0xff &&
        bytes[11] == 0xff;
    final isIpv4Compatible = bytes.take(12).every((byte) => byte == 0);

    if (isIpv4Mapped || isIpv4Compatible) {
      return _isSpecialUseIpv4Octets(bytes.sublist(12, 16));
    }

    final isUniqueLocal = (bytes[0] & 0xfe) == 0xfc;
    final isLinkLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80;
    final isSiteLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0xc0;
    final isDocumentation =
        bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x0d &&
        bytes[3] == 0xb8;
    final isTeredo =
        bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x00;
    final isBenchmarking =
        bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x02 &&
        bytes[4] == 0x00 &&
        bytes[5] == 0x00;
    final isSixToFour = bytes[0] == 0x20 && bytes[1] == 0x02;
    final isDiscardOnly =
        bytes[0] == 0x01 &&
        bytes[1] == 0x00 &&
        bytes.sublist(2, 8).every((byte) => byte == 0);
    final isMulticast = bytes[0] == 0xff;

    return isUnspecified ||
        isLoopback ||
        isUniqueLocal ||
        isLinkLocal ||
        isSiteLocal ||
        isDocumentation ||
        isTeredo ||
        isBenchmarking ||
        isSixToFour ||
        isDiscardOnly ||
        isMulticast;
  }

  static void _validateFirebaseOptions({
    required Flavor flavor,
    required FirebaseOptions firebaseOptions,
    required TargetPlatform platform,
  }) {
    final requiredValues = <String, String?>{
      'apiKey': firebaseOptions.apiKey,
      'appId': firebaseOptions.appId,
      'messagingSenderId': firebaseOptions.messagingSenderId,
      'projectId': firebaseOptions.projectId,
      'storageBucket': firebaseOptions.storageBucket,
    };

    if (platform == TargetPlatform.iOS) {
      requiredValues['iosBundleId'] = firebaseOptions.iosBundleId;
    }

    final missingKeys = requiredValues.entries
        .where((entry) => _isMissingOrPlaceholder(entry.value))
        .map((entry) => entry.key)
        .toList(growable: false);

    if (missingKeys.isNotEmpty) {
      throw StartupConfigException(
        '${flavor.name} requires Firebase dart-defines for ${platform.name}: ${missingKeys.join(', ')}.',
      );
    }
  }

  static bool _isMissingOrPlaceholder(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return true;
    }

    final lower = normalized.toLowerCase();
    return _placeholderMarkers.any(lower.contains);
  }
}
