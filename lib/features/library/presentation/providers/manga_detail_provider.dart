import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/manga.dart';
import '../../domain/usecases/get_manga_detail.dart';

/// Family provider that fetches enriched manga details by ID.
///
/// Returns a [Manga] entity via [GetMangaDetail]. Results are auto-cached
/// by Riverpod for the lifetime of the provider scope.
final mangaDetailProvider =
FutureProvider.family<Either<Failure, Manga>, String>((ref, mangaId) {
  return sl<GetMangaDetail>()(mangaId);
});
