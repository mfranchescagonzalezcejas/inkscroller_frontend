import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_capabilities.dart';

void main() {
  test('supports unspecified when null_union is true and contract is v1', () {
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
    // Pagination type does not affect the unspecified support.
    expect(
      MangaCapabilities.fromJson(const <String, Object>{
        'demographic_filter': <String, Object>{
          'contract_version': 1,
          'null_union': true,
          'pagination': 'offset',
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
          'contract_version': 2,
          'null_union': true,
          'pagination': 'cursor-v1',
        },
      }).supportsUnspecified,
      isFalse,
    );
  });
}
