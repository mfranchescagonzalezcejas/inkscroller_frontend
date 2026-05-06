/// Core domain entity representing a manga title.
///
/// This is the pure business object used throughout the domain and presentation
/// layers. It has no dependency on any data-layer concern (JSON, API models, etc.).
class Manga {
  final String id;
  final String title;

  /// Optional plot synopsis or back-cover description.
  final String? description;

  /// Full URL of the manga's cover image, or `null` if unavailable.
  final String? coverUrl;

  /// Target demographic (e.g., `"shounen"`, `"shoujo"`, `"seinen"`, `"josei"`), if known.
  final String? demographic;

  /// Publication status (e.g., `"ongoing"`, `"completed"`, `"hiatus"`, `"cancelled"`), if known.
  final String? status;

  /// Genre/theme tags (e.g., `["Action", "Fantasy"]`). Empty list when not available.
  final List<String> genres;

  /// Community rating score, or `null` if not yet rated.
  final double? score;

  /// Popularity rank position, or `null` when the source does not provide it.
  final int? rank;

  /// Manga type: "manga", "manhwa", "manhua", or `null` if unknown.
  /// Source: MangaDex returns this in the "originalLanguage" field.
  ///
  /// Pending backend integration to populate this field.
  ///
  /// Currently uses placeholder.
  /// - MangaDex: "originalLanguage" field maps to type
  /// - "ja" = Manga, "ko" = Manhwa, "zh" = Manhua
  final String? type;

  /// Year of first publication, if known.
  final int? year;

  /// List of authors/artist names.
  final List<String> authors;

  /// Per-user reading progress counters when provided by the backend.
  final int? readChaptersCount;
  final int? totalChaptersCount;

  Manga({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.demographic,
    this.status,
    this.genres = const [],
    this.score,
    this.rank,
    this.type,
    this.year,
    this.authors = const [],
    this.readChaptersCount,
    this.totalChaptersCount,
  });

  /// Returns display name for the demographic.
  /// e.g., "shounen" -> "Shounen", "josei" -> "Josei"
  String? get demographicDisplay {
    if (demographic == null) return null;
    return demographic![0].toUpperCase() + demographic!.substring(1);
  }

  /// Returns display name for the type.
  /// e.g., "manhwa" -> "Manhwa", "manhua" -> "Manhua"
  String? get typeDisplay {
    if (type == null) return null;
    return type![0].toUpperCase() + type!.substring(1);
  }
}
