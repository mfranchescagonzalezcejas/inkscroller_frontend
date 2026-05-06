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
