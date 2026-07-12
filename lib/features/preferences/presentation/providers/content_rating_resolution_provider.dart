import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../domain/entities/content_rating.dart';
import 'preferences_provider.dart';

/// Resolved content rating state for the current user.
class ContentRatingResolution {
  /// The effective content rating after age and guest constraints.
  final ContentRating effectiveRating;

  /// All content ratings the user is allowed to select.
  final List<ContentRating> allowedOptions;

  /// Whether the user can change the content rating (more than one option).
  final bool isEditable;

  const ContentRatingResolution({
    required this.effectiveRating,
    required this.allowedOptions,
    required this.isEditable,
  });
}

/// Watches auth, profile, and preferences to resolve the effective content rating.
final contentRatingResolutionProvider =
    Provider<ContentRatingResolution>((ref) {
  final authState = ref.watch(authProvider);
  final profileState = ref.watch(userProfileProvider);
  final preferencesState = ref.watch(preferencesProvider);

  final isGuest = authState.user == null;
  final birthDate = profileState.profile?.birthDate;
  final age = birthDate != null
      ? DateTime.now().year -
            birthDate.year -
            (DateTime.now().isBefore(
                  DateTime(birthDate.year, birthDate.month, birthDate.day),
                )
                ? 1
                : 0)
      : null;
  final stored = preferencesState.preferences?.contentRatingFilter;

  final allowed = ContentRating.valuesForAge(age, isGuest: isGuest);
  final effective = ContentRating.effectiveForAge(age, isGuest: isGuest, stored: stored);

  return ContentRatingResolution(
    effectiveRating: effective,
    allowedOptions: allowed,
    isEditable: allowed.length > 1,
  );
});
