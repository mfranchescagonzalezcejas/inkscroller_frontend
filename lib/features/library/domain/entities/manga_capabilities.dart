/// Advertised backend support for demographic filtering contracts.
class MangaCapabilities {
  /// Whether the backend supports the exact null-demographic cursor contract.
  final bool supportsUnspecified;

  const MangaCapabilities({required this.supportsUnspecified});

  /// Parses the capability response defensively; malformed data is unavailable.
  factory MangaCapabilities.fromJson(Map<String, Object?> json) {
    final filter = json['demographic_filter'];
    if (filter is! Map<String, Object?>) {
      return const MangaCapabilities(supportsUnspecified: false);
    }
    return MangaCapabilities(
      supportsUnspecified:
          filter['contract_version'] == 1 &&
          filter['null_union'] == true &&
          filter['pagination'] == 'cursor-v1',
    );
  }
}
