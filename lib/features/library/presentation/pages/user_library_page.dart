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
      backgroundColor: AppColors.voidLowest,
      appBar: AppBar(
        backgroundColor: AppColors.voidLowest,
        title: Text(
          context.l10n.libraryTitle,
          style: AppTypography.titleLgStyle.copyWith(color: AppColors.onSurface),
        ),
        centerTitle: false,
      ),
      body: _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    // Placeholder data - replace with user's library when backend available
    final placeholderMangas = [
      const _PlaceholderManga(title: 'One Piece', coverColor: AppColors.card),
      const _PlaceholderManga(
        title: 'Solo Leveling',
        coverColor: AppColors.cardHigh,
      ),
      const _PlaceholderManga(
        title: 'Tokyo Revengers',
        coverColor: AppColors.card,
      ),
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
            color: AppColors.card,
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
                        : AppColors.cardHigh,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.outline,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  index < placeholderMangas.length
                      ? placeholderMangas[index].title
                      : 'Manga ${index + 1}',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
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
