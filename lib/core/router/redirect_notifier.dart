import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// [Listenable] that triggers GoRouter redirect re-evaluation.
///
/// Notifies on:
/// - Firebase auth state changes (sign-in/sign-out) via [authStateChanges]
/// - Explicit [triggerRouterRefresh] calls from the Dio interceptor after
///   a 403/email_not_verified response, so the router immediately sends
///   unverified users to the verification page.
final routerRefreshNotifier = _AuthRedirectNotifier();

class _AuthRedirectNotifier extends ChangeNotifier {
  _AuthRedirectNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  /// Public trigger so [triggerRouterRefresh] can call notifyListeners
  /// without violating [ChangeNotifier]'s protected-member convention.
  void requestRefresh() => notifyListeners();
}

/// Called by [AuthNotifier.setEmailVerificationRequired] after the Dio
/// interceptor catches a 403/email_not_verified response.
void triggerRouterRefresh() => routerRefreshNotifier.requestRefresh();
