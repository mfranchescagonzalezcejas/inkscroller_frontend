import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import 'user_profile_notifier.dart';
import 'user_profile_state.dart';

/// Riverpod bridge for the user profile module.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>(
      (ref) => UserProfileNotifier(getUserProfile: sl()),
    );
