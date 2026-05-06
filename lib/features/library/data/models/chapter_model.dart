/// Data Transfer Object (DTO) for a chapter as returned by the backend API.
///
/// Note that [number] is kept as a [String] here (e.g., `"12.5"`) and parsed to
/// a [double] by [ChapterModelMapper.toEntity]. Use that mapper to convert to [Chapter].
class ChapterModel {
  final String id;

  /// Chapter number as a raw string from the API (e.g., `"1"`, `"12.5"`).
  /// `null` for extra chapters or oneshots.
  final String? number;
  final String? title;
  final DateTime? date;
  final bool readable;
  final bool external;
  final String? externalUrl;

  ChapterModel({
    required this.id,
    this.number,
    this.title,
    this.date,
    required this.readable,
    required this.external,
    this.externalUrl,
  });

  /// Deserializes a [ChapterModel] from the JSON map returned by the API.
  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as String,
      number: json['number']?.toString(),
      title: json['title'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      readable: json['readable'] as bool,
      external: json['external'] as bool,
      externalUrl: json['externalUrl'] as String?,
    );
  }

  /// Serializes this model back into JSON for local caching.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'number': number,
      'title': title,
      'date': date?.toIso8601String(),
      'readable': readable,
      'external': external,
      'externalUrl': externalUrl,
    };
  }
}
