import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import 'reader_notifier.dart';
import 'reader_state.dart';

/// Family provider keyed by chapter ID that creates a [ReaderNotifier] per chapter.
///
/// Each instance independently loads and pre-caches page images, allowing
/// multiple chapters to be opened without shared mutable state.
final readerProvider =
    StateNotifierProvider.family<ReaderNotifier, ReaderState, String>(
      (ref, chapterId) =>
          ReaderNotifier(getChapterPages: sl(), resolveReaderMode: sl()),
    );
