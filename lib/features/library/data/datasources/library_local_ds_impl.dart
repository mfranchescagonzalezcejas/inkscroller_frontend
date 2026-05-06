import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import 'library_local_ds.dart';

/// SharedPreferences-backed cache for library payloads.
class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  const LibraryLocalDataSourceImpl(this.sharedPreferences);

  final SharedPreferences sharedPreferences;

  @override
  Future<List<MangaModel>?> getCachedMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    required Duration maxAge,
  }) async {
    final Map<String, dynamic>? payload = _readPayload(
      _mangaListKey(limit: limit, offset: offset, order: order),
      maxAge: maxAge,
    );

    final List<dynamic>? rawItems = payload?['items'] as List<dynamic>?;
    if (rawItems == null) return null;

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(MangaModel.fromJson)
        .toList();
  }

  @override
  Future<void> cacheMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    required List<MangaModel> mangas,
  }) {
    return _writePayload(
      _mangaListKey(limit: limit, offset: offset, order: order),
      <String, dynamic>{
        'items': mangas.map((manga) => manga.toJson()).toList(),
      },
    );
  }

  @override
  Future<MangaModel?> getCachedMangaDetail(
    String mangaId, {
    required Duration maxAge,
  }) async {
    final Map<String, dynamic>? payload = _readPayload(
      'library.manga_detail.$mangaId',
      maxAge: maxAge,
    );

    final Map<String, dynamic>? item = payload?['item'] as Map<String, dynamic>?;
    if (item == null) return null;

    return MangaModel.fromJson(item);
  }

  @override
  Future<void> cacheMangaDetail(String mangaId, MangaModel manga) {
    return _writePayload(
      'library.manga_detail.$mangaId',
      <String, dynamic>{
        'item': manga.toJson(),
      },
    );
  }

  @override
  Future<List<ChapterModel>?> getCachedMangaChapters(
    String mangaId, {
    required Duration maxAge,
  }) async {
    final Map<String, dynamic>? payload = _readPayload(
      'library.manga_chapters.$mangaId',
      maxAge: maxAge,
    );

    final List<dynamic>? rawItems = payload?['items'] as List<dynamic>?;
    if (rawItems == null) return null;

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(ChapterModel.fromJson)
        .toList();
  }

  @override
  Future<void> cacheMangaChapters(String mangaId, List<ChapterModel> chapters) {
    return _writePayload(
      'library.manga_chapters.$mangaId',
      <String, dynamic>{
        'items': chapters.map((chapter) => chapter.toJson()).toList(),
      },
    );
  }

  @override
  Future<void> clearLibraryCache() async {
    try {
      final Iterable<String> keys = sharedPreferences.getKeys().where(
        (key) => key.startsWith('library.'),
      );

      for (final key in keys) {
        await sharedPreferences.remove(key);
      }
    } on Exception catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  String _mangaListKey({
    required int limit,
    required int offset,
    Map<String, String>? order,
  }) {
    final String orderPart = order == null || order.isEmpty
        ? 'default'
        : order.entries
              .map((entry) => '${entry.key}:${entry.value}')
              .join(',');

    return 'library.manga_list.$limit.$offset.$orderPart';
  }

  Map<String, dynamic>? _readPayload(String key, {required Duration maxAge}) {
    try {
      final String? raw = sharedPreferences.getString(key);
      if (raw == null) return null;

      final Map<String, dynamic> payload =
          jsonDecode(raw) as Map<String, dynamic>;
      final int? timestamp = payload['timestamp'] as int?;
      if (timestamp == null) return null;

      final DateTime cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > maxAge) {
        return null;
      }

      return payload;
    } on Exception catch (error) {
      throw CacheException(message: error.toString());
    }
  }

  Future<void> _writePayload(String key, Map<String, dynamic> data) async {
    try {
      final bool saved = await sharedPreferences.setString(
        key,
        jsonEncode(<String, dynamic>{
          ...data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (!saved) {
        throw const CacheException(message: 'No se pudo persistir el cache');
      }
    } on CacheException {
      rethrow;
    } on Exception catch (error) {
      throw CacheException(message: error.toString());
    }
  }
}
