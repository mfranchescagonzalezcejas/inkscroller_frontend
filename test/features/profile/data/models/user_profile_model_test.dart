import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/profile/data/models/user_profile_model.dart';

void main() {
  test('parses username and birth_date from /users/me response', () {
    final model = UserProfileModel.fromJson(const <String, dynamic>{
      'firebase_uid': 'uid-123',
      'email': 'alice@example.com',
      'display_name': null,
      'username': 'alice_01',
      'birth_date': '2000-02-03',
      'created_at': '2026-06-28T12:00:00Z',
    });

    final entity = model.toEntity();

    expect(entity.firebaseUid, 'uid-123');
    expect(entity.username, 'alice_01');
    expect(entity.birthDate, DateTime(2000, 2, 3));
    expect(entity.createdAt, DateTime.parse('2026-06-28T12:00:00Z'));
  });

  test('keeps optional metadata null when backend omits it', () {
    final model = UserProfileModel.fromJson(const <String, dynamic>{
      'firebase_uid': 'uid-123',
      'email': 'alice@example.com',
      'created_at': '2026-06-28T12:00:00Z',
    });

    final entity = model.toEntity();

    expect(entity.username, isNull);
    expect(entity.birthDate, isNull);
  });
}
