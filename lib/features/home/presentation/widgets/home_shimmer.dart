import 'package:flutter/material.dart';
import '../../../../core/widgets/inkscroller_shimmer.dart';
import '../constants/home_layout.dart';

/// Decorative loading skeleton for the redesigned home feed.
///
/// Two variants match the shapes of the main sections so the placeholder feels
/// like the real layout.
class HomeShimmer extends StatelessWidget {
  /// Large rectangle placeholder for the featured hero carousel.
  const HomeShimmer.carousel({super.key})
    : _variant = _HomeShimmerVariant.carousel;

  /// Horizontal row of small placeholders for the continue-reading rail.
  const HomeShimmer.cardRow({super.key})
    : _variant = _HomeShimmerVariant.cardRow;

  final _HomeShimmerVariant _variant;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: _variant == _HomeShimmerVariant.carousel
          ? const InkScrollerShimmer(
              height: HomeLayout.heroCarouselHeight,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            )
          : const _CardRowShimmer(),
    );
  }
}

enum _HomeShimmerVariant { carousel, cardRow }

class _CardRowShimmer extends StatelessWidget {
  const _CardRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          SizedBox(width: 20),
          _CardShimmer(),
          SizedBox(width: 12),
          _CardShimmer(),
          SizedBox(width: 12),
          _CardShimmer(),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: HomeLayout.continueReadingCardWidth,
      child: InkScrollerShimmer(height: HomeLayout.continueReadingCardHeight),
    );
  }
}
