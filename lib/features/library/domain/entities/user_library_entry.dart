import 'manga.dart';
import 'user_library_status.dart';

/// User-scoped local library record for a manga title.
class UserLibraryEntry {
  final Manga manga;
  final bool isInLibrary;
  final UserLibraryStatus status;
  final DateTime updatedAt;

  const UserLibraryEntry({
    required this.manga,
    required this.isInLibrary,
    required this.status,
    required this.updatedAt,
  });

  UserLibraryEntry copyWith({
    Manga? manga,
    bool? isInLibrary,
    UserLibraryStatus? status,
    DateTime? updatedAt,
  }) {
    return UserLibraryEntry(
      manga: manga ?? this.manga,
      isInLibrary: isInLibrary ?? this.isInLibrary,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
