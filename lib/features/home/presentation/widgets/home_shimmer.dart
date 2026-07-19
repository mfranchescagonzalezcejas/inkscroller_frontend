import 'package:flutter/material.dart';

import '../../../../core/widgets/inkscroller_shimmer.dart';

/// Loading skeleton for the Home feed.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  const HomeShimmer.carousel({super.key});

  const HomeShimmer.cardRow({super.key});

  const HomeShimmer.chapterRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 370, child: InkScrollerShimmer(height: 370)),
            SizedBox(height: 24),
            _SectionTitleShimmer(),
            SizedBox(height: 8),
            _CardRowShimmer(itemCount: 3, width: 280, height: 150),
            SizedBox(height: 24),
            _SectionTitleShimmer(),
            SizedBox(height: 8),
            _ChipRowShimmer(),
            SizedBox(height: 12),
            _CardRowShimmer(itemCount: 4, width: 130, height: 220),
            SizedBox(height: 24),
            _SectionTitleShimmer(),
            SizedBox(height: 8),
            _CardRowShimmer(itemCount: 4, width: 150, height: 260),
            SizedBox(height: 24),
            _SectionTitleShimmer(),
            SizedBox(height: 8),
            _ChapterRowShimmer(),
            _ChapterRowShimmer(),
            _ChapterRowShimmer(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitleShimmer extends StatelessWidget {
  const _SectionTitleShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 160,
        height: 20,
        child: InkScrollerShimmer(height: 20),
      ),
    );
  }
}

class _CardRowShimmer extends StatelessWidget {
  const _CardRowShimmer({
    required this.itemCount,
    required this.width,
    required this.height,
  });

  final int itemCount;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 20),
          ...List.generate(
            itemCount,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: width,
                height: height,
                child: InkScrollerShimmer(height: height),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _ChipRowShimmer extends StatelessWidget {
  const _ChipRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(width: 100, height: 40, child: InkScrollerShimmer(height: 40)),
            SizedBox(width: 8),
            SizedBox(width: 100, height: 40, child: InkScrollerShimmer(height: 40)),
            SizedBox(width: 8),
            SizedBox(width: 100, height: 40, child: InkScrollerShimmer(height: 40)),
            SizedBox(width: 8),
            SizedBox(width: 100, height: 40, child: InkScrollerShimmer(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _ChapterRowShimmer extends StatelessWidget {
  const _ChapterRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 48, height: 64, child: InkScrollerShimmer(height: 64)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 140, height: 14, child: InkScrollerShimmer(height: 14)),
                SizedBox(height: 4),
                SizedBox(width: 100, height: 12, child: InkScrollerShimmer(height: 12)),
                SizedBox(height: 4),
                SizedBox(width: 40, height: 11, child: InkScrollerShimmer(height: 11)),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(width: 6, height: 6, child: InkScrollerShimmer(height: 6)),
        ],
      ),
    );
  }
}
