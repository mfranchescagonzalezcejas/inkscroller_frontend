import '../../../library/domain/entities/manga_tags.dart';

/// Guest-allowed demographic values — only those MangaDex supports (shounen,
/// shoujo). `kodomo` was removed from the enum — MangaDex does not support it.
const List<MangaDemographic> _guestAllowed = [
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

  /// Whether a demographic preference can be saved.
  static bool isValidSelection(List<MangaDemographic> selection) =>
      selection.isNotEmpty;

  /// Returns a dialog selection that contains only currently available values.
  static List<MangaDemographic> selectionForDialog({
    required List<MangaDemographic>? stored,
    required DemographicResolution resolution,
  }) {
    if (stored != null && stored.every(resolution.allowedOptions.contains)) {
      return stored;
    }
    return resolution.effectiveFilter;
  }

  /// Creates a resolution from raw data — deterministic, testable.
  // ignore: prefer_constructors_over_static_methods
  static DemographicResolution resolve({
    required bool isGuest,
    bool isAdult = false,
    bool supportsUnspecified = false,
    List<MangaDemographic>? stored,
  }) {
    final allowed = isGuest
        ? _guestAllowed
        : MangaDemographic.values
              .where(
                (demographic) =>
                    demographic != MangaDemographic.unspecified ||
                    (isAdult && supportsUnspecified),
              )
              .toList();

    // Filter stored values to only those allowed for this user.
    final filtered = stored != null
        ? stored.where(allowed.contains).toSet().toList()
        : <MangaDemographic>[];
    filtered.sort((left, right) => left.index.compareTo(right.index));

    // If the stored selection contained `unspecified` but the user is not
    // allowed to request it (minor, guest, or unsupported capability), fall
    // back to the default filter instead of silently dropping the sentinel.
    final hadUnspecified =
        stored?.contains(MangaDemographic.unspecified) ?? false;
    final allowsUnspecified = allowed.contains(MangaDemographic.unspecified);
    final effective =
        (filtered.isEmpty || (hadUnspecified && !allowsUnspecified))
            ? _defaultFilter
            : filtered;

    return DemographicResolution(
      effectiveFilter: effective,
      allowedOptions: allowed,
    );
  }
}
