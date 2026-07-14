import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import 'manga_capabilities_provider.dart';
import '../../domain/entities/demographic_resolution.dart';
import 'preferences_provider.dart';

/// Watches auth and preferences to resolve the effective demographic filter.
final demographicResolutionProvider = Provider<DemographicResolution>((ref) {
  final authState = ref.watch(authProvider);
  final preferencesState = ref.watch(preferencesProvider);
  final profileState = ref.watch(userProfileProvider);
  final capabilities = ref.watch(mangaCapabilitiesProvider).value;

  return DemographicResolution.resolve(
    isGuest: authState.user == null,
    isAdult: _isAdult(profileState.profile?.birthDate),
    supportsUnspecified: capabilities?.supportsUnspecified ?? false,
    stored: preferencesState.preferences?.demographicFilter,
  );
});

bool _isAdult(DateTime? birthDate) {
  if (birthDate == null) return false;
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (DateTime(now.year, birthDate.month, birthDate.day).isAfter(now)) age--;
  return age >= 18;
}
