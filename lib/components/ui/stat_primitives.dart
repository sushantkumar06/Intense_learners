import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Pulsing dot drawing attention to urgent or unread items.
class AttentionDot extends StatefulWidget {
  final Color color;
  final double size;

  const AttentionDot({
    super.key,
    this.color = AppColors.coral,
    this.size = 7.0,
  });

  @override
  State<AttentionDot> createState() => _AttentionDotState();
}

class _AttentionDotState extends State<AttentionDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Animates a number counting up from 0 to target.
class CountUpText extends StatefulWidget {
  final int target;
  final TextStyle? style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.target,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _animation = IntTween(begin: _animation.value, end: widget.target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: widget.style ?? AppTypography.stat,
        );
      },
    );
  }
}

/// Mini stat item with icon, animated value, and label.
class MiniStat extends StatelessWidget {
  final Widget icon;
  final int value;
  final String label;

  const MiniStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        CountUpText(
          target: value,
          style: AppTypography.label.copyWith(
            color: AppColors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
