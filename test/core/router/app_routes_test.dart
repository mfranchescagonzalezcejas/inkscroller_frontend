import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('builds manga detail path with manga id', () {
      expect(AppRoutes.mangaDetailPath('abc-123'), '/manga/abc-123');
    });

    test('builds reader path with manga and chapter ids', () {
      expect(
        AppRoutes.readerPath(mangaId: 'manga-1', chapterId: 'ch-2'),
        '/manga/manga-1/chapter/ch-2',
      );
    });
  });
}
