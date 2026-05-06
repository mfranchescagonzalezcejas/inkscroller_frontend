import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/reader_mode.dart';
import '../providers/per_title_override_provider.dart';
import '../providers/reader/reader_ui_provider.dart';
import '../providers/reader/reader_ui_state.dart';

/// Phase 6 reader settings bottom sheet.
///
/// Controls:
/// - Reading direction: LTR (paged) / RTL (paged) / Vertical — persisted via
///   [perTitleOverrideProvider] for this manga.
/// - Brightness overlay: local, transient, stored in [readerUiProvider].
/// - AMOLED Black toggle: local, transient.
/// - Immersive Mode toggle: local, triggers [SystemChrome] change.
///
/// Open via [showReaderSettings].
class ReaderSettingsSheet extends ConsumerWidget {
  final String chapterId;
  final String? mangaId;

  const ReaderSettingsSheet({
    super.key,
    required this.chapterId,
    this.mangaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderUiState uiState = ref.watch(readerUiProvider(chapterId));
    final ReaderUiNotifier uiNotifier =
        ref.read(readerUiProvider(chapterId).notifier);

    // Per-title override determines the active reading direction.
    final override = mangaId != null
        ? ref.watch(perTitleOverrideProvider(mangaId!))
        : null;
    final activeMode = override?.preferredReaderMode ?? ReaderMode.vertical;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Color(0x0DFFFFFF)),
          left: BorderSide(color: Color(0x0DFFFFFF)),
          right: BorderSide(color: Color(0x0DFFFFFF)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── Handle ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x33889391),
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── Reading Direction ──────────────────────────────────────
                  _SectionLabel(context.l10n.readerSettingsDirection),
                  const SizedBox(height: 12),
                  _DirectionSegment(
                    active: activeMode,
                    mangaId: mangaId,
                    ref: ref,
                  ),

                  const SizedBox(height: 32),

                  // ── Brightness ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _SectionLabel(context.l10n.readerSettingsBrightness),
                      const Icon(
                        Icons.light_mode_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.voidLowest,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.12),
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 9),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 18),
                    ),
                    child: Slider(
                      value: uiState.brightness,
                      min: 0.1,
                      onChanged: uiNotifier.setBrightness,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── AMOLED Black ───────────────────────────────────────────
                  _ToggleRow(
                    title: context.l10n.readerSettingsAmoled,
                    subtitle: context.l10n.readerSettingsAmoledSubtitle,
                    value: uiState.amoledBlack,
                    onToggle: uiNotifier.toggleAmoled,
                  ),

                  const SizedBox(height: 24),

                  // ── Immersive Mode ─────────────────────────────────────────
                  _ToggleRow(
                    title: context.l10n.readerSettingsImmersive,
                    subtitle: context.l10n.readerSettingsImmersiveSubtitle,
                    value: uiState.immersiveMode,
                    onToggle: uiNotifier.toggleImmersive,
                  ),

                  const SizedBox(height: 32),

                  // ── Confirm ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cardHigh,
                        foregroundColor: AppColors.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.l10n.readerSettingsConfirm.toUpperCase(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the [ReaderSettingsSheet] as a modal bottom sheet.
Future<void> showReaderSettings(
  BuildContext context, {
  required String chapterId,
  String? mangaId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ReaderSettingsSheet(
      chapterId: chapterId,
      mangaId: mangaId,
    ),
  );
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 2,
      ),
    );
  }
}

class _DirectionSegment extends StatelessWidget {
  final ReaderMode active;
  final String? mangaId;
  final WidgetRef ref;

  const _DirectionSegment({
    required this.active,
    required this.mangaId,
    required this.ref,
  });

  void _select(ReaderMode mode) {
    if (mangaId == null) return;
    ref.read(perTitleOverrideProvider(mangaId!).notifier).setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.voidLowest,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          _SegmentButton(
            label: context.l10n.readerDirectionLtr,
            selected: active == ReaderMode.paged,
            onTap: () => _select(ReaderMode.paged),
          ),
          _SegmentButton(
            label: context.l10n.readerDirectionRtl,
            selected: false,
            onTap: () => _select(ReaderMode.paged),
          ),
          _SegmentButton(
            label: context.l10n.readerDirectionVertical,
            selected: active == ReaderMode.vertical,
            onTap: () => _select(ReaderMode.vertical),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _InkToggle(value: value),
        ],
      ),
    );
  }
}

/// Custom toggle that follows the Cinematic Canvas design.
/// Active: teal track + right-aligned thumb.
/// Inactive: void surface track + left-aligned muted thumb.
class _InkToggle extends StatelessWidget {
  final bool value;
  const _InkToggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.voidLowest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
