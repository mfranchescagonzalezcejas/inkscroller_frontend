import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reader_mode.dart';
import '../../domain/entities/reading_preferences.dart';
import '../../domain/repositories/per_title_override_repository.dart';

/// SharedPreferences-backed implementation of per-title reader mode overrides.
class PerTitleOverrideRepositoryImpl implements PerTitleOverrideRepository {
  final SharedPreferences prefs;

  PerTitleOverrideRepositoryImpl(this.prefs);

  static const String _prefix = 'per_title_override_';

  @override
  Future<PerTitleOverride?> getOverride(String mangaId) async {
    final json = prefs.getString('$_prefix$mangaId');
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return PerTitleOverride(
        mangaId: data['mangaId'] as String,
        preferredReaderMode: ReaderMode.values.byName(
          data['preferredReaderMode'] as String,
        ),
      );
    } on Object {
      await removeOverride(mangaId);
      return null;
    }
  }

  @override
  Future<void> saveOverride(PerTitleOverride override) async {
    final json = jsonEncode({
      'mangaId': override.mangaId,
      'preferredReaderMode': override.preferredReaderMode.name,
    });
    await prefs.setString('$_prefix${override.mangaId}', json);
  }

  @override
  Future<void> removeOverride(String mangaId) async {
    await prefs.remove('$_prefix$mangaId');
  }
}
