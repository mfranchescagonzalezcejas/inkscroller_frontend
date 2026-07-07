import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/reader_mode.dart';
import '../../domain/entities/reading_preferences.dart';
import '../../domain/usecases/get_per_title_override.dart';
import '../../domain/usecases/remove_per_title_override.dart';
import '../../domain/usecases/save_per_title_override.dart';

/// Riverpod family provider for per-title reader mode overrides.
///
/// Keyed by manga ID so each manga has its own independent state.
final perTitleOverrideProvider =
    StateNotifierProvider.family<PerTitleOverrideNotifier, PerTitleOverride?, String>(
      (ref, mangaId) => PerTitleOverrideNotifier(
        mangaId: mangaId,
        getOverride: sl(),
        saveOverride: sl(),
        removeOverride: sl(),
      ),
    );

/// Notifier that loads and saves per-title reader mode overrides.
class PerTitleOverrideNotifier extends StateNotifier<PerTitleOverride?> {
  final String mangaId;
  final GetPerTitleOverride getOverride;
  final SavePerTitleOverride saveOverride;
  final RemovePerTitleOverride removeOverride;

  PerTitleOverrideNotifier({
    required this.mangaId,
    required this.getOverride,
    required this.saveOverride,
    required this.removeOverride,
  }) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await getOverride(mangaId);
  }

  Future<void> setMode(ReaderMode mode) async {
    final override = PerTitleOverride(
      mangaId: mangaId,
      preferredReaderMode: mode,
    );
    await saveOverride(override);
    state = override;
  }

  Future<void> clearOverride() async {
    await removeOverride(mangaId);
    state = null;
  }
}
