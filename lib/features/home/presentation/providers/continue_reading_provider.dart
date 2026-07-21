import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/domain/entities/manga_reading_progress.dart';
import '../../../library/domain/entities/user_library_entry.dart';
import '../../../library/presentation/providers/reading_progress_provider.dart';
import '../../../library/presentation/providers/user_library_provider.dart';

/// View model exposed by [continueReadingProvider].
class ContinueReadingItem {
  const ContinueReadingItem({required this.manga, required this.progress});

  final Manga manga;
  final MangaReadingProgress progress;
}

/// Derived provider that builds the "Continue Reading" rail for signed-in users.
///
/// It resolves progress records against the user library, filters out
/// incomplete/invalid entries, sorts by recency, and caps the result at eight.
final continueReadingProvider = FutureProvider<List<ContinueReadingItem>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return const <ContinueReadingItem>[];
  }

  final progressNotifier = ref.watch(readingProgressProvider.notifier);
  await progressNotifier.initialized;
  final progressMap = ref.watch(readingProgressProvider);
  final userLibrary = ref.watch(userLibraryProvider);

  return _buildContinueReadingItems(
    progressMap: progressMap,
    userLibrary: userLibrary,
  );
});

List<ContinueReadingItem> _buildContinueReadingItems({
  required Map<String, MangaReadingProgress> progressMap,
  required Map<String, UserLibraryEntry> userLibrary,
}) {
  final mangaLookup = <String, Manga>{};
  for (final entry in userLibrary.values) {
    mangaLookup[entry.manga.id] = entry.manga;
  }

  final items = <ContinueReadingItem>[];
  for (final entry in progressMap.entries) {
    final manga = mangaLookup[entry.key];
    if (manga == null) continue;

    final progress = entry.value;
    if (progress.readChaptersCount <= 0) continue;
    if (progress.hasKnownTotal &&
        progress.readChaptersCount >= progress.totalChaptersCount) {
      continue;
    }

    items.add(ContinueReadingItem(manga: manga, progress: progress));
  }

  items.sort((a, b) => b.progress.updatedAt.compareTo(a.progress.updatedAt));

  if (items.length > 8) {
    return items.take(8).toList();
  }
  return items;
}
