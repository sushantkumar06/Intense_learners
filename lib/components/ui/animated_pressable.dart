import 'package:flutter/material.dart';

/// Interactive wrapper that provides spring-scale tactile feedback on tap.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPress;
  final double pressScale;
  final bool disabled;
  final HitTestBehavior behavior;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onPress,
    this.pressScale = 0.96,
    this.disabled = false,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.disabled && widget.onPress != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.disabled && widget.onPress != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.disabled && widget.onPress != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.disabled ? null : widget.onPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.disabled ? 0.5 : 1.0,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
