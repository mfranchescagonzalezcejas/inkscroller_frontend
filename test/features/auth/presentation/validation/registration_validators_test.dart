import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/presentation/validation/registration_validators.dart';

void main() {
  group('RegistrationValidators', () {
    test('normalizes username by trimming and lowercasing', () {
      expect(
        RegistrationValidators.normalizeUsername('  Alice_01  '),
        'alice_01',
      );
    });

    test('validates backend-compatible usernames', () {
      expect(RegistrationValidators.isValidUsername('abc'), isTrue);
      expect(RegistrationValidators.isValidUsername('user-name_01'), isTrue);
      expect(RegistrationValidators.isValidUsername('ab'), isFalse);
      expect(RegistrationValidators.isValidUsername('user name'), isFalse);
      expect(RegistrationValidators.isValidUsername('user.name'), isFalse);
    });

    test('parses only strict yyyy-mm-dd birth dates', () {
      expect(
        RegistrationValidators.parseBirthDate('2000-02-03'),
        DateTime(2000, 2, 3),
      );
      expect(RegistrationValidators.parseBirthDate('2000-02-31'), isNull);
      expect(RegistrationValidators.parseBirthDate('02/03/2000'), isNull);
    });

    test('rejects future and pre-1900 birth dates', () {
      final now = DateTime(2026, 6, 28);

      expect(
        RegistrationValidators.isAllowedBirthDate(DateTime(1900), now: now),
        isTrue,
      );
      expect(
        RegistrationValidators.isAllowedBirthDate(
          DateTime(1899, 12, 31),
          now: now,
        ),
        isFalse,
      );
      expect(
        RegistrationValidators.isAllowedBirthDate(
          DateTime(2026, 6, 29),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
