import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_version_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart'
    show AppColors, AppTypography;
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/app_locale_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/domain/entities/reader_mode.dart';
import '../../../preferences/domain/entities/content_rating.dart';
import '../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../preferences/domain/entities/user_reading_preferences.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../../preferences/presentation/providers/preferences_state.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../providers/user_profile_state.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _profileRequested = false;
  bool _preferencesRequested = false;
  ReaderMode? _selectedReaderMode;
  String? _selectedReadingLanguage;

  static const List<String> _supportedAppLanguages = <String>['en', 'es'];

  static const List<String> _supportedLanguages = <String>[
    'en',
    'es',
    'pt',
    'fr',
    'de',
    'it',
    'ja',
    'ko',
    'zh',
  ];

  static const Map<String, String> _languageLabels = <String, String>{
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(userProfileProvider);
    final preferencesState = ref.watch(preferencesProvider);
    final contentRatingResolution = ref.watch(contentRatingResolutionProvider);

    if (authState.user != null && !_profileRequested) {
      _profileRequested = true;
      Future<void>.microtask(
        () => ref.read(userProfileProvider.notifier).loadProfile(),
      );
    }

    if (authState.user != null &&
        !_preferencesRequested &&
        !preferencesState.isLoading &&
        preferencesState.preferences == null) {
      _preferencesRequested = true;
      Future<void>.microtask(
        () => ref.read(preferencesProvider.notifier).loadPreferences(),
      );
    }

    if (authState.user == null) {
      _profileRequested = false;
      _preferencesRequested = false;
      _selectedReaderMode = null;
      _selectedReadingLanguage = null;
    }

    ref.listen(preferencesProvider, (previous, next) {
      if (next.preferences != null &&
          next.preferences != previous?.preferences) {
        setState(() {
          _selectedReaderMode = next.preferences?.defaultReaderMode;
          _selectedReadingLanguage = next.preferences?.defaultLanguage;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.stage,
      appBar: AppTopBar(
        authState: authState,
        enableDrawer: false,
        rightWidget: GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: const Icon(
            Icons.settings_outlined,
            color: AppColors.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: authState.user == null
            ? _buildGuestView(context)
            : _buildAuthenticatedView(
                context,
                profileState,
                preferencesState,
                contentRatingResolution,
              ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.profileGuestTitle,
                style: AppTypography.bodyLgStyle.copyWith(
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.profileGuestSubtitle,
                style: AppTypography.bodyStyle.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.voidLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(context.l10n.profileGuestCta),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context,
    UserProfileState profileState,
    PreferencesState preferencesState,
    ContentRatingResolution contentRatingResolution,
  ) {
    final appLocale = ref.watch(appLocaleProvider);
    final profile = profileState.profile;
    final prefs = preferencesState.preferences;
    final effectiveReaderMode =
        _selectedReaderMode ?? prefs?.defaultReaderMode ?? ReaderMode.vertical;
    final effectiveReadingLanguage =
        _selectedReadingLanguage ??
        prefs?.defaultLanguage ??
        AppConstants.defaultLanguage;
    final effectiveAppLanguage =
        appLocale?.languageCode ?? Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: <Widget>[
        // ── Error banner ──────────────────────────────────────────────────
        if (profileState.error != null) ...<Widget>[
          const SizedBox(height: 12),
          _ErrorBanner(
            onRetry: () => ref.read(userProfileProvider.notifier).loadProfile(),
          ),
        ],

        // ── Avatar section ────────────────────────────────────────────────
        _AvatarSection(profile: profile, isLoading: profileState.isLoading),

        // ── Preferences section ───────────────────────────────────────────
        _SectionLabel(label: context.l10n.profileReadingPreferencesSection),
        const SizedBox(height: 8),
        _PrefCard(
          children: <Widget>[
            _PrefRow(
              icon: Icons.menu_book_outlined,
              iconColor: AppColors.primary,
              title: context.l10n.profileReadingModeTitle,
              value: effectiveReaderMode == ReaderMode.vertical
                  ? context.l10n.profileReadingModeVertical
                  : context.l10n.profileReadingModePaged,
              onTap: preferencesState.isLoading
                  ? null
                  : () => _showReaderModeDialog(
                      context,
                      effectiveReaderMode,
                      prefs,
                    ),
            ),
            _PrefRow(
              icon: Icons.translate_outlined,
              iconColor: AppColors.primary,
              title: context.l10n.profilePreferredAppLanguageTitle,
              value:
                  _languageLabels[effectiveAppLanguage] ??
                  effectiveAppLanguage.toUpperCase(),
              onTap: preferencesState.isLoading
                  ? null
                  : () => _showAppLanguageDialog(context, effectiveAppLanguage),
            ),
            _PrefRow(
              icon: Icons.language_outlined,
              iconColor: AppColors.primary,
              title: context.l10n.profilePreferredReadingLanguageTitle,
              value:
                  _languageLabels[effectiveReadingLanguage] ??
                  effectiveReadingLanguage.toUpperCase(),
              onTap: preferencesState.isLoading
                  ? null
                  : () => _showReadingLanguageDialog(
                      context,
                      effectiveReadingLanguage,
                      prefs,
                    ),
            ),
            _PrefRow(
              icon: Icons.visibility_outlined,
              iconColor: AppColors.primary,
              title: context.l10n.profileContentRatingTitle,
              value: _contentRatingLabel(
                context,
                contentRatingResolution.effectiveRating,
              ),
              // Always tappable for authenticated users. The dialog shows only
              // age-allowed options, so an under-16 user sees a single option
              // (safe) with no effective choice — clear UX instead of a silent
              // no-op when profile/preferences are still loading.
              onTap: () => _showContentRatingDialog(
                context,
                contentRatingResolution,
                prefs,
              ),
            ),
          ],
        ),

        // ── App settings section ──────────────────────────────────────────
        const SizedBox(height: 20),
        _SectionLabel(label: context.l10n.profileAppSettingsSection),
        const SizedBox(height: 8),
        _PrefCard(
          children: <Widget>[
            _PrefRow(
              icon: Icons.storage_outlined,
              iconColor: AppColors.onSurfaceVariant,
              title: context.l10n.profileCacheSettingsTitle,
              value: context.l10n.profileCacheSettingsSubtitle,
              valueIsSubtitle: true,
              onTap: () => context.push(AppRoutes.settings),
            ),
            _PrefRow(
              icon: Icons.info_outline,
              iconColor: AppColors.onSurfaceVariant,
              title: context.l10n.profileAppInfoTitle,
              value: context.l10n.profileAppInfoSubtitle,
              valueIsSubtitle: true,
              onTap: () => context.push(AppRoutes.about),
            ),
          ],
        ),

        // ── Sign out ──────────────────────────────────────────────────────
        const SizedBox(height: 20),
        const _SignOutSection(),
      ],
    );
  }

  Future<void> _showReaderModeDialog(
    BuildContext context,
    ReaderMode current,
    UserReadingPreferences? prefs,
  ) async {
    final selected = await showDialog<ReaderMode>(
      context: context,
      builder: (ctx) => _SelectionDialog<ReaderMode>(
        title: context.l10n.profileReadingModeTitle,
        options: const <ReaderMode>[ReaderMode.vertical, ReaderMode.paged],
        current: current,
        labelFor: (mode) => mode == ReaderMode.vertical
            ? context.l10n.profileReadingModeVertical
            : context.l10n.profileReadingModePaged,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedReaderMode = selected);
    await ref
        .read(preferencesProvider.notifier)
        .savePreferences(
          defaultReaderMode: selected.name,
          defaultLanguage:
              _selectedReadingLanguage ??
              prefs?.defaultLanguage ??
              AppConstants.defaultLanguage,
        );
  }

  Future<void> _showAppLanguageDialog(
    BuildContext context,
    String current,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _SelectionDialog<String>(
        title: context.l10n.profilePreferredAppLanguageTitle,
        options: _supportedAppLanguages,
        current: current,
        labelFor: (lang) => _languageLabels[lang] ?? lang.toUpperCase(),
      ),
    );
    if (selected == null || !mounted) return;
    await ref.read(appLocaleProvider.notifier).setAppLanguage(selected);
  }

  Future<void> _showReadingLanguageDialog(
    BuildContext context,
    String current,
    UserReadingPreferences? prefs,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => _SelectionDialog<String>(
        title: context.l10n.profilePreferredReadingLanguageTitle,
        options: _supportedLanguages,
        current: current,
        labelFor: (lang) => _languageLabels[lang] ?? lang.toUpperCase(),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedReadingLanguage = selected);
    await ref
        .read(preferencesProvider.notifier)
        .savePreferences(
          defaultReaderMode:
              (_selectedReaderMode ??
                      prefs?.defaultReaderMode ??
                      ReaderMode.vertical)
                  .name,
          defaultLanguage: selected,
        );
  }

  String _contentRatingLabel(BuildContext context, ContentRating rating) {
    return switch (rating) {
      ContentRating.safe => context.l10n.profileContentRatingSafe,
      ContentRating.suggestive => context.l10n.profileContentRatingSuggestive,
      ContentRating.all => context.l10n.profileContentRatingAll,
    };
  }

  Future<void> _showContentRatingDialog(
    BuildContext context,
    ContentRatingResolution resolution,
    UserReadingPreferences? prefs,
  ) async {
    final selected = await showDialog<ContentRating>(
      context: context,
      builder: (ctx) => _SelectionDialog<ContentRating>(
        title: context.l10n.profileContentRatingTitle,
        options: resolution.allowedOptions,
        current: resolution.effectiveRating,
        labelFor: (rating) => _contentRatingLabel(context, rating),
      ),
    );
    if (selected == null || !mounted) return;
    await ref
        .read(preferencesProvider.notifier)
        .savePreferences(
          defaultReaderMode:
              (_selectedReaderMode ??
                      prefs?.defaultReaderMode ??
                      ReaderMode.vertical)
                  .name,
          defaultLanguage:
              _selectedReadingLanguage ??
              prefs?.defaultLanguage ??
              AppConstants.defaultLanguage,
          contentRatingFilter: selected.wireValue,
        );
  }
}

// ── Avatar section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.profile, required this.isLoading});

  final UserProfile? profile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && profile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final initials = _getInitials(profile);
    final name = profile?.displayName;
    final email = profile?.email ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.card,
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (name != null && name.isNotEmpty) ...<Widget>[
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (email.isNotEmpty)
            Text(
              email,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(UserProfile? profile) {
    final name = profile?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final email = profile?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
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

// ── Pref card ─────────────────────────────────────────────────────────────────

class _PrefCard extends StatelessWidget {
  const _PrefCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(children: children),
    );
  }
}

// ── Pref row ──────────────────────────────────────────────────────────────────

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueIsSubtitle = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool valueIsSubtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: valueIsSubtitle
                          ? AppColors.onSurfaceVariant
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

// ── Sign out section ──────────────────────────────────────────────────────────

class _SignOutSection extends ConsumerWidget {
  const _SignOutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final appVersionText = appVersionAsync.maybeWhen(
      data: (info) =>
          context.l10n.profileVersionLabel(info.version, info.buildNumber),
      orElse: () => context.l10n.profileVersionLabel('-', '-'),
    );

    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (!context.mounted) return;
                    AppFeedback.showInfo(
                      context,
                      title: context.l10n.profileSignOutSnackBar,
                    );
                  },
            child: authState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.profileSignOutAction,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appVersionText,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            color: AppColors.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.profileServerConnectionError,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              context.l10n.retryAction,
              style: const TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selection dialog ──────────────────────────────────────────────────────────

class _SelectionDialog<T> extends StatelessWidget {
  const _SelectionDialog({
    required this.title,
    required this.options,
    required this.current,
    required this.labelFor,
  });

  final String title;
  final List<T> options;
  final T current;
  final String Function(T) labelFor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options
                      .map(
                        (option) => ListTile(
                          title: Text(
                            labelFor(option),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                          ),
                          trailing: option == current
                              ? const Icon(
                                  Icons.check,
                                  size: 20,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
