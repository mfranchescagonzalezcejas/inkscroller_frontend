import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/user_library_entry_model.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';

void main() {
  group('UserLibraryEntryModel', () {
    final baseJson = <String, dynamic>{
      'mangaId': 'manga-1',
      'title': 'Berserk',
      'description': 'Dark fantasy',
      'coverUrl': 'https://image',
      'demographic': 'seinen',
      'publicationStatus': 'ongoing',
      'genres': <String>['Action', 'Fantasy'],
      'score': 9.4,
      'rank': 5,
      'type': 'manga',
      'year': 1989,
      'authors': <String>['Kentaro Miura'],
      'readChaptersCount': 50,
      'totalChaptersCount': 380,
      'malId': 2,
      'isInLibrary': true,
      'userLibraryStatus': 'reading',
      'updatedAtMillis': 1700000000000,
    };

    test('parses a full JSON payload with malId', () {
      final model = UserLibraryEntryModel.fromJson(baseJson);

      expect(model.mangaId, 'manga-1');
      expect(model.title, 'Berserk');
      expect(model.description, 'Dark fantasy');
      expect(model.malId, 2);
      expect(model.score, 9.4);
      expect(model.totalChaptersCount, 380);
      expect(model.genres, containsAll(<String>['Action', 'Fantasy']));
    });

    test('fromJson handles null malId', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('malId');
      final model = UserLibraryEntryModel.fromJson(json);

      expect(model.malId, isNull);
    });

    test('round-trip fromEntity → toEntity preserves malId', () {
      final manga = Manga(
        id: 'manga-1',
        title: 'Berserk',
        description: 'Dark fantasy',
        coverUrl: 'https://image',
        demographic: 'seinen',
        status: 'ongoing',
        genres: <String>['Action', 'Fantasy'],
        score: 9.4,
        rank: 5,
        type: 'manga',
        year: 1989,
        authors: <String>['Kentaro Miura'],
        readChaptersCount: 50,
        totalChaptersCount: 380,
        malId: 2,
      );
      final entry = UserLibraryEntry(
        manga: manga,
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final model = UserLibraryEntryModel.fromEntity(entry);
      final restored = model.toEntity();

      expect(restored.manga.malId, 2);
      expect(restored.manga.title, 'Berserk');
      expect(restored.manga.totalChaptersCount, 380);
      expect(restored.isInLibrary, true);
    });

    test('round-trip fromJson → toJson preserves malId', () {
      final model = UserLibraryEntryModel.fromJson(baseJson);
      final json = model.toJson();

      expect(json['malId'], 2);
      expect(json['mangaId'], 'manga-1');
      expect(json['totalChaptersCount'], 380);
    });

    test('toJson omits null malId', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('malId');
      final model = UserLibraryEntryModel.fromJson(json);
      final output = model.toJson();

      expect(output.containsKey('malId'), true);
      expect(output['malId'], isNull);
    });
  });
}
