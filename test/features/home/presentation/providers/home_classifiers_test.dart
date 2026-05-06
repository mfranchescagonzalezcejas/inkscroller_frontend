import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_classifiers.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Manga _manga({
  required String id,
  String? coverUrl,
  String? description,
  String? demographic,
}) =>
    Manga(
      id: id,
      title: 'Manga $id',
      coverUrl: coverUrl,
      description: description,
      demographic: demographic,
    );

List<Manga> _buildList(int count) =>
    List.generate(count, (i) => _manga(id: '$i'));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeClassifier.takeSafe', () {
    test('returns the list unchanged when it has exactly showMany items', () {
      final list = _buildList(HomeClassifier.showMany);
      expect(HomeClassifier.takeSafe(list), list);
    });

    test('caps the list to showMany when it exceeds the limit', () {
      final list = _buildList(50);
      final result = HomeClassifier.takeSafe(list);
      expect(result.length, HomeClassifier.showMany);
      expect(result.first.id, list.first.id);
    });

    test('returns the list unchanged when shorter than showMany', () {
      final list = _buildList(5);
      expect(HomeClassifier.takeSafe(list), list);
    });
  });

  group('HomeClassifier.featured', () {
    test('returns all items without additional filtering', () {
      final all = [
        _manga(id: '1'),
        _manga(id: '2', coverUrl: 'url', description: 'desc'),
        _manga(id: '3'),
      ];
      expect(HomeClassifier.featured(all), all);
    });

    test('caps to showMany items', () {
      final all = _buildList(50);
      expect(HomeClassifier.featured(all).length, HomeClassifier.showMany);
    });
  });

  group('HomeClassifier.latest', () {
    test('returns items in reversed order', () {
      final all = [_manga(id: '1'), _manga(id: '2'), _manga(id: '3')];
      final result = HomeClassifier.latest(all);
      expect(result.map((m) => m.id).toList(), ['3', '2', '1']);
    });

    test('caps to showMany items', () {
      final all = _buildList(50);
      expect(HomeClassifier.latest(all).length, HomeClassifier.showMany);
    });
  });

  group('HomeClassifier.popular', () {
    test('includes only items with both coverUrl and description', () {
      final all = [
        _manga(id: '1'),
        _manga(id: '2', coverUrl: 'url'),
        _manga(id: '3', description: 'desc'),
        _manga(id: '4', coverUrl: 'url', description: 'desc'),
      ];
      final result = HomeClassifier.popular(all);
      expect(result.map((m) => m.id).toList(), ['4']);
    });

    test('caps to showMany items', () {
      final all = List.generate(
        50,
        (i) => _manga(id: '$i', coverUrl: 'url', description: 'desc'),
      );
      expect(HomeClassifier.popular(all).length, HomeClassifier.showMany);
    });
  });

  group('HomeClassifier.byDemographic', () {
    test('returns only items matching the given demographic', () {
      final all = [
        _manga(id: '1', demographic: 'shounen'),
        _manga(id: '2', demographic: 'shoujo'),
        _manga(id: '3', demographic: 'shounen'),
      ];
      final result = HomeClassifier.byDemographic(all, 'shounen');
      expect(result.map((m) => m.id).toList(), ['1', '3']);
    });

    test('returns empty list when no items match', () {
      final all = [_manga(id: '1', demographic: 'shounen')];
      expect(HomeClassifier.byDemographic(all, 'josei'), isEmpty);
    });

    test('caps to showMany items', () {
      final all = List.generate(
        50,
        (i) => _manga(id: '$i', demographic: 'seinen'),
      );
      expect(
        HomeClassifier.byDemographic(all, 'seinen').length,
        HomeClassifier.showMany,
      );
    });
  });

  group('HomeClassifier.classify', () {
    test('produces a HomeState that matches individual method outputs', () {
      final all = [
        _manga(id: '1', demographic: 'shounen'),
        _manga(id: '2', coverUrl: 'url', description: 'desc'),
        _manga(id: '3', demographic: 'shoujo'),
      ];

      final state = HomeClassifier.classify(all);

      expect(state.featured, HomeClassifier.featured(all));
      expect(state.latest, HomeClassifier.latest(all));
      expect(state.popular, HomeClassifier.popular(all));
      expect(state.shounen, HomeClassifier.byDemographic(all, 'shounen'));
      expect(state.shoujo, HomeClassifier.byDemographic(all, 'shoujo'));
      expect(state.seinen, HomeClassifier.byDemographic(all, 'seinen'));
      expect(state.josei, HomeClassifier.byDemographic(all, 'josei'));
    });

    test('returns empty lists for every section when input is empty', () {
      final state = HomeClassifier.classify([]);
      expect(state.featured, isEmpty);
      expect(state.latest, isEmpty);
      expect(state.popular, isEmpty);
      expect(state.shounen, isEmpty);
      expect(state.shoujo, isEmpty);
      expect(state.seinen, isEmpty);
      expect(state.josei, isEmpty);
    });
  });
}
