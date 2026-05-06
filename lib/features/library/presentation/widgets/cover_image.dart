import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/layout.dart';

/// Cached network image widget for manga cover art with shimmer placeholder.
///
/// Scales the image resolution based on viewport width and caches it for
/// 7 days via [CachedNetworkImage]. Shows a shimmer skeleton while loading.
class CoverImage extends StatelessWidget {
  final String? url;

  const CoverImage({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const Icon(Icons.image_not_supported);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Escala base pensada para móvil ~375px
    final scale = screenWidth / AppLayout.baseViewportWidth;

    final coverWidth = AppLayout.smallCoverWidth * scale;
    final coverHeight = AppLayout.smallCoverHeight * scale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppLayout.coverBorderRadius * scale),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: coverWidth,
        height: coverHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: coverWidth,
            height: coverHeight,
            color: Colors.grey.shade300,
          ),
        ),
        errorWidget: (_, _, _) =>
        const Icon(Icons.broken_image),
      ),
    );
  }
}
