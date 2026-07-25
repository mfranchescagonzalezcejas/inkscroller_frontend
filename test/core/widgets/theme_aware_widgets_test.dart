import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/theme/app_theme.dart';
import 'package:inkscroller_flutter/core/widgets/info_list_card.dart';
import 'package:inkscroller_flutter/core/widgets/tonal_tab_bar.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/manga_tile.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  final List<ThemeData> themes = <ThemeData>[AppTheme.light(), AppTheme.dark()];

  testWidgets('TonalTabBar uses the active color scheme', (tester) async {
    for (final ThemeData theme in themes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TonalTabBar(
              labels: const <String>['Active', 'Inactive'],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final DecoratedBox container = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final Material activePill = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(TonalTabBar),
              matching: find.byType(Material),
            )
            .first,
      );
      final Text active = tester.widget<Text>(find.text('Active'));
      final Text inactive = tester.widget<Text>(find.text('Inactive'));

      expect(decoration.color, theme.colorScheme.surfaceContainerLow);
      expect(
        activePill.color,
        theme.colorScheme.primary.withValues(alpha: 0.16),
      );
      expect(active.style!.color, theme.colorScheme.primary);
      expect(inactive.style!.color, theme.colorScheme.onSurfaceVariant);
    }
  });

  testWidgets('InfoListCard uses the active color scheme', (tester) async {
    for (final ThemeData theme in themes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: InfoListCard(
              children: <Widget>[
                InfoListRow(
                  label: 'Label',
                  value: 'Value',
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final DecoratedBox card = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final BoxDecoration decoration = card.decoration as BoxDecoration;
      final Text label = tester.widget<Text>(find.text('Label'));
      final Text value = tester.widget<Text>(find.text('Value'));
      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));

      expect(decoration.color, theme.colorScheme.surfaceContainer);
      expect(label.style!.color, theme.colorScheme.onSurface);
      expect(value.style!.color, theme.colorScheme.onSurfaceVariant);
      expect(icon.color, theme.colorScheme.primary);
    }
  });

  testWidgets('MangaTile uses the active color scheme', (tester) async {
    for (final ThemeData theme in themes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: MangaTile(
                manga: Manga(id: 'manga-1', title: 'Theme Aware Manga'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Text title = tester.widget<Text>(find.text('Theme Aware Manga'));
      final Text score = tester.widget<Text>(find.text('--'));
      final Icon star = tester.widget<Icon>(find.byIcon(Icons.star));

      expect(title.style!.color, theme.colorScheme.onSurface);
      expect(score.style!.color, theme.colorScheme.onSurfaceVariant);
      expect(star.color, theme.colorScheme.onSurfaceVariant);
    }
  });
}
