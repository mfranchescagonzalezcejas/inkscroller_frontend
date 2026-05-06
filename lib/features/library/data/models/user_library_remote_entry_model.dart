import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';
import '../mappers/manga_mapper.dart';
import 'manga_model.dart';

/// Remote DTO for `GET /users/me/library` items.
class UserLibraryRemoteEntryModel {
  final MangaModel manga;
  final UserLibraryStatus status;
  final DateTime updatedAt;

  const UserLibraryRemoteEntryModel({
    required this.manga,
    required this.status,
    required this.updatedAt,
  });

  factory UserLibraryRemoteEntryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> library =
        (json['library'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return UserLibraryRemoteEntryModel(
      manga: MangaModel.fromJson(json),
      status: UserLibraryStatusX.fromStorageValue(
        library['library_status'] as String?,
      ),
      updatedAt: _parseUpdatedAt(library['updated_at'] as String?),
    );
  }

  UserLibraryEntry toEntity() {
    return UserLibraryEntry(
      manga: manga.toEntity(),
      isInLibrary: true,
      status: status,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseUpdatedAt(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(raw)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
