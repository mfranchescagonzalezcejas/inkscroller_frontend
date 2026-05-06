import '../../domain/entities/manga.dart';
import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';

/// Serializable model for [UserLibraryEntry].
class UserLibraryEntryModel {
  final String mangaId;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? demographic;
  final String? publicationStatus;
  final List<String> genres;
  final double? score;
  final int? rank;
  final String? type;
  final int? year;
  final List<String> authors;
  final int? readChaptersCount;
  final int? totalChaptersCount;
  final bool isInLibrary;
  final String userLibraryStatus;
  final int updatedAtMillis;

  const UserLibraryEntryModel({
    required this.mangaId,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.demographic,
    required this.publicationStatus,
    required this.genres,
    required this.score,
    required this.rank,
    required this.type,
    required this.year,
    required this.authors,
    required this.readChaptersCount,
    required this.totalChaptersCount,
    required this.isInLibrary,
    required this.userLibraryStatus,
    required this.updatedAtMillis,
  });

  factory UserLibraryEntryModel.fromEntity(UserLibraryEntry entry) {
    final Manga manga = entry.manga;
    return UserLibraryEntryModel(
      mangaId: manga.id,
      title: manga.title,
      description: manga.description,
      coverUrl: manga.coverUrl,
      demographic: manga.demographic,
      publicationStatus: manga.status,
      genres: manga.genres,
      score: manga.score,
      rank: manga.rank,
      type: manga.type,
      year: manga.year,
      authors: manga.authors,
      readChaptersCount: manga.readChaptersCount,
      totalChaptersCount: manga.totalChaptersCount,
      isInLibrary: entry.isInLibrary,
      userLibraryStatus: entry.status.storageValue,
      updatedAtMillis: entry.updatedAt.millisecondsSinceEpoch,
    );
  }

  factory UserLibraryEntryModel.fromJson(Map<String, dynamic> json) {
    return UserLibraryEntryModel(
      mangaId: json['mangaId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      demographic: json['demographic'] as String?,
      publicationStatus: json['publicationStatus'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      score: (json['score'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
      type: json['type'] as String?,
      year: json['year'] as int?,
      authors: (json['authors'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      readChaptersCount: json['readChaptersCount'] as int?,
      totalChaptersCount: json['totalChaptersCount'] as int?,
      isInLibrary: json['isInLibrary'] as bool? ?? true,
      userLibraryStatus: json['userLibraryStatus'] as String? ?? 'reading',
      updatedAtMillis:
          json['updatedAtMillis'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  UserLibraryEntry toEntity() {
    return UserLibraryEntry(
      manga: Manga(
        id: mangaId,
        title: title,
        description: description,
        coverUrl: coverUrl,
        demographic: demographic,
        status: publicationStatus,
        genres: genres,
        score: score,
        rank: rank,
        type: type,
        year: year,
        authors: authors,
        readChaptersCount: readChaptersCount,
        totalChaptersCount: totalChaptersCount,
      ),
      isInLibrary: isInLibrary,
      status: UserLibraryStatusX.fromStorageValue(userLibraryStatus),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mangaId': mangaId,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'demographic': demographic,
      'publicationStatus': publicationStatus,
      'genres': genres,
      'score': score,
      'rank': rank,
      'type': type,
      'year': year,
      'authors': authors,
      'readChaptersCount': readChaptersCount,
      'totalChaptersCount': totalChaptersCount,
      'isInLibrary': isInLibrary,
      'userLibraryStatus': userLibraryStatus,
      'updatedAtMillis': updatedAtMillis,
    };
  }
}
