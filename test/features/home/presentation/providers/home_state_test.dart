import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_state.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';

void main() {
  group('HomeState', () {
    test('can be constructed without the latest field', () {
      const state = HomeState(
        featured: [],
        popular: [],
        shounen: [],
        shoujo: [],
        seinen: [],
        josei: [],
      );

      expect(state.featured, isEmpty);
      expect(state.popular, isEmpty);
      expect(state.shounen, isEmpty);
      expect(state.shoujo, isEmpty);
      expect(state.seinen, isEmpty);
      expect(state.josei, isEmpty);
    });

    test('keeps the demographic and featured sections', () {
      final manga = Manga(id: 'm1', title: 'Manga One');
      final state = HomeState(
        featured: [manga],
        popular: [],
        shounen: [],
        shoujo: [],
        seinen: [],
        josei: [],
      );

      expect(state.featured, [manga]);
    });
  });
}
