import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/home/presentation/constants/home_layout.dart';

void main() {
  group('HomeLayout', () {
    test('defines heroCarouselHeight as 460.0', () {
      expect(HomeLayout.heroCarouselHeight, 460.0);
    });

    test('keeps mangaCardRowHeight for demographic rows', () {
      expect(HomeLayout.mangaCardRowHeight, 220.0);
    });
  });
}
