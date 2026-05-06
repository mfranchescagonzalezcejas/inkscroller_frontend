import '../../domain/entities/chapter.dart';
import '../models/chapter_model.dart';

/// Extension that adds a [toEntity] conversion method to [ChapterModel].
///
/// Parses the raw string [ChapterModel.number] to a [double] during mapping.
extension ChapterModelMapper on ChapterModel {
  /// Converts this DTO into the corresponding [Chapter] domain entity.
  Chapter toEntity() {
    return Chapter(
      id: id,
      number: number != null ? double.tryParse(number!) : null,
      title: title,
      date: date,
      readable: readable,
      external: external,
      externalUrl: externalUrl,
    );
  }
}
