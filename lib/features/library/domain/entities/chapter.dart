/// Core domain entity representing a single manga chapter.
///
/// A chapter can be either readable in-app ([readable] == `true`) or available
/// only through an external link ([external] == `true`, [externalUrl] set).
/// Some chapters (e.g., extras or oneshots) may have no [number].
class Chapter {
  final String id;

  /// Chapter number (e.g., `1.0`, `12.5`). `null` for extras or oneshots.
  final double? number;

  /// Optional chapter title provided by the scanlation group.
  final String? title;

  /// Publication or upload date, if available.
  final DateTime? date;

  /// Whether the chapter can be read inside the app reader.
  final bool readable;

  /// Whether the chapter is only accessible via an external site.
  final bool external;

  /// URL to the external reader when [external] is `true`.
  final String? externalUrl;

  Chapter({
    required this.id,
    this.number,
    this.title,
    this.date,
    required this.readable,
    required this.external,
    this.externalUrl,
  });
}
