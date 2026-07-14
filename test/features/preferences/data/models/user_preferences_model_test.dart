import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/preferences/data/models/user_preferences_model.dart';

void main() {
  group('UserPreferencesModel demographicFilter serialization', () {
    test('fromJson reads demographic_filter as list of MangaDemographic', () {
      final json = {
        'firebase_uid': 'uid-123',
        'default_reader_mode': 'vertical',
        'default_language': 'en',
        'demographic_filter': ['shounen', 'shoujo', 'seinen'],
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final model = UserPreferencesModel.fromJson(json);

      expect(model.demographicFilter, isNotNull);
      expect(model.demographicFilter, hasLength(3));
      expect(model.demographicFilter, contains(MangaDemographic.shounen));
      expect(model.demographicFilter, contains(MangaDemographic.shoujo));
      expect(model.demographicFilter, contains(MangaDemographic.seinen));
    });

    test('fromJson handles null demographic_filter', () {
      final json = {
        'firebase_uid': 'uid-123',
        'default_reader_mode': 'vertical',
        'default_language': 'en',
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final model = UserPreferencesModel.fromJson(json);

      expect(model.demographicFilter, isNull);
    });

    test('fromJson handles empty demographic_filter list', () {
      final json = {
        'firebase_uid': 'uid-123',
        'default_reader_mode': 'vertical',
        'default_language': 'en',
        'demographic_filter': <String>[],
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final model = UserPreferencesModel.fromJson(json);

      expect(model.demographicFilter, isNotNull);
      expect(model.demographicFilter, isEmpty);
    });

    test('toUpdateJson includes demographic_filter when provided', () {
      const model = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        demographicFilter: [MangaDemographic.shounen, MangaDemographic.josei],
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final json = model.toUpdateJson();

      expect(json['demographic_filter'], isA<List<String>>());
      expect(json['demographic_filter'], ['shounen', 'josei']);
    });

    test('toUpdateJson omits demographic_filter when null', () {
      const model = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final json = model.toUpdateJson();

      expect(json.containsKey('demographic_filter'), isFalse);
    });

    test('toUpdateJson sends null for empty demographic_filter list', () {
      const model = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        demographicFilter: <MangaDemographic>[],
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final json = model.toUpdateJson();

      // Empty list means "clear the preference" → send null to backend
      expect(json['demographic_filter'], isNull);
    });

    test('toEntity maps demographicFilter from model to entity', () {
      const model = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        demographicFilter: [MangaDemographic.shounen, MangaDemographic.shoujo],
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final entity = model.toEntity();

      expect(entity.demographicFilter, isNotNull);
      expect(entity.demographicFilter, hasLength(2));
      expect(entity.demographicFilter, contains(MangaDemographic.shounen));
      expect(entity.demographicFilter, contains(MangaDemographic.shoujo));
    });

    test('toEntity maps null demographicFilter to null', () {
      const model = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final entity = model.toEntity();

      expect(entity.demographicFilter, isNull);
    });

    test('roundtrip fromJson → toUpdateJson preserves demographicFilter', () {
      const original = UserPreferencesModel(
        firebaseUid: 'uid-123',
        defaultReaderMode: 'vertical',
        defaultLanguage: 'en',
        demographicFilter: [
          MangaDemographic.kodomo,
          MangaDemographic.seinen,
          MangaDemographic.unspecified,
        ],
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final json = original.toUpdateJson();
      final restored = UserPreferencesModel.fromJson({
        'firebase_uid': 'uid-123',
        'default_reader_mode': 'vertical',
        'default_language': 'en',
        'demographic_filter': json['demographic_filter'],
        'updated_at': '2026-01-01T00:00:00.000',
      });

      expect(restored.demographicFilter, original.demographicFilter);
    });
  });
}
