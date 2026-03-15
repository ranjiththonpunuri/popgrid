import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Data for a single strikeout line to render.
class StrikeoutLine {
  final Offset start;
  final Offset end;
  final Color color;
  final bool isNew;

  const StrikeoutLine({
    required this.start,
    required this.end,
    required this.color,
    this.isNew = false,
  });
}

/// Overlay that draws animated strikeout lines across scored sequences.
///
/// New lines animate from start → end with a glowing effect.
/// Old lines are drawn at full length immediately.
class StrikeoutOverlay extends StatefulWidget {
  final List<StrikeoutLine> lines;

  const StrikeoutOverlay({super.key, required this.lines});

  @override
  State<StrikeoutOverlay> createState() => _StrikeoutOverlayState();
}

class _StrikeoutOverlayState extends State<StrikeoutOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _previousLineCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _previousLineCount = widget.lines.length;
    // If there are already new lines on init, animate them
    if (widget.lines.any((l) => l.isNew)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant StrikeoutOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when new lines appear
    final hasNewLines = widget.lines.any((l) => l.isNew);
    final lineCountChanged = widget.lines.length != _previousLineCount;
    if (hasNewLines && lineCountChanged) {
      _controller.forward(from: 0.0);
    }
    _previousLineCount = widget.lines.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StrikeoutPainter(
            lines: widget.lines,
            animationProgress: _animation.value,
          ),
        );
      },
    );
  }
}

class _StrikeoutPainter extends CustomPainter {
  final List<StrikeoutLine> lines;
  final double animationProgress;

  _StrikeoutPainter({
    required this.lines,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final progress = line.isNew ? animationProgress : 1.0;
      if (progress <= 0) continue;

      final currentEnd = Offset.lerp(line.start, line.end, progress)!;

      // Outer glow layer
      final glowPaint = Paint()
        ..color = line.color.withValues(alpha: 0.3)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawLine(line.start, currentEnd, glowPaint);

      // Inner glow layer
      final innerGlowPaint = Paint()
        ..color = line.color.withValues(alpha: 0.5)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawLine(line.start, currentEnd, innerGlowPaint);

      // Core line
      final corePaint = Paint()
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..shader = ui.Gradient.linear(
          line.start,
          currentEnd,
          [
            line.color.withValues(alpha: 0.9),
            line.color,
            line.color.withValues(alpha: 0.9),
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawLine(line.start, currentEnd, corePaint);

      // Bright tip dot on new animated lines
      if (line.isNew && progress > 0.05 && progress < 1.0) {
        final tipPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(currentEnd, 4.0, tipPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrikeoutPainter oldDelegate) {
    return animationProgress != oldDelegate.animationProgress ||
        lines.length != oldDelegate.lines.length;
  }
}
