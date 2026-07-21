import 'package:flutter/material.dart';

import 'flavor_config.dart';

class FlavorBanner extends StatelessWidget {
  final Widget child;

  const FlavorBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final flavor = FlavorConfig.instance.flavor;

    if (flavor == Flavor.pro) {
      return child; // no banner in PRO
    }

    // ponytail: --dart-define=HIDE_FLAVOR_BANNER=true hides the banner so
    // screen recordings for demos don't show the dev/staging label.
    const bool hideBanner = bool.fromEnvironment('HIDE_FLAVOR_BANNER');
    if (hideBanner) return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: flavor.name.toUpperCase(),
        location: BannerLocation.bottomEnd,
        color: flavor == Flavor.dev ? Colors.red : Colors.orange,
        child: child,
      ),
    );
  }
}
