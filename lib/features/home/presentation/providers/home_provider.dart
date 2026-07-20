import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_locale_provider.dart';
import '../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../preferences/presentation/providers/demographic_resolution_provider.dart';
import '../../../preferences/domain/entities/demographic_resolution.dart';
import '../../../library/domain/usecases/get_manga_list.dart';
import '../../../library/domain/usecases/search_manga.dart';
import '../../../library/presentation/providers/library/library_notifier.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/presentation/providers/library/library_state.dart';
import 'home_classifiers.dart';
import 'home_state.dart';

// ─────────────────────────────────────────────────────────────
// HOME DATA — único LibraryNotifier que posee los datos de Home
// ─────────────────────────────────────────────────────────────

/// Unico proveedor de datos para la pantalla Home.
///
/// Carga el tab "Todo" de inmediato para Hero + Recommended, y en background
/// precarga Popular, Romance y Action para que el cambio de filtro en Discover
/// sea instantáneo.
final homeDataProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final contentResolution = ref.read(contentRatingResolutionProvider);
  final demographicResolution = ref.read(demographicResolutionProvider);
  final locale = ref.read(appLocaleProvider);
  final notifier = LibraryNotifier(
    sl<GetMangaList>(),
    sl<SearchManga>(),
    initialContentRating: contentResolution.effectiveRating.wireValue,
    initialDemographics: demographicResolution.effectiveFilter
        .map((d) => d.toJson())
        .toList(),
    language: locale?.languageCode,
  );

  // Precarga en background: Popular, Romance, Action para Discover.
  // Usa fetchToCacheOnly para NO mutar el state — el Hero no se afecta.
  Future<void>.microtask(() async {
    await notifier.fetchToCacheOnly(mode: LibraryMode.popular);
    if (!notifier.mounted) return;
    await notifier.fetchToCacheOnly(genre: 'romance');
    if (!notifier.mounted) return;
    await notifier.fetchToCacheOnly(genre: 'action');
  });

  // Escucha cambios de content rating — ignora el primer resolve para
  // evitar el doble loadInitial (el constructor ya cargó con los params).
  ref.listen<ContentRatingResolution>(
    contentRatingResolutionProvider,
    (previous, next) {
      if (previous == null) return;
      if (previous.effectiveRating != next.effectiveRating) {
        notifier.refresh(contentRating: next.effectiveRating.wireValue);
      }
    },
  );

  // Escucha cambios de demographic filter — mismo pattern.
  ref.listen<DemographicResolution>(
    demographicResolutionProvider,
    (previous, next) {
      if (previous == null) return;
      if (previous.stableKey != next.stableKey) {
        notifier.refresh(
          demographics: next.effectiveFilter
              .map((d) => d.toJson())
              .toList(),
        );
      }
    },
  );

  return notifier;
});

// ─────────────────────────────────────────────────────────────
// HOME STATE — clasifica los mangas del provider en secciones
// ─────────────────────────────────────────────────────────────

/// Proveedor derivado que particiona los mangas de [homeDataProvider] en
/// secciones para Hero, Recommended, etc.
final homeProvider = Provider<HomeState>((ref) {
  final libraryState = ref.watch(homeDataProvider);
  return HomeClassifier.classify(libraryState.mangas);
});

// ─────────────────────────────────────────────────────────────
// DISCOVER — filtros sobre el mismo homeDataProvider
// ─────────────────────────────────────────────────────────────

/// Filtro activo del Discover section.
enum HomeDiscoverFilter { all, popular, romance, action }

final homeDiscoverFilterProvider =
    StateProvider<HomeDiscoverFilter>((_) => HomeDiscoverFilter.all);

/// Resultados cacheados de Discover para tabs no-All (Popular, Romance, Action).
/// Se llena via [triggerDiscoverFilter] → [fetchToCacheOnly].
final _homeDiscoverResultsProvider = StateProvider<List<Manga>>((ref) => []);

/// Mangas a mostrar en Discover según el filtro activo.
///
/// Para "All" usa los datos del homeDataProvider (All tab).
/// Para Popular/Romance/Action usa los resultados cacheados via fetchToCacheOnly,
/// con fallback a filtrado client-side mientras carga.
final homeDiscoverMangasProvider = Provider<List<Manga>>((ref) {
  final filter = ref.watch(homeDiscoverFilterProvider);
  final cached = ref.watch(_homeDiscoverResultsProvider);
  final mangas = ref.watch(homeDataProvider.select((s) => s.mangas));
  final homeState = ref.watch(homeProvider);

  // Si hay resultados cacheados para este filtro, usarlos
  if (cached.isNotEmpty && filter != HomeDiscoverFilter.all) return cached;

  switch (filter) {
    case HomeDiscoverFilter.popular:
      if (mangas.isNotEmpty) return mangas.take(20).toList();
      return homeState.popular.take(20).toList();

    case HomeDiscoverFilter.romance:
    case HomeDiscoverFilter.action:
      final genre = filter == HomeDiscoverFilter.romance ? 'romance' : 'action';
      return mangas.where((m) =>
          m.genres.any((g) => g.toLowerCase().contains(genre)) ||
          m.demographic?.toLowerCase() == genre).take(20).toList();

    case HomeDiscoverFilter.all:
      if (mangas.isNotEmpty) return mangas.take(20).toList();
      final all = <Manga>[
        ...homeState.popular,
        ...homeState.shounen,
        ...homeState.shoujo,
      ];
      final seen = <String>{};
      return all.where((m) => seen.add(m.id)).take(20).toList();
  }
});

/// Cambia el filtro de Discover y dispara la carga del tab si es necesario.
///
/// No llama a [loadInitial] — usa [fetchToCacheOnly] que no muta el state
/// del notifier, así el Hero/Recommended no se ve afectado.
void triggerDiscoverFilter(WidgetRef ref, HomeDiscoverFilter filter) {
  ref.read(homeDiscoverFilterProvider.notifier).state = filter;

  final notifier = ref.read(homeDataProvider.notifier);

  switch (filter) {
    case HomeDiscoverFilter.popular:
      unawaited(_loadDiscoverTab(ref, notifier.fetchToCacheOnly(mode: LibraryMode.popular)));
    case HomeDiscoverFilter.romance:
      unawaited(_loadDiscoverTab(ref, notifier.fetchToCacheOnly(genre: 'romance')));
    case HomeDiscoverFilter.action:
      unawaited(_loadDiscoverTab(ref, notifier.fetchToCacheOnly(genre: 'action')));
    case HomeDiscoverFilter.all:
      break; // Ya está en state.mangas
  }
}

Future<void> _loadDiscoverTab(
  WidgetRef ref,
  Future<List<Manga>?> loader,
) async {
  final mangas = await loader;
  if (mangas != null && mangas.isNotEmpty) {
    ref.read(_homeDiscoverResultsProvider.notifier).state = mangas.take(20).toList();
  }
}
