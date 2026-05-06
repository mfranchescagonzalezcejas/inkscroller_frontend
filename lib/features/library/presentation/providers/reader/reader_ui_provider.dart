import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reader_ui_state.dart';

/// Scoped provider — one instance per reader session (keyed by chapterId).
final readerUiProvider =
    StateNotifierProvider.family<ReaderUiNotifier, ReaderUiState, String>(
      (ref, chapterId) => ReaderUiNotifier(),
    );

class ReaderUiNotifier extends StateNotifier<ReaderUiState> {
  ReaderUiNotifier() : super(const ReaderUiState());

  void setBrightness(double value) {
    state = state.copyWith(brightness: value.clamp(0.1, 1.0));
  }

  void toggleAmoled() {
    state = state.copyWith(amoledBlack: !state.amoledBlack);
  }

  void toggleImmersive() {
    final next = !state.immersiveMode;
    state = state.copyWith(immersiveMode: next);
    if (next) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Restore system UI when leaving the reader.
  void restore() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}
