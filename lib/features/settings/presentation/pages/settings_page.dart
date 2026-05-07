import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/layout.dart';
import '../../../../core/design/design_tokens.dart'
    show AppColors, AppTypography;
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/info_list_card.dart';
import '../../../../flavors/flavor_config.dart';
import '../providers/settings_cache_controller.dart';

/// Settings page — cache maintenance and app environment info.
///
/// Accessible from Profile → "Caché y datos guardados".
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isClearingCache = false;

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);

    final result = await ref
        .read(settingsCacheControllerProvider)
        .clearLibraryCache();

    if (!mounted) return;

    // Refresh the displayed cache size after clearing.
    ref.invalidate(cacheSizeProvider);

    result.fold(
      (failure) => AppFeedback.showError(
        context,
        title: context.l10n.settingsCacheClearFailedMessage,
      ),
      (_) => AppFeedback.showSuccess(
        context,
        title: context.l10n.settingsCacheClearedMessage,
      ),
    );

    if (mounted) setState(() => _isClearingCache = false);
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = ref.watch(cacheSizeProvider);

    return Scaffold(
      backgroundColor: AppColors.stage,
      appBar: AppBar(
        backgroundColor: AppColors.stage,
        foregroundColor: AppColors.onSurface,
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
        elevation: 0,
        title: Text(
          context.l10n.settingsTitle,
          style: AppTypography.titleLgStyle.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: <Widget>[
            // ── App info ──────────────────────────────────────────────────
            _SectionLabel(
              text: context.l10n.settingsAppSectionTitle.toUpperCase(),
            ),
            const SizedBox(height: 8),
            InfoListCard(
              children: <Widget>[
                InfoListRow(
                  label: context.l10n.settingsAppNameLabel,
                  value: FlavorConfig.instance.name,
                  icon: Icons.apps_outlined,
                ),
                InfoListRow(
                  label: context.l10n.settingsFlavorLabel,
                  value: FlavorConfig.instance.flavor.name.toUpperCase(),
                  icon: Icons.tune_outlined,
                ),
                InfoListRow(
                  label: context.l10n.settingsApiBaseUrlLabel,
                  value: ApiConfig.baseUrl,
                  icon: Icons.code_outlined,
                ),
              ],
            ),

            // ── Cache ─────────────────────────────────────────────────────
            const SizedBox(height: 24),
            _SectionLabel(
              text: context.l10n.settingsCacheSectionTitle.toUpperCase(),
            ),
            const SizedBox(height: 8),
            InfoListCard(
              children: <Widget>[
                InfoListRow(
                  label: context.l10n.settingsCacheSizeLabel,
                  value: cacheSize,
                  icon: Icons.storage_outlined,
                ),
                InfoListRow(
                  label: context.l10n.settingsMangaListCacheLabel,
                  value: context.l10n.settingsCacheMinutesValue(
                    AppConstants.mangaListCacheTtlMinutes,
                  ),
                  icon: Icons.view_list_outlined,
                ),
                InfoListRow(
                  label: context.l10n.settingsMangaDetailCacheLabel,
                  value: context.l10n.settingsCacheMinutesValue(
                    AppConstants.mangaDetailCacheTtlMinutes,
                  ),
                  icon: Icons.menu_book_outlined,
                ),
                InfoListRow(
                  label: context.l10n.settingsMangaChaptersCacheLabel,
                  value: context.l10n.settingsCacheMinutesValue(
                    AppConstants.mangaChaptersCacheTtlMinutes,
                  ),
                  icon: Icons.auto_stories_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ClearCacheButton(
              isLoading: _isClearingCache,
              onTap: _isClearingCache ? null : _clearCache,
              label: context.l10n.settingsClearCacheAction,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.outline,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Clear cache button ────────────────────────────────────────────────────────

class _ClearCacheButton extends StatelessWidget {
  const _ClearCacheButton({
    required this.isLoading,
    required this.label,
    this.onTap,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          ),
        ),
        onPressed: onTap,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.delete_sweep_outlined,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
