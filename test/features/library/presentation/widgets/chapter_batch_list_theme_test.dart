import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/theme/app_theme.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter_batch.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/chapter_batch_list.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

class _ReadingProgressRepository implements ReadingProgressRepository {
  @override
  Future<Map<String, MangaReadingProgress>> getAll() async =>
      const <String, MangaReadingProgress>{};

  @override
  Future<void> save(MangaReadingProgress progress) async {}
}

void main() {
  final List<ThemeData> themes = <ThemeData>[AppTheme.light(), AppTheme.dark()];

  testWidgets('ChapterBatchList headers use the active color scheme', (
    tester,
  ) async {
    for (final ThemeData theme in themes) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readingProgressProvider.overrideWith(
              (ref) => ReadingProgressNotifier(_ReadingProgressRepository()),
            ),
          ],
          child: MaterialApp(
            theme: theme,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ChapterBatchList(
                mangaId: 'manga-1',
                batches: <ChapterBatch>[
                  ChapterBatch(
                    start: 1,
                    end: 2,
                    items: <ChapterBatchItem>[
                      ReadableChapterBatchItem(
                        Chapter(
                          id: 'chapter-1',
                          number: 1,
                          readable: true,
                          external: false,
                        ),
                        1,
                      ),
                      PlaceholderChapterBatchItem(2),
                    ],
                  ),
                ],
                onChapterTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Text header = tester.widget<Text>(find.text('Capítulos 1–2'));
      expect(header.style!.color, theme.colorScheme.onSurface);
    }
  });
}
