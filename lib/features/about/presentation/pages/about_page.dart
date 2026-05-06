import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart' show AppColors;

/// About screen — app version, legal disclaimer, and API credits.
///
/// Accessible from Profile → "Información de la app".
/// Contains the legal disclaimer required by MangaDex and MAL/Jikan API ToS.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stage,
      appBar: AppBar(
        backgroundColor: AppColors.stage,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: const Text(
          'Sobre la app',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: const <Widget>[
          _AppIdentitySection(),
          SizedBox(height: 24),
          _DisclaimerSection(),
          SizedBox(height: 24),
          _CreditsSection(),
        ],
      ),
    );
  }
}

// ── App identity ──────────────────────────────────────────────────────────────

class _AppIdentitySection extends StatelessWidget {
  const _AppIdentitySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: <Widget>[
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Versión 0.4.2 (Build 20)',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Manga reader personal — open source',
            style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(text: 'AVISO LEGAL'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DisclaimerItem(
                icon: Icons.no_photography_outlined,
                title: 'Sin afiliación a MangaDex',
                body:
                    '${AppConstants.appName} no está afiliado, asociado, autorizado ni respaldado por MangaDex. '
                    'El nombre "MangaDex" y su logotipo son marcas de sus respectivos propietarios. '
                    'El uso de la API pública de MangaDex se realiza bajo sus Términos de Uso.',
              ),
              SizedBox(height: 16),
              _DisclaimerItem(
                icon: Icons.no_photography_outlined,
                title: 'Sin afiliación a MyAnimeList',
                body:
                    '${AppConstants.appName} no está afiliado, asociado, autorizado ni respaldado por MyAnimeList (MAL). '
                    'El nombre "MyAnimeList" y su logotipo son marcas de sus respectivos propietarios. '
                    'Los metadatos adicionales se obtienen a través de la API pública de Jikan, '
                    'una API no oficial de MAL, y se usan únicamente con fines informativos.',
              ),
              SizedBox(height: 16),
              _DisclaimerItem(
                icon: Icons.copyright_outlined,
                title: 'Derechos de autor del contenido',
                body:
                    'Todo el contenido de manga (imágenes, capítulos, portadas) '
                    'pertenece a sus respectivos autores y editores. '
                    '${AppConstants.appName} no almacena ni redistribuye contenido con derechos de autor. '
                    'Esta app solo consume datos de APIs públicas de terceros.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(text: 'CRÉDITOS Y APIs'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Column(
            children: <Widget>[
              _CreditRow(
                icon: Icons.library_books_outlined,
                name: 'MangaDex API',
                description: 'Catálogo, capítulos y portadas',
                url: 'api.mangadex.org',
              ),
              Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.api_outlined,
                name: 'Jikan API',
                description: 'Metadatos adicionales (MAL)',
                url: 'api.jikan.moe',
              ),
              Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.cloud_outlined,
                name: 'Google Cloud Run',
                description: 'Infraestructura de backend',
                url: 'cloud.google.com',
              ),
              Divider(color: AppColors.outlineVariant, height: 1),
              _CreditRow(
                icon: Icons.lock_outlined,
                name: 'Firebase Auth',
                description: 'Autenticación de usuarios',
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
