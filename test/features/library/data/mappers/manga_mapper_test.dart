import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/mappers/manga_mapper.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';

void main() {
  test('MangaModelMapper.toEntity maps all fields including malId', () {
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
      malId: 1333,
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
    expect(entity.malId, 1333);
  });

  test('MangaModelMapper.toEntity maps null malId', () {
    const model = MangaModel(
      id: 'manga-2',
      title: 'Berserk',
    );

    final entity = model.toEntity();

    expect(entity.malId, isNull);
  });

  test('MangaModel.fromJson parses malId', () {
    final json = <String, dynamic>{
      'id': 'manga-3',
      'title': 'Vagabond',
      'malId': 512,
    };

    // malId is now supported in MangaModel.fromJson (added in feat/jikan-reading-progress)
    final model = MangaModel.fromJson(json);

    expect(model.malId, 512);
  });

  test('MangaModel.fromJson defaults malId to null when absent', () {
    final json = <String, dynamic>{
      'id': 'manga-4',
      'title': 'Vinland',
    };

    final model = MangaModel.fromJson(json);

    expect(model.malId, isNull);
  });

  test('MangaModel.toJson includes malId', () {
    const model = MangaModel(
      id: 'manga-5',
      title: 'OPM',
      malId: 21087,
    );

    final json = model.toJson();

    expect(json['malId'], 21087);
  });
}
