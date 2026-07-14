import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_capabilities.dart';

void main() {
  test('supports only the exact null-union cursor-v1 contract', () {
    expect(
      MangaCapabilities.fromJson(const <String, Object>{
        'demographic_filter': <String, Object>{
          'contract_version': 1,
          'null_union': true,
          'pagination': 'cursor-v1',
        },
      }).supportsUnspecified,
      isTrue,
    );
    expect(
      MangaCapabilities.fromJson(const <String, Object>{}).supportsUnspecified,
      isFalse,
    );
    expect(
      MangaCapabilities.fromJson(const <String, Object>{
        'demographic_filter': <String, Object>{
          'contract_version': 1,
          'null_union': false,
          'pagination': 'cursor-v1',
        },
      }).supportsUnspecified,
      isFalse,
    );
    expect(
      MangaCapabilities.fromJson(const <String, Object>{
        'demographic_filter': <String, Object>{
          'contract_version': 1,
          'null_union': true,
          'pagination': 'offset-v1',
        },
      }).supportsUnspecified,
      isFalse,
    );
    expect(
      MangaCapabilities.fromJson(const <String, Object>{
        'demographic_filter': <String, Object>{
          'contract_version': 2,
          'null_union': true,
          'pagination': 'cursor-v1',
        },
      }).supportsUnspecified,
      isFalse,
    );
  });
}
