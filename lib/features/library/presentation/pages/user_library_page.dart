import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart';
import 'package:inkscroller_flutter/core/l10n/l10n.dart';

/// User's personal library page - shows manga added by the user.
///
/// This is a placeholder UI - will be connected to user's saved library
/// when backend is available.
class UserLibraryPage extends StatelessWidget {
  const UserLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          context.l10n.libraryTitle,
          style: AppTypography.titleLgStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    // Placeholder data - replace with user's library when backend available
    final colors = Theme.of(context).colorScheme;
    final placeholderMangas = <_PlaceholderManga>[
      _PlaceholderManga(title: 'One Piece', coverColor: colors.surface),
      _PlaceholderManga(
        title: 'Solo Leveling',
        coverColor: colors.surfaceContainerHigh,
      ),
      _PlaceholderManga(title: 'Tokyo Revengers', coverColor: colors.surface),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: placeholderMangas.length + 6, // +6 for more placeholder items
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: index < placeholderMangas.length
                        ? placeholderMangas[index].coverColor
                        : colors.surfaceContainerHigh,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.image, color: colors.outline, size: 32),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  index < placeholderMangas.length
                      ? placeholderMangas[index].title
                      : 'Manga ${index + 1}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceholderManga {
  final String title;
  final Color coverColor;

  const _PlaceholderManga({required this.title, required this.coverColor});
}
