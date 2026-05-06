import 'package:flutter/material.dart';

/// Reusable shimmer skeleton box used as a loading placeholder.
///
/// Renders a rounded rectangle with a gradient sweep animation.
/// Used by [LibraryShimmer], [MangaDetailShimmer], and other loading states.
class InkScrollerShimmer extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;

  const InkScrollerShimmer({
    super.key,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<InkScrollerShimmer> createState() => _InkScrollerShimmerState();
}

class _InkScrollerShimmerState extends State<InkScrollerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlideGradientTransform(_controller.value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlideGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      0,
      bounds.height * (slidePercent * 2 - 1),
      0,
    );
  }
}
