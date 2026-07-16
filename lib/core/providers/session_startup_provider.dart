import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/preferences/presentation/providers/preferences_provider.dart';
import '../../features/profile/presentation/providers/user_profile_provider.dart';

/// Watches auth state and triggers profile + preference loading when a
/// session is restored (cold start) or freshly created (login/register).
///
/// Without this provider, [contentRatingResolutionProvider] and any other
/// provider that depends on profile or preferences would see null values
/// until the user happens to visit the Profile page, which only loads
/// them on demand.
///
/// This provider is watched from [MyApp] so it activates immediately on
/// app start — no page-level boilerplate needed.
final sessionStartupProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final justSignedIn = previous?.user == null && next.user != null;
    if (!justSignedIn) return;
    // Skip data loading for unverified users — the backend returns
    // 403/email_not_verified on all protected endpoints.
    if (!next.user!.isEmailVerified) return;

    // ponytail: fire-and-forget loads — failures are handled internally
    // by each notifier and surfaced to the UI via their error states.
    ref.read(userProfileProvider.notifier).loadProfile();
    ref.read(preferencesProvider.notifier).loadPreferences();
  });
});
