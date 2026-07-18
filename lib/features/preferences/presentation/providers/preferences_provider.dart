import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import 'preferences_notifier.dart';
import 'preferences_state.dart';

/// Riverpod bridge for the user preferences module.
///
/// Automatically clears cached preferences when the user signs out so that
/// guest sessions do not inherit stale preferences from a previous user.
/// Syncs guest preferences to the backend when the user verifies their email.
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>(
      (ref) {
        final notifier = PreferencesNotifier(
          getPreferences: sl(),
          updatePreferences: sl(),
        );

        // Listen to auth state changes.
        ref.listen<AuthState>(authProvider, (previous, authState) {
          // Clear preferences on logout.
          if (authState.user == null) {
            notifier.clearPreferences();
            return;
          }

          // Sync guest preferences when transitioning from guest → verified.
          final wasGuest = previous?.user == null;
          final isVerified = authState.user != null &&
              authState.needsEmailVerification == false;
          if (wasGuest && isVerified) {
            notifier.syncGuestPreferencesToRemote();
          }
        });

        return notifier;
      },
    );
