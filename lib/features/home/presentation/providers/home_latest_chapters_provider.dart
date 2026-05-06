import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/home_chapter.dart';
import '../../domain/usecases/get_latest_home_chapters.dart';

final homeLatestChaptersProvider =
    FutureProvider.autoDispose<List<HomeChapter>>((ref) async {
  final useCase = sl<GetLatestHomeChapters>();
  final result = await useCase(limit: 8);

  return result.fold(
    (_) => <HomeChapter>[],
    (chapters) => chapters,
  );
});
