import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final String? label;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 72,
    this.strokeWidth = 7,
    this.color = AppColors.gold,
    this.trackColor = const Color(0x33FFFFFF),
    this.label,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    final percent = (clampedProgress * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated glow behind ring
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final opacity = 0.35 + (_glowController.value * 0.25);
              return Container(
                width: widget.size + 10,
                height: widget.size + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: opacity * 0.3),
                ),
              );
            },
          ),
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              progress: clampedProgress,
              strokeWidth: widget.strokeWidth,
              color: widget.color,
              trackColor: widget.trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: AppTypography.h3.copyWith(
                  color: AppColors.white,
                  fontSize: widget.size < 60 ? 12 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 8,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
