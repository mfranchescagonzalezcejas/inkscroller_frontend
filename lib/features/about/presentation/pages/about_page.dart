import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart' show AppColors;
import '../../../../core/l10n/l10n.dart';

/// About screen — app version, legal disclaimer, and API credits.
///
/// Accessible from Profile → "App information".
/// Contains the legal disclaimer required by MangaDex and MAL/Jikan API ToS.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _packageInfo = info);
    } on Object catch (e, st) {
      debugPrint('[AboutPage] Failed to load package info: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.stage,
      appBar: AppBar(
        backgroundColor: AppColors.stage,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Text(
          l10n.aboutTitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          _AppIdentitySection(packageInfo: _packageInfo),
          const SizedBox(height: 24),
          const _DisclaimerSection(),
          const SizedBox(height: 24),
          const _CreditsSection(),
        ],
      ),
    );
  }
}

// ── App identity ──────────────────────────────────────────────────────────────

class _AppIdentitySection extends StatelessWidget {
  final PackageInfo? packageInfo;

  const _AppIdentitySection({this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final version = packageInfo != null
        ? l10n.aboutVersion(
            packageInfo!.version,
            packageInfo!.buildNumber,
          )
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            version,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aboutAppDescription,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disclaimer section ────────────────────────────────────────────────────────

class _DisclaimerSection extends StatelessWidget {
  const _DisclaimerSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(text: l10n.aboutDisclaimerTitle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DisclaimerItem(
                icon: Icons.no_photography_outlined,
                title: l10n.aboutDisclaimerMangadexTitle,
                body: l10n.aboutDisclaimerMangadexBody(AppConstants.appName),
              ),
              const SizedBox(height: 16),
              _DisclaimerItem(
                icon: Icons.no_photography_outlined,
                title: l10n.aboutDisclaimerMalTitle,
                body: l10n.aboutDisclaimerMalBody(AppConstants.appName),
              ),
              const SizedBox(height: 16),
              _DisclaimerItem(
                icon: Icons.copyright_outlined,
                title: l10n.aboutDisclaimerCopyrightTitle,
                body: l10n.aboutDisclaimerCopyrightBody(AppConstants.appName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Credits section ───────────────────────────────────────────────────────────

class _CreditsSection extends StatelessWidget {
  const _CreditsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(text: l10n.aboutCreditsTitle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: <Widget>[
              _CreditRow(
                icon: Icons.library_books_outlined,
                name: 'MangaDex API',
                description: l10n.aboutCreditMangadexDescription,
                url: 'api.mangadex.org',
              ),
              const Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.api_outlined,
                name: 'Jikan API',
                description: l10n.aboutCreditJikanDescription,
                url: 'api.jikan.moe',
              ),
              const Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.cloud_outlined,
                name: 'Google Cloud Run',
                description: l10n.aboutCreditCloudRunDescription,
                url: 'cloud.google.com',
              ),
              const Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.lock_outlined,
                name: 'Firebase Auth',
                description: l10n.aboutCreditFirebaseDescription,
                url: 'firebase.google.com',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

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

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.primary),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.icon,
    required this.name,
    required this.description,
    required this.url,
  });

  final IconData icon;
  final String name;
  final String description;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            url,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
