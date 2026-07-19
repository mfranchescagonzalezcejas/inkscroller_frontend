import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:inkscroller_flutter/core/design/design_tokens.dart';
import 'package:inkscroller_flutter/core/feedback/app_feedback.dart';
import 'package:inkscroller_flutter/core/l10n/l10n.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/core/widgets/catalog_tab_bar.dart';
import 'package:inkscroller_flutter/core/widgets/offline_banner.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/presentation/constants/library_ui_constants.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/manga_tile.dart';

/// Local-first user library page.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOffline = ref
        .watch(connectivityStatusProvider)
        .maybeWhen(data: (isOnline) => !isOnline, orElse: () => false);

    final bool isSyncing = ref.watch(userLibrarySyncingProvider);

    final Map<String, UserLibraryEntry> entries = ref.watch(
      userLibraryProvider,
    );
    final List<UserLibraryEntry> libraryEntries =
        entries.values.where((entry) => entry.isInLibrary).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final String query = _searchController.text.trim().toLowerCase();
    final List<UserLibraryEntry> filteredEntries = libraryEntries
        .where((entry) => _matchesTab(entry))
        .where(
          (entry) =>
              query.isEmpty || entry.manga.title.toLowerCase().contains(query),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isOffline) const OfflineBanner(),
          if (isSyncing)
            LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: AppColors.primary.withValues(alpha: 0.5),
              minHeight: 2,
            ),
          _LibraryHeader(mangaCount: libraryEntries.length),
          _LibrarySearchBar(
            controller: _searchController,
            query: _searchController.text,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          _LibraryTabs(
            selectedIndex: _selectedTabIndex,
            onSelected: (index) {
              setState(() => _selectedTabIndex = index);
            },
          ),
          Expanded(
            child: _LibraryBody(
              allEntries: libraryEntries,
              filteredEntries: filteredEntries,
              selectedTabIndex: _selectedTabIndex,
              query: _searchController.text.trim(),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesTab(UserLibraryEntry entry) {
    switch (_selectedTabIndex) {
      case 1:
        return entry.status == UserLibraryStatus.reading;
      case 2:
        return entry.status == UserLibraryStatus.completed;
      case 3:
        return entry.status == UserLibraryStatus.paused;
      default:
        return true;
    }
  }
}

class _LibraryHeader extends StatelessWidget {
  final int mangaCount;

  const _LibraryHeader({required this.mangaCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.libraryTitle,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.libraryCollectionsCount(mangaCount),
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

class _LibrarySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _LibrarySearchBar({
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
          color: AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
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

class _LibraryTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _LibraryTabs({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return CatalogTabBar(
      labels: <String>[
        context.l10n.libraryTabAll,
        context.l10n.libraryTabReading,
        context.l10n.libraryTabCompleted,
        context.l10n.libraryTabOnHold,
      ],
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}

class _LibraryBody extends StatefulWidget {
  final List<UserLibraryEntry> allEntries;
  final List<UserLibraryEntry> filteredEntries;
  final int selectedTabIndex;
  final String query;

  const _LibraryBody({
    required this.allEntries,
    required this.filteredEntries,
    required this.selectedTabIndex,
    required this.query,
  });

  @override
  State<_LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends State<_LibraryBody> {
  static const int _pageSize = 20;

  late final ScrollController _scrollController;
  int _displayLimit = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_LibraryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when the active filter or search query changes.
    if (oldWidget.selectedTabIndex != widget.selectedTabIndex ||
        oldWidget.query != widget.query) {
      setState(() => _displayLimit = _pageSize);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      _loadMore();
    }
  }

  void _loadMore() {
    final int total = widget.filteredEntries.length;
    if (_displayLimit < total) {
      setState(() {
        _displayLimit = (_displayLimit + _pageSize).clamp(0, total);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allEntries.isEmpty) {
      return _LibraryEmptyMessage(message: context.l10n.libraryEmpty);
    }

    if (widget.filteredEntries.isEmpty) {
      final String message = widget.query.isNotEmpty
          ? context.l10n.noSearchResults(widget.query)
          : context.l10n.libraryEmptyTab;

      return _LibraryEmptyMessage(message: message);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final _LibraryGridConfig gridConfig = _resolveGridConfig(
          constraints.maxWidth,
        );

        final double bottomInset = MediaQuery.of(context).padding.bottom;
        final double bottomSafePadding =
            LibraryUiConstants.cardGridBottomPadding + bottomInset;

        final int displayCount =
            _displayLimit.clamp(0, widget.filteredEntries.length);
        final bool hasMore = displayCount < widget.filteredEntries.length;

        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LibraryUiConstants.horizontalPadding,
                0,
                LibraryUiConstants.horizontalPadding,
                0,
              ),
                sliver: SliverMasonryGrid(
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridConfig.crossAxisCount,
                  ),
                mainAxisSpacing: LibraryUiConstants.gridMainSpacing,
                crossAxisSpacing: LibraryUiConstants.gridCrossSpacing,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final UserLibraryEntry entry =
                        widget.filteredEntries[index];
                    return _LibraryEntryCard(entry: entry);
                  },
                  childCount: displayCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: hasMore
                    ? LibraryUiConstants.cardGridBottomPadding
                    : bottomSafePadding,
                child: hasMore
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

_LibraryGridConfig _resolveGridConfig(double width) {
  if (width >= LibraryUiConstants.largeGridBreakpoint) {
    return const _LibraryGridConfig(LibraryUiConstants.largeGridColumns);
  }

  if (width >= LibraryUiConstants.mediumGridBreakpoint) {
    return const _LibraryGridConfig(LibraryUiConstants.mediumGridColumns);
  }

  return const _LibraryGridConfig(LibraryUiConstants.smallGridColumns);
}

class _LibraryGridConfig {
  final int crossAxisCount;

  const _LibraryGridConfig(this.crossAxisCount);
}

class _LibraryEmptyMessage extends StatelessWidget {
  final String message;

  const _LibraryEmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _LibraryEntryCard extends ConsumerWidget {
  final UserLibraryEntry entry;

  const _LibraryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      readingProgressProvider.select((value) => value[entry.manga.id]),
    );

    return Stack(
      children: <Widget>[
        MangaTile(
          manga: entry.manga,
          readChaptersCount: progress?.readChaptersCount,
          totalChaptersCount: (progress?.hasKnownTotal ?? false)
              ? progress?.totalChaptersCount
              : null,
        ),
        Positioned(
          top: 6,
          left: 6,
          child: PopupMenuButton<_LibraryEntryAction>(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.cardHigh,
              child: Icon(
                Icons.more_horiz,
                size: 16,
                color: AppColors.onSurface,
              ),
            ),
            color: AppColors.stage,
            onSelected: (action) async {
              switch (action) {
                case _LibraryEntryAction.reading:
                  await ref
                      .read(userLibraryProvider.notifier)
                      .setStatus(entry.manga.id, UserLibraryStatus.reading);
                  if (!context.mounted) return;
                  AppFeedback.showInfo(
                    context,
                    title: context.l10n.libraryStatusUpdated,
                  );
                case _LibraryEntryAction.completed:
                  await ref
                      .read(userLibraryProvider.notifier)
                      .setStatus(entry.manga.id, UserLibraryStatus.completed);
                  if (!context.mounted) return;
                  AppFeedback.showInfo(
                    context,
                    title: context.l10n.libraryStatusUpdated,
                  );
                case _LibraryEntryAction.paused:
                  await ref
                      .read(userLibraryProvider.notifier)
                      .setStatus(entry.manga.id, UserLibraryStatus.paused);
                  if (!context.mounted) return;
                  AppFeedback.showInfo(
                    context,
                    title: context.l10n.libraryStatusUpdated,
                  );
                case _LibraryEntryAction.remove:
                  await ref
                      .read(userLibraryProvider.notifier)
                      .remove(entry.manga.id);
                  if (!context.mounted) return;
                  AppFeedback.showInfo(
                    context,
                    title: context.l10n.libraryItemRemoved(entry.manga.title),
                  );
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<_LibraryEntryAction>>[
              PopupMenuItem<_LibraryEntryAction>(
                value: _LibraryEntryAction.reading,
                child: Text(context.l10n.libraryStatusReading),
              ),
              PopupMenuItem<_LibraryEntryAction>(
                value: _LibraryEntryAction.completed,
                child: Text(context.l10n.libraryStatusCompleted),
              ),
              PopupMenuItem<_LibraryEntryAction>(
                value: _LibraryEntryAction.paused,
                child: Text(context.l10n.libraryStatusPaused),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_LibraryEntryAction>(
                value: _LibraryEntryAction.remove,
                child: Text(context.l10n.removeFromLibrary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _LibraryEntryAction { reading, completed, paused, remove }
