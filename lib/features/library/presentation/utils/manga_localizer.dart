import 'package:inkscroller_flutter/l10n/app_localizations.dart';

/// Localizes manga-specific strings (status, genres) using the active locale.
///
/// Falls back to the original English value when no translation is available,
/// so unknown genres from MangaDex still display a readable label.
class MangaLocalizer {
  const MangaLocalizer._();

  /// Returns the localized status label for a given [status] string.
  ///
  /// Known values: "ongoing", "completed", "hiatus", "cancelled".
  /// Falls back to the original string with first-letter uppercase.
  static String localizeStatus(AppLocalizations l10n, String status) {
    return switch (status.toLowerCase()) {
      'ongoing' => l10n.mangaStatusOngoing,
      'completed' => l10n.mangaStatusCompleted,
      'hiatus' => l10n.mangaStatusHiatus,
      'cancelled' => l10n.mangaStatusCancelled,
      _ => _capitalize(status),
    };
  }

  /// Returns the localized label for a single [genre] string.
  ///
  /// Falls back to the original string with first-letter uppercase when no
  /// translation exists for that genre name.
  static String localizeGenre(AppLocalizations l10n, String genre) {
    return switch (genre.toLowerCase()) {
      'action' => l10n.genreAction,
      'adventure' => l10n.genreAdventure,
      'comedy' => l10n.genreComedy,
      'drama' => l10n.genreDrama,
      'fantasy' => l10n.genreFantasy,
      'horror' => l10n.genreHorror,
      'mystery' => l10n.genreMystery,
      'romance' => l10n.genreRomance,
      'sci-fi' || 'scifi' => l10n.genreSciFi,
      'slice of life' || 'slice_of_life' => l10n.genreSliceOfLife,
      'sports' => l10n.genreSports,
      'thriller' => l10n.genreThriller,
      'supernatural' => l10n.genreSupernatural,
      _ => _capitalize(genre),
    };
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
