import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../library/data/datasources/library_remote_ds.dart';
import '../../../library/domain/entities/manga_capabilities.dart';

/// Loads the backend contract and fails closed when it is unavailable.
final mangaCapabilitiesProvider = FutureProvider<MangaCapabilities>((ref) async {
  try {
    return await sl<LibraryRemoteDataSource>().getMangaCapabilities();
  } on DioException {
    return const MangaCapabilities(supportsUnspecified: false);
  }
});
