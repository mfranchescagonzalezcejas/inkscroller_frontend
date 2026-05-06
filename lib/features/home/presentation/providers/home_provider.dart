import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/presentation/providers/library/library_provider.dart';
import '../../../library/presentation/providers/library/library_state.dart';
import 'home_classifiers.dart';
import 'home_state.dart';

/// Derived provider that partitions the library manga list into [HomeState] sections.
///
/// Watches [libraryProvider] and delegates all classification logic to
/// [HomeClassifier], which groups manga into featured, latest, popular, and
/// demographic-based sections for the [HomePage] carousels.
final homeProvider = Provider<HomeState>((ref) {
  final LibraryState libraryState = ref.watch(libraryProvider);
  return HomeClassifier.classify(libraryState.mangas);
});
