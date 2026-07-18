import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_version_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart'
    show AppColors, AppTypography;
import '../../../../core/design/app_spacing.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/app_locale_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../library/domain/entities/reader_mode.dart';
import '../../../preferences/domain/entities/content_rating.dart';
import '../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../preferences/domain/entities/user_reading_preferences.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../../preferences/presentation/providers/preferences_state.dart';
import '../../../preferences/presentation/providers/demographic_resolution_provider.dart';
import '../../../preferences/domain/entities/demographic_resolution.dart';
import '../../../library/domain/entities/manga_tags.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../providers/user_profile_state.dart';
import '../widgets/demographic_selection_dialog.dart';

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
  List<MangaDemographic>? _selectedDemographics;

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
    final demographicResolution = ref.watch(demographicResolutionProvider);

    // Skip profile loading for unverified users — the backend returns 403.
    // But always load preferences (guests need them too).
    final isGuest = authState.user == null;
    final shouldLoadProfile =
        authState.user != null && authState.needsEmailVerification == false;
    final shouldLoadPreferences = !preferencesState.isLoading &&
        preferencesState.preferences == null;

    if (shouldLoadProfile && !_profileRequested) {
      _profileRequested = true;
      Future<void>.microtask(
        () => ref.read(userProfileProvider.notifier).loadProfile(),
      );
    }

    if (shouldLoadPreferences && !_preferencesRequested) {
      _preferencesRequested = true;
      Future<void>.microtask(
        () => ref.read(preferencesProvider.notifier).loadPreferences(),
      );
    }

    if (isGuest) {
      _profileRequested = false;
      _preferencesRequested = false;
      _selectedReaderMode = null;
      _selectedReadingLanguage = null;
      _selectedDemographics = null;
    }

    ref.listen(preferencesProvider, (previous, next) {
      if (next.preferences != null &&
          next.preferences != previous?.preferences) {
        setState(() {
          _selectedReaderMode = next.preferences?.defaultReaderMode;
          _selectedReadingLanguage = next.preferences?.defaultLanguage;
          _selectedDemographics = next.preferences?.demographicFilter;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.stage,
      appBar: AppTopBar(
        authState: authState,
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
        child: isGuest
            ? _buildGuestView(
                context,
                preferencesState,
              )
            : _buildAuthenticatedView(
                context,
                authState,
                profileState,
                preferencesState,
                contentRatingResolution,
                demographicResolution,
              ),
      ),
    );
  }

  Widget _buildGuestView(
    BuildContext context,
    PreferencesState preferencesState,
  ) {
    final prefs = preferencesState.preferences;
    final appLocale = ref.watch(appLocaleProvider);
    final effectiveReaderMode =
        _selectedReaderMode ?? prefs?.defaultReaderMode ?? ReaderMode.vertical;
    final effectiveReadingLanguage =
        _selectedReadingLanguage ?? prefs?.defaultLanguage ?? AppConstants.defaultLanguage;
    final effectiveAppLanguage =
        appLocale?.languageCode ?? Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: <Widget>[
        // ── Guest header ──────────────────────────────────────────────────
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
            ],
          ),
        ),

        // ── Preferences section ───────────────────────────────────────────
        const SizedBox(height: 20),
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
          ],
        ),

        // ── Sign In button ────────────────────────────────────────────────
        const SizedBox(height: 24),
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
            child: Text(context.l10n.authSignInButton),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context,
    AuthState authState,
    UserProfileState profileState,
    PreferencesState preferencesState,
    ContentRatingResolution contentRatingResolution,
    DemographicResolution demographicResolution,
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

        // ── Email verification section ────────────────────────────────────
        if (authState.needsEmailVerification) ...[
          const SizedBox(height: 20),
          _EmailVerificationSection(
            onResend: () => ref.read(authProvider.notifier).sendVerificationEmail(),
            isLoading: authState.isLoading,
          ),
        ],

        // ── Account section ─────────────────────────────────────────────
        const SizedBox(height: 20),
        _SectionLabel(label: context.l10n.accountSectionLabel.toUpperCase()),
        const SizedBox(height: 8),
        _PrefCard(
          children: <Widget>[
            _PrefRow(
              icon: Icons.person_outline,
              iconColor: AppColors.primary,
              title: context.l10n.authChangeUsernameOption,
              value: profile?.username ?? '',
              onTap: () {
                if (profile?.birthDate == null) {
                  AppFeedback.showError(
                    context,
                    title: context.l10n.profileBirthDateRequired,
                  );
                  return;
                }
                _showChangeUsernameDialog(context, ref, profile!);
              },
            ),
          ],
        ),

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
            _PrefRow(
              icon: Icons.category_outlined,
              iconColor: AppColors.primary,
              title: context.l10n.profileDemographicTitle,
              value: _demographicCountLabel(
                context,
                DemographicResolution.selectionForDialog(
                  stored: _selectedDemographics,
                  resolution: demographicResolution,
                ),
              ),
              onTap: preferencesState.isLoading
                  ? null
                  : () => _showDemographicDialog(
                        context, demographicResolution, prefs,
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

  String _demographicCountLabel(
    BuildContext context,
    List<MangaDemographic> selected,
  ) {
    return context.l10n.profileDemographicCount(selected.length);
  }

  Future<void> _showDemographicDialog(
    BuildContext context,
    DemographicResolution resolution,
    UserReadingPreferences? prefs,
  ) async {
    final current = DemographicResolution.selectionForDialog(
      stored: _selectedDemographics ?? prefs?.demographicFilter,
      resolution: resolution,
    );
    final selected = await showDialog<Set<MangaDemographic>>(
      context: context,
      builder: (ctx) => DemographicSelectionDialog(
        options: resolution.allowedOptions,
        current: current.toSet(),
        labelFor: (demo) => _demographicLabel(context, demo),
        emptySelectionMessage:
            context.l10n.profileDemographicSelectionRequired,
      ),
    );
    if (selected == null || !context.mounted) return;
    final demographics = selected.toList();
    if (!DemographicResolution.isValidSelection(demographics)) {
      AppFeedback.showError(
        context,
        title: context.l10n.profileDemographicSelectionRequired,
      );
      return;
    }
    setState(() => _selectedDemographics = demographics);
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
          contentRatingFilter: prefs?.contentRatingFilter?.wireValue,
          demographicFilter: demographics.map((d) => d.toJson()).toList(),
        );
  }

  String _demographicLabel(BuildContext context, MangaDemographic demo) {
    return switch (demo) {
      MangaDemographic.shounen => context.l10n.demographicShounen,
      MangaDemographic.shoujo => context.l10n.demographicShoujo,
      MangaDemographic.seinen => context.l10n.demographicSeinen,
      MangaDemographic.josei => context.l10n.demographicJosei,
      MangaDemographic.unspecified => context.l10n.demographicUnspecified,
    };
  }

  String _contentRatingLabel(BuildContext context, ContentRating rating) {
    return switch (rating) {
      ContentRating.safe => context.l10n.profileContentRatingSafe,
      ContentRating.suggestive => context.l10n.profileContentRatingSuggestive,
      ContentRating.all => context.l10n.profileContentRatingAll,
    };
  }

  Future<void> _showChangeUsernameDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.username);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(
          context.l10n.authChangeUsernameTitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              labelText: context.l10n.authUsernameLabel,
              labelStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.onSurfaceVariant,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n.authUsernameRequired;
              }
              final trimmed = value.trim();
              if (trimmed.length < 3 || trimmed.length > 30) {
                return context.l10n.authUsernameInvalid;
              }
              if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(trimmed)) {
                return context.l10n.authUsernameInvalid;
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.l10n.dialogCancel,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.l10n.authChangeUsernameSave),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final newUsername = controller.text.trim();
    // ponytail: birthDate is guaranteed non-null by the guard before opening
    // the dialog — if it were null the user gets a profile-completion prompt
    // instead.
    final birthDate = profile.birthDate!;
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(username: newUsername, birthDate: birthDate);
    if (!context.mounted) return;
    final profileState = ref.read(userProfileProvider);
    if (profileState.error != null) {
      AppFeedback.showError(context, title: profileState.error!);
    } else {
      AppFeedback.showSuccess(
        context,
        title: context.l10n.authChangeUsernameSuccess,
      );
    }
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
    final name = profile?.username;
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
    // Prefer username → displayName → email for avatar initials.
    final name = profile?.username ?? profile?.displayName;
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

// ── Email verification section ─────────────────────────────────────────────────

class _EmailVerificationSection extends ConsumerWidget {
  const _EmailVerificationSection({
    required this.onResend,
    required this.isLoading,
  });

  final VoidCallback onResend;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.authVerifyInProfile,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.authVerifyInProfileSubtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onResend,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.authVerifyEmailResend,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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

// ── Multi-select dialog ──────────────────────────────────────────────────────

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.options,
    required this.current,
    required this.labelFor,
  });

  final String title;
  final List<T> options;
  final Set<T> current;
  final String Function(T) labelFor;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.current);
  }

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
                widget.title,
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
                  children: widget.options
                      .map(
                        (option) => CheckboxListTile(
                          value: _selected.contains(option),
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selected.add(option);
                              } else {
                                _selected.remove(option);
                              }
                            });
                          },
                          title: Text(
                            widget.labelFor(option),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.deleteAccountCancelAction,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('OK'),
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
