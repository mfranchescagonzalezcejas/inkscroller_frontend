import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/demographic_resolution.dart';
import 'preferences_provider.dart';

/// Watches auth and preferences to resolve the effective demographic filter.
final demographicResolutionProvider =
    Provider<DemographicResolution>((ref) {
  final authState = ref.watch(authProvider);
  final preferencesState = ref.watch(preferencesProvider);

  return DemographicResolution.resolve(
    isGuest: authState.user == null,
    stored: preferencesState.preferences?.demographicFilter,
  );
});
