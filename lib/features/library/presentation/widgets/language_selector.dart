import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart' show AppColors, AppSpacing;

/// Maps ISO 639-1 language codes to user-facing Spanish names.
///
/// Covers the most common languages found in manga translations.
const _languageNames = <String, String>{
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

/// Returns the user-facing name for a language code (e.g. `'en'` → `'Inglés'`).
///
/// Falls back to the uppercased code when the code is not in the map.
String languageDisplayName(String code) {
  return _languageNames[code] ?? code.toUpperCase();
}

/// Dropdown that lets the reader choose which language to display chapters in.
///
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
            child: isLoading
                ? DropdownButtonFormField<String>(
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
                  )
                : DropdownButtonFormField<String>(
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
                  ),
          ),
        ],
      ),
    );
  }
}
