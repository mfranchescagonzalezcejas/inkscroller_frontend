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

  /// Creates a resolution from raw data — deterministic, testable.
  // ignore: prefer_constructors_over_static_methods
  static ContentRatingResolution resolve({
    required bool isGuest,
    DateTime? birthDate,
    ContentRating? stored,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final age = birthDate != null
        ? today.year -
              birthDate.year -
              (today.isBefore(
                    DateTime(today.year, birthDate.month, birthDate.day),
                  )
                  ? 1
                  : 0)
        : null;

    final allowed = ContentRating.valuesForAge(age, isGuest: isGuest);
    final effective =
        ContentRating.effectiveForAge(age, isGuest: isGuest, stored: stored);

    return ContentRatingResolution(
      effectiveRating: effective,
      allowedOptions: allowed,
      isEditable: allowed.length > 1,
    );
  }
}

/// Watches auth, profile, and preferences to resolve the effective content rating.
final contentRatingResolutionProvider =
    Provider<ContentRatingResolution>((ref) {
  final authState = ref.watch(authProvider);
  final profileState = ref.watch(userProfileProvider);
  final preferencesState = ref.watch(preferencesProvider);

  return ContentRatingResolution.resolve(
    isGuest: authState.user == null,
    birthDate: profileState.profile?.birthDate,
    stored: preferencesState.preferences?.contentRatingFilter,
  );
});
