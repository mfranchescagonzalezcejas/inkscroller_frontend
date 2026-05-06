import 'package:flutter/material.dart';

/// Animated brand logo loader shown during full-screen loading states.
///
/// Pulses and bounces the InkScroller logo icon using a repeating
/// [AnimationController] to provide visual feedback while data loads.
class InkScrollerLogoLoader extends StatefulWidget {
  final double size;

  const InkScrollerLogoLoader({
    super.key,
    this.size = 96,
  });

  @override
  State<InkScrollerLogoLoader> createState() =>
      _InkScrollerLogoLoaderState();
}

class _InkScrollerLogoLoaderState extends State<InkScrollerLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _offset = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Image.asset(
              'assets/icons/prod/foreground.png',
              width: widget.size,
              height: widget.size,
            ),
          ),
        );
      },
    );
  }
}
