import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/mappers/manga_mapper.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';

void main() {
  test('MangaModelMapper.toEntity maps all fields', () {
    const model = MangaModel(
      id: 'manga-1',
      title: 'Monster',
      description: 'Thriller',
      coverUrl: 'https://cover',
      demographic: 'seinen',
      status: 'completed',
      genres: <String>['Mystery'],
      score: 8.9,
      rank: 42,
      authors: <String>['Naoki Urasawa'],
    );

    final entity = model.toEntity();

    expect(entity.id, model.id);
    expect(entity.title, model.title);
    expect(entity.description, model.description);
    expect(entity.coverUrl, model.coverUrl);
    expect(entity.demographic, model.demographic);
    expect(entity.status, model.status);
    expect(entity.genres, model.genres);
    expect(entity.score, model.score);
    expect(entity.rank, model.rank);
    expect(entity.authors, model.authors);
  });
}
