import 'package:flutter/material.dart';
import '../../../../core/widgets/inkscroller_shimmer.dart';

/// Shimmer skeleton placeholder displayed while [LibraryPage] loads its initial data.
///
/// Renders a static 3-column grid of [InkScrollerShimmer] boxes that visually
/// match the manga tile layout to reduce perceived loading time.
class LibraryShimmer extends StatelessWidget {
  const LibraryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (_, _) {
        return const InkScrollerShimmer(height: double.infinity);
      },
    );
  }
}
