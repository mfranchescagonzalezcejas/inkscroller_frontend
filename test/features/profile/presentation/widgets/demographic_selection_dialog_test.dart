import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/profile/presentation/widgets/demographic_selection_dialog.dart';
import '../../../../support/l10n_test_helpers.dart';

void main() {
  Future<Future<Set<MangaDemographic>?> Function()> pump(WidgetTester tester, List<MangaDemographic> options) async {
    late Future<Set<MangaDemographic>?> result;
    await tester.pumpWidget(wrapWithL10n(Builder(builder: (context) => ElevatedButton(onPressed: () { result = showDialog<Set<MangaDemographic>>(context: context, builder: (_) => DemographicSelectionDialog(options: options, current: <MangaDemographic>{}, labelFor: (value) => value.name, emptySelectionMessage: 'Select at least one demographic')); }, child: const Text('open'))), locale: const Locale('en')));
    await tester.tap(find.text('open')); await tester.pump();
    return () => result;
  }
  testWidgets('renders only allowed options', (tester) async { await pump(tester, [MangaDemographic.shounen]); expect(find.text('unspecified'), findsNothing); });
  testWidgets('shows unspecified when allowed and guards empty confirmation', (tester) async { await pump(tester, [MangaDemographic.unspecified]); expect(find.text('unspecified'), findsOneWidget); await tester.tap(find.text('OK')); await tester.pump(); expect(find.text('Select at least one demographic'), findsOneWidget); });
  testWidgets('confirm returns a nonempty selection', (tester) async {
    final result = await pump(tester, [MangaDemographic.shounen]);
    await tester.tap(find.byType(Checkbox)); await tester.tap(find.text('OK')); await tester.pump();
    expect(await result(), <MangaDemographic>{MangaDemographic.shounen});
  });
  testWidgets('cancel dismisses the dialog', (tester) async {
    final result = await pump(tester, [MangaDemographic.shounen]);
    await tester.tap(find.text('Cancel')); await tester.pump();
    expect(await result(), isNull);
  });
}
