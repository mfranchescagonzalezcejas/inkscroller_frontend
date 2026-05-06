import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/usecases/get_manga_list.dart';
import '../../../domain/usecases/search_manga.dart';
import 'library_notifier.dart';
import 'library_state.dart';

/// Riverpod provider that wires [LibraryNotifier] with its use-case dependencies.
///
/// Resolves [GetMangaList] and [SearchManga] from get_it and exposes
/// the reactive [LibraryState] to the widget tree.
final libraryProvider =
StateNotifierProvider<LibraryNotifier, LibraryState>(
      (ref) {
    return LibraryNotifier(
      sl<GetMangaList>(),
      sl<SearchManga>(),
    );
  },
);
