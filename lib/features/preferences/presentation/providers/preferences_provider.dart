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
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>(
      (ref) {
        final notifier = PreferencesNotifier(
          getPreferences: sl(),
          updatePreferences: sl(),
        );

        // Listen to auth state changes and reset preferences on logout.
        ref.listen<AuthState>(authProvider, (_, authState) {
          if (authState.user == null) {
            notifier.clearPreferences();
          }
        });

        return notifier;
      },
    );
