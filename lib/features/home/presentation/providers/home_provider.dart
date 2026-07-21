import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../preferences/presentation/providers/content_rating_resolution_provider.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../../preferences/presentation/providers/preferences_state.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../profile/presentation/providers/user_profile_state.dart';
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

const List<String> _guestHomeDemographics = <String>['shounen', 'shoujo'];

/// Unico proveedor de datos para la pantalla Home.
///
/// Waits for the resolved session filters before loading its catalog.
final homeDataProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  final locale = ref.read(appLocaleProvider);
  final notifier = LibraryNotifier(
    sl<GetMangaList>(),
    sl<SearchManga>(),
    language: locale?.languageCode,
    skipInitialLoad: true,
  );

  var started = false;
  var authResolved = false;
  String? activeFilterKey;

  void loadForResolvedFilters() {
    final authState = ref.read(authProvider);
    if (!authResolved && authState.user == null) return;

    String contentRating;
    List<String> demographics;

    if (authState.user == null || !authState.user!.isEmailVerified) {
      contentRating = 'safe';
      demographics = _guestHomeDemographics;
    } else {
      final preferencesState = ref.read(preferencesProvider);
      final profileState = ref.read(userProfileProvider);

      // Esperar preferencias Y perfil. Sin birthDate (perfil), la resolución
      // trata age=null como <16 y solo permite safe, ignorando stored=all.
      if (preferencesState.isLoading || profileState.isLoading) return;
      if (preferencesState.preferences == null) {
        if (preferencesState.error != null) {
          contentRating = 'safe';
          demographics = _guestHomeDemographics;
        } else {
          return;
        }
      } else if (profileState.profile == null) {
        if (profileState.error != null) {
          contentRating = 'safe';
          demographics = _guestHomeDemographics;
        } else {
          return;
        }
      } else {
        contentRating = ref
            .read(contentRatingResolutionProvider)
            .effectiveRating
            .wireValue;
        final storedDemos = preferencesState.preferences!.demographicFilter;
        demographics =
            storedDemos
                ?.map((d) => d.toJson())
                .where((d) => d != 'unspecified')
                .toList() ??
            [];
      }
    }

    final filterKey = '$contentRating:${demographics.join(',')}';
    if (filterKey == activeFilterKey) return;
    activeFilterKey = filterKey;

    if (started) {
      notifier.refresh(
        contentRating: contentRating,
        demographics: demographics,
      );
      return;
    }

    started = true;
    unawaited(
      notifier
          .loadInitial(contentRating: contentRating, demographics: demographics)
          .then((_) async {
            // Ponytail: secuencial evita que Cloud Run dispare instancias
            // frías para requests paralelos. La instancia ya está caliente
            // del catálogo inicial, así que cada preload es ~0.2s.
            await notifier.fetchToCacheOnly(mode: LibraryMode.popular);
            await notifier.fetchToCacheOnly(genre: 'romance');
            await notifier.fetchToCacheOnly(genre: 'action');
          }),
    );
  }

  // ── Esperar a que Firebase confirme el estado de auth ─────
  // En el factory, authProvider todavía tiene el estado inicial
  // (user: null) aunque el usuario tenga sesión activa. Escuchamos
  // el primer cambio para decidir invitado vs verificado.
  ref.listen<AuthState>(authProvider, (previous, next) {
    authResolved = true;

    loadForResolvedFilters();
  });

  ref.listen<PreferencesState>(
    preferencesProvider,
    (_, __) => loadForResolvedFilters(),
  );
  ref.listen<UserProfileState>(
    userProfileProvider,
    (_, __) => loadForResolvedFilters(),
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

final homeDiscoverFilterProvider = StateProvider<HomeDiscoverFilter>(
  (_) => HomeDiscoverFilter.all,
);

/// Resultados cacheados de Discover para tabs no-All (Popular, Romance, Action).
/// Se llena via [triggerDiscoverFilter] → [fetchToCacheOnly].
final _homeDiscoverResultsProvider =
    StateProvider<Map<HomeDiscoverFilter, List<Manga>>>((ref) => {});

/// Mangas a mostrar en Discover según el filtro activo.
///
/// Para "All" usa los datos del homeDataProvider (All tab).
/// Para Popular/Romance/Action usa los resultados cacheados via fetchToCacheOnly,
/// con fallback a filtrado client-side mientras carga.
final homeDiscoverMangasProvider = Provider<List<Manga>>((ref) {
  final filter = ref.watch(homeDiscoverFilterProvider);
  final cached = ref.watch(_homeDiscoverResultsProvider)[filter];
  final mangas = ref.watch(homeDataProvider.select((s) => s.mangas));
  final homeState = ref.watch(homeProvider);

  // Si hay resultados cacheados para este filtro, usarlos
  if (cached != null && cached.isNotEmpty && filter != HomeDiscoverFilter.all) {
    return cached;
  }

  switch (filter) {
    case HomeDiscoverFilter.popular:
      if (mangas.isNotEmpty) return mangas.take(20).toList();
      return homeState.popular.take(20).toList();

    case HomeDiscoverFilter.romance:
    case HomeDiscoverFilter.action:
      final genre = filter == HomeDiscoverFilter.romance ? 'romance' : 'action';
      return mangas
          .where(
            (m) =>
                m.genres.any((g) => g.toLowerCase().contains(genre)) ||
                m.demographic?.toLowerCase() == genre,
          )
          .take(20)
          .toList();

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
      unawaited(
        _loadDiscoverTab(
          ref,
          HomeDiscoverFilter.popular,
          notifier.fetchToCacheOnly(mode: LibraryMode.popular),
        ),
      );
    case HomeDiscoverFilter.romance:
      unawaited(
        _loadDiscoverTab(
          ref,
          HomeDiscoverFilter.romance,
          notifier.fetchToCacheOnly(genre: 'romance'),
        ),
      );
    case HomeDiscoverFilter.action:
      unawaited(
        _loadDiscoverTab(
          ref,
          HomeDiscoverFilter.action,
          notifier.fetchToCacheOnly(genre: 'action'),
        ),
      );
    case HomeDiscoverFilter.all:
      break; // Ya está en state.mangas
  }
}

Future<void> _loadDiscoverTab(
  WidgetRef ref,
  HomeDiscoverFilter filter,
  Future<List<Manga>?> loader,
) async {
  final mangas = await loader;
  if (mangas != null && mangas.isNotEmpty) {
    try {
      // Ponytail: if the widget was already disposed, ref.read throws.
      // Catch and ignore instead of crashing the app.
      final cache = ref.read(_homeDiscoverResultsProvider);
      ref.read(_homeDiscoverResultsProvider.notifier).state = {
        ...cache,
        filter: mangas.take(20).toList(),
      };
    } on Object catch (_) {
      // Widget disposed before preload completed, results can't be delivered.
    }
  }
}
