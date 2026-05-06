import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reading_preferences.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/resolve_reader_mode.dart';

void main() {
  const useCase = ResolveReaderMode();

  test('returns per-title override when present', () {
    const override = PerTitleOverride(
      mangaId: 'manga-1',
      preferredReaderMode: ReaderMode.paged,
    );

    final result = useCase(
      globalReaderMode: ReaderMode.vertical,
      titleOverride: override,
      contentMetadata: const ReaderContentMetadata(pageCount: 10),
    );

    expect(result, ReaderMode.paged);
  });

  test('returns global preference when no override exists', () {
    final result = useCase(
      globalReaderMode: ReaderMode.paged,
      contentMetadata: const ReaderContentMetadata(pageCount: 10),
    );

    expect(result, ReaderMode.paged);
  });

  test('returns content suggestion when no global preference exists', () {
    final result = useCase(
      contentMetadata: const ReaderContentMetadata(
        pageCount: 10,
        suggestedMode: ReaderMode.paged,
      ),
    );

    expect(result, ReaderMode.paged);
  });

  test('returns vertical default when nothing is configured', () {
    final result = useCase(
      contentMetadata: const ReaderContentMetadata(pageCount: 10),
    );

    expect(result, ReaderMode.vertical);
  });

  test('override wins over global preference and content suggestion', () {
    const override = PerTitleOverride(
      mangaId: 'manga-2',
      preferredReaderMode: ReaderMode.vertical,
    );

    final result = useCase(
      globalReaderMode: ReaderMode.paged,
      titleOverride: override,
      contentMetadata: const ReaderContentMetadata(
        pageCount: 5,
        suggestedMode: ReaderMode.paged,
      ),
    );

    expect(result, ReaderMode.vertical);
  });
}
