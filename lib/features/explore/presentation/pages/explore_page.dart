import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/connectivity_status_provider.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_tab_bar.dart';
import '../../../../core/widgets/inkscroller_logo_loader.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../library/presentation/constants/library_ui_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/presentation/providers/library/library_notifier.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../../../library/presentation/providers/library/library_state.dart';
import '../../../library/presentation/widgets/manga_tile.dart';
import '../../../library/presentation/widgets/library_shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Explore page — full catalogue browsing with search and genre filters.
///
/// Matches the Explore Screen in the Pencil design (node rMA5n).
/// Structure: TopBar · Header · SearchBar · GenreTabs · MasonryGrid
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  bool _canTriggerLoadMore = true;
  int _selectedGenreIndex = 0; // 0=All, 1=Popular, 2=Romance, 3=Action

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(libraryProvider);
    if (state.isSearching || state.query.trim().isNotEmpty) return;
    if (!_scrollController.hasClients) return;

    final thresholdReached =
        _scrollController.position.extentAfter <=
        AppConstants.mangaListPrefetchExtent;

    if (thresholdReached && !state.isLoadingMore && _canTriggerLoadMore) {
      _canTriggerLoadMore = false;
      ref.read(libraryProvider.notifier).loadMore();
    }
    if (!thresholdReached) _canTriggerLoadMore = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final authState = ref.watch(authProvider);
    final bool isOffline = ref
        .watch(connectivityStatusProvider)
        .maybeWhen(data: (isOnline) => !isOnline, orElse: () => false);

    // Keep TextField in sync with state
    if (_searchController.text != state.query) {
      _searchController.value = _searchController.value.copyWith(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      appBar: AppTopBar(authState: authState),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOffline) const OfflineBanner(),
          _ExploreHeader(),
          _ExploreSearchBar(
            controller: _searchController,
            query: state.query,
            onChanged: (v) => ref.read(libraryProvider.notifier).setQuery(v),
            onClear: () {
              _searchController.clear();
              ref.read(libraryProvider.notifier).clearSearch();
            },
          ),
          if (state.query.trim().isEmpty)
            _GenreTabs(
              selectedIndex: _selectedGenreIndex,
              onSelected: (i) {
                setState(() => _selectedGenreIndex = i);
                if (i == 1) {
                  ref
                      .read(libraryProvider.notifier)
                      .loadInitial(mode: LibraryMode.popular);
                } else {
                  const genres = [null, 'romance', 'action'];
                  final genre = i > 1 ? genres[i - 1] : null;
                  ref.read(libraryProvider.notifier).setGenre(genre);
                }
              },
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
              child: _ExploreGrid(state: state, controller: _scrollController),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TopBar ────────────────────────────────────────────────────────────────────

// ── Header ────────────────────────────────────────────────────────────────────

class _ExploreHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.exploreTitle,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.exploreSubtitle,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SearchBar ─────────────────────────────────────────────────────────────────

class _ExploreSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ExploreSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // color-surface-highest from design
          color: const Color(0xFF181B1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.searchMangaHint,
                  hintStyle: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: AppColors.outline,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onChanged,
              ),
            ),
            if (query.trim().isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.clear,
                  color: AppColors.outline,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── GenreTabs ─────────────────────────────────────────────────────────────────

class _GenreTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _GenreTabs({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return CatalogTabBar(
      labels: [
        context.l10n.genreAll,
        context.l10n.genrePopular,
        context.l10n.genreRomance,
        context.l10n.genreAction,
      ],
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  final LibraryState state;
  final ScrollController controller;

  const _ExploreGrid({required this.state, required this.controller});

  // Server-side filtering already applied via libraryProvider.setGenre().
  // Just return the manga list directly - no local filtering needed.
  List<Manga> get _filteredMangas => state.mangas;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.mangas.isEmpty) {
      return const LibraryShimmer();
    }

    if (state.isSearching && state.mangas.isEmpty) {
      return const Center(child: InkScrollerLogoLoader());
    }

    final mangas = _filteredMangas;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSafePadding =
        LibraryUiConstants.cardGridBottomPadding + bottomInset;

    if (mangas.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Text(
                state.query.trim().isEmpty
                    ? context.l10n.noMangasAvailable
                    : context.l10n.noSearchResults(state.query),
                style: AppTypography.bodyStyle.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final int crossAxisCount;
        if (width >= LibraryUiConstants.largeGridBreakpoint) {
          crossAxisCount = LibraryUiConstants.largeGridColumns;
        } else if (width >= LibraryUiConstants.mediumGridBreakpoint) {
          crossAxisCount = LibraryUiConstants.mediumGridColumns;
        } else {
          crossAxisCount = LibraryUiConstants.smallGridColumns;
        }

        final showBottomLoader = state.isLoadingMore && !state.isSearching;
        final showEndReached =
            !state.isSearching && !state.isLoadingMore && !state.hasMore;

        return MasonryGridView.builder(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSafePadding),
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          mainAxisSpacing: LibraryUiConstants.gridMainSpacing,
          crossAxisSpacing: LibraryUiConstants.gridCrossSpacing,
          itemCount:
              mangas.length +
              (showBottomLoader ? 1 : 0) +
              (showEndReached ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= mangas.length) {
              if (showBottomLoader && index == mangas.length) {
                return const Center(child: InkScrollerLogoLoader());
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: Text(context.l10n.noMoreMangaToLoad)),
              );
            }

            return MangaTile(manga: mangas[index]);
          },
        );
      },
    );
  }
}
