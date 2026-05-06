/// Transient UI state for the reader — brightness overlay, AMOLED mode,
/// immersive mode. Lives only for the duration of a reader session.
class ReaderUiState {
  /// Brightness level [0.0, 1.0] where 1.0 = full brightness (no overlay).
  /// Rendered as a `Colors.black.withOpacity(1 - brightness)` overlay.
  final double brightness;

  /// When true, the reader background uses pure black (#000000) instead of
  /// [AppColors.voidLowest] (#080F10). Saves battery on OLED screens.
  final bool amoledBlack;

  /// When true, system UI bars (status + navigation) are hidden via
  /// [SystemChrome.setEnabledSystemUIMode].
  final bool immersiveMode;

  const ReaderUiState({
    this.brightness = 1.0,
    this.amoledBlack = false,
    this.immersiveMode = false,
  });

  ReaderUiState copyWith({
    double? brightness,
    bool? amoledBlack,
    bool? immersiveMode,
  }) {
    return ReaderUiState(
      brightness: brightness ?? this.brightness,
      amoledBlack: amoledBlack ?? this.amoledBlack,
      immersiveMode: immersiveMode ?? this.immersiveMode,
    );
  }
}
