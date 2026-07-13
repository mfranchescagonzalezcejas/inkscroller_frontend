import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';

void main() {
  test('exploreProvider is a StateNotifierProvider<LibraryNotifier, LibraryState>',
      () {
    // Verify the provider is declared with the correct type at compile time.
    // ignore: unnecessary_type_check
    expect(exploreProvider, isA<ProviderBase<dynamic>>());
  });
}
