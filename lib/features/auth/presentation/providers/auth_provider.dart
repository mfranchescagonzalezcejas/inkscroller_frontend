import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_auth_state.dart';
import '../../domain/usecases/reload_user.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../../profile/domain/usecases/get_user_profile.dart';
import '../../../profile/domain/usecases/update_user_profile.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Riverpod provider that exposes [AuthNotifier] to the widget tree.
///
/// Resolves use cases from get_it following the project convention that
/// providers bridge get_it singletons to the Riverpod layer.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signIn: sl<SignIn>(),
    signUp: sl<SignUp>(),
    signOut: sl<SignOut>(),
    getAuthState: sl<GetAuthState>(),
    sendEmailVerification: sl<SendEmailVerification>(),
    reloadUser: sl<ReloadUser>(),
    getUserProfile: sl<GetUserProfile>(),
    updateUserProfile: sl<UpdateUserProfile>(),
    profileMetadataFailureReporter: ({required flow, required reason}) {
      return FirebaseAnalytics.instance.logEvent(
        name: 'profile_metadata_failure',
        parameters: <String, Object>{'flow': flow, 'reason': reason},
      );
    },
  );
});
