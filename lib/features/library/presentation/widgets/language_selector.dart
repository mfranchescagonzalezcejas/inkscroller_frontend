import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart' show AppColors, AppSpacing;

/// Maps ISO 639-1 language codes to user-facing Spanish names.
///
/// Covers the most common languages found in manga translations.
const _languageNamesEs = <String, String>{
  'en': 'Inglés',
  'ja': 'Japonés',
  'ko': 'Coreano',
  'zh': 'Chino',
  'zh-hk': 'Chino (HK)',
  'es': 'Español',
  'es-la': 'Español (LATAM)',
  'fr': 'Francés',
  'pt': 'Portugués',
  'pt-br': 'Portugués (BR)',
  'id': 'Indonesio',
  'eu': 'Euskera',
  'vi': 'Vietnamita',
  'th': 'Tailandés',
  'ru': 'Ruso',
  'de': 'Alemán',
  'it': 'Italiano',
  'ar': 'Árabe',
  'pl': 'Polaco',
  'nl': 'Neerlandés',
  'sv': 'Sueco',
  'tr': 'Turco',
  'ro': 'Rumano',
  'uk': 'Ucraniano',
  'cs': 'Checo',
  'el': 'Griego',
  'hu': 'Húngaro',
  'da': 'Danés',
  'fi': 'Finlandés',
  'nb': 'Noruego',
  'ms': 'Malayo',
  'tl': 'Tagalo',
  'mn': 'Mongol',
  'my': 'Birmano',
  'bn': 'Bengalí',
  'hi': 'Hindi',
  'ne': 'Nepalí',
  'sr': 'Serbio',
  'hr': 'Croata',
  'he': 'Hebreo',
  'fa': 'Persa',
  'bg': 'Búlgaro',
  'ca': 'Catalán',
  'ka': 'Georgiano',
  'lt': 'Lituano',
  'lv': 'Letón',
  'et': 'Estonio',
  'sk': 'Eslovaco',
  'sl': 'Esloveno',
};

/// English-language names for the same codes.
const _languageNamesEn = <String, String>{
  'en': 'English',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
  'zh-hk': 'Chinese (HK)',
  'es': 'Spanish',
  'es-la': 'Spanish (LATAM)',
  'fr': 'French',
  'pt': 'Portuguese',
  'pt-br': 'Portuguese (BR)',
  'id': 'Indonesian',
  'eu': 'Basque',
  'vi': 'Vietnamese',
  'th': 'Thai',
  'ru': 'Russian',
  'de': 'German',
  'it': 'Italian',
  'ar': 'Arabic',
  'pl': 'Polish',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'tr': 'Turkish',
  'ro': 'Romanian',
  'uk': 'Ukrainian',
  'cs': 'Czech',
  'el': 'Greek',
  'hu': 'Hungarian',
  'da': 'Danish',
  'fi': 'Finnish',
  'nb': 'Norwegian',
  'ms': 'Malay',
  'tl': 'Tagalog',
  'mn': 'Mongolian',
  'my': 'Burmese',
  'bn': 'Bengali',
  'hi': 'Hindi',
  'ne': 'Nepali',
  'sr': 'Serbian',
  'hr': 'Croatian',
  'he': 'Hebrew',
  'fa': 'Persian',
  'bg': 'Bulgarian',
  'ca': 'Catalan',
  'ka': 'Georgian',
  'lt': 'Lithuanian',
  'lv': 'Latvian',
  'et': 'Estonian',
  'sk': 'Slovak',
  'sl': 'Slovenian',
};

/// Returns the user-facing name for a language code (e.g. `'en'` → `'Inglés'`)
/// localized according to the active app [locale].
///
/// Falls back to the uppercased code when the code is not in the map.
String languageDisplayName(String code, [Locale? locale]) {
  final map = locale?.languageCode == 'en' ? _languageNamesEn : _languageNamesEs;
  return map[code] ?? code.toUpperCase();
}

/// Dropdown that lets the reader choose which language to display chapters in.
///
/// When there is only one available language, renders it as a plain label
/// instead of a dropdown — no need to select when there's no choice.
/// Shows a loading indicator while [isLoading] is true. Emits the selected
/// language code via [onLanguageChanged].
class LanguageSelector extends ConsumerWidget {
  final List<String> availableLanguages;
  final String selectedLanguage;
  final bool isLoading;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.availableLanguages,
    required this.selectedLanguage,
    this.isLoading = false,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.translate,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return DropdownButtonFormField<String>(
        disabledHint: const Text('Cargando…'),
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(),
          labelText: 'Idioma',
        ),
      );
    }

    // No languages available → hide the entire selector.
    if (availableLanguages.isEmpty) return const SizedBox.shrink();

    // Single language: show as plain text, no dropdown needed.
    if (availableLanguages.length == 1) {
      return Text(
        languageDisplayName(availableLanguages.first),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Multiple languages: show dropdown.
    return DropdownButtonFormField<String>(
      initialValue: availableLanguages.contains(selectedLanguage)
          ? selectedLanguage
          : availableLanguages.first,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(),
        labelText: 'Idioma',
      ),
      items: availableLanguages.map((code) {
        return DropdownMenuItem<String>(
          value: code,
          child: Text(languageDisplayName(code)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onLanguageChanged(value);
      },
    );
  }
}
