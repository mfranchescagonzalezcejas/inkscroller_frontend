import 'dart:io';

/// Forces all DNS lookups to resolve IPv4 addresses only.
///
/// Some development setups (especially on macOS/Linux with dual-stack networks)
/// can cause Dio/http to connect via IPv6, which may fail when the local backend
/// only listens on IPv4. Installing this override via [HttpOverrides.global] at
/// startup ensures consistent connectivity across all platforms.
class IPv4HttpOverrides extends HttpOverrides {
  /// Overrides the default DNS lookup to restrict results to [InternetAddressType.IPv4].
  Future<List<InternetAddress>> lookup(
      String host, {
        InternetAddressType type = InternetAddressType.any,
      }) {
    // 🔥 FORZAR IPv4
    return InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    );
  }
}
