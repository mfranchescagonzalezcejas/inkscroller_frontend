import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Navigator observer that logs every screen transition to Firebase Analytics.
///
/// Can be attached to the app router/navigation layer so route pushes are
/// automatically recorded without manual instrumentation.
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FirebaseAnalytics.instance.logScreenView(
      screenName: route.settings.name,
    );
  }
}
