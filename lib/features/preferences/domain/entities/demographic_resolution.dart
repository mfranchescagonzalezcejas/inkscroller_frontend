import '../../../library/domain/entities/manga_tags.dart';

/// Guest-allowed demographic values — kodomo, shounen, shoujo.
const List<MangaDemographic> _guestAllowed = [
  MangaDemographic.kodomo,
  MangaDemographic.shounen,
  MangaDemographic.shoujo,
];

/// Default effective filter when no preference is stored.
const List<MangaDemographic> _defaultFilter = [
  MangaDemographic.shounen,
  MangaDemographic.shoujo,
];

/// Resolved demographic filter state for the current user.
class DemographicResolution {
  /// The effective demographic list after guest and default constraints.
  final List<MangaDemographic> effectiveFilter;

  /// All demographic values the user is allowed to select.
  final List<MangaDemographic> allowedOptions;

  const DemographicResolution({
    required this.effectiveFilter,
    required this.allowedOptions,
  });

  /// Creates a resolution from raw data — deterministic, testable.
  // ignore: prefer_constructors_over_static_methods
  static DemographicResolution resolve({
    required bool isGuest,
    List<MangaDemographic>? stored,
  }) {
    final allowed = isGuest ? _guestAllowed : MangaDemographic.values;

    // Filter stored values to only those allowed for this user.
    final filtered = stored != null
        ? stored.where((d) => allowed.contains(d)).toList()
        : <MangaDemographic>[];

    // Fall back to default when the filtered list is empty.
    final effective = filtered.isNotEmpty ? filtered : _defaultFilter;

    return DemographicResolution(
      effectiveFilter: effective,
      allowedOptions: allowed,
    );
  }
}
