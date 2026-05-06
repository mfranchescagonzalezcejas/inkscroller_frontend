import 'package:flutter/material.dart';
import '../../../../core/widgets/inkscroller_shimmer.dart';

/// Shimmer skeleton placeholder displayed while [MangaDetailPage] fetches data.
///
/// Mimics the detail page layout (cover, title, metadata, chapter list) with
/// [InkScrollerShimmer] boxes to reduce perceived loading time.
class MangaDetailShimmer extends StatelessWidget {
  const MangaDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkScrollerShimmer(height: 240),
          SizedBox(height: 16),
          InkScrollerShimmer(height: 20),
          SizedBox(height: 8),
          InkScrollerShimmer(height: 20),
          SizedBox(height: 24),
          InkScrollerShimmer(height: 16),
          SizedBox(height: 12),
          InkScrollerShimmer(height: 16),
          SizedBox(height: 12),
          InkScrollerShimmer(height: 16),
        ],
      ),
    );
  }
}
