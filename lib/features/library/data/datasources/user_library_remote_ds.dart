import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';

/// Authenticated remote datasource for user-library sync endpoints.
abstract class UserLibraryRemoteDataSource {
  Future<Map<String, UserLibraryEntry>> getLibrary();

  Future<void> addToLibrary(
    String mangaId, {
    String? title,
    String? coverUrl,
    List<String> authors,
    String? type,
    String? demographic,
    List<String>? genres,
    String? status,
  });

  Future<void> updateLibraryStatus(String mangaId, UserLibraryStatus status);

  Future<void> removeFromLibrary(String mangaId);
}
