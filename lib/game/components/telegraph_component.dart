import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum TelegraphShape { circle, line }

/// Visual warning indicator rendered before an enemy attack lands.
class TelegraphComponent extends PositionComponent {
  TelegraphComponent({
    required Vector2 position,
    required this.shape,
    required this.duration,
    required this.onTrigger,
    this.radius = 52.0,
    this.lineLength = 150.0,
    this.lineWidth = 34.0,
    this.angleRad = 0.0,
  }) : super(position: position, anchor: Anchor.center, priority: 5);

  final TelegraphShape shape;
  final double duration;
  final VoidCallback onTrigger;
  final double radius;
  final double lineLength;
  final double lineWidth;
  final double angleRad;

  double _elapsed = 0.0;
  bool _triggered = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (!_triggered && _elapsed >= duration) {
      _triggered = true;
      onTrigger();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final outlinePaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFFFF3B30).withValues(alpha: 0.18 + 0.25 * progress)
      ..style = PaintingStyle.fill;

    if (shape == TelegraphShape.circle) {
      canvas.drawCircle(Offset.zero, radius, outlinePaint);
      canvas.drawCircle(Offset.zero, radius * progress, fillPaint);
    } else {
      canvas.save();
      canvas.rotate(angleRad);
      final fullRect = Rect.fromLTWH(0, -lineWidth / 2, lineLength, lineWidth);
      final fillRect = Rect.fromLTWH(
        0,
        -lineWidth / 2,
        lineLength * progress,
        lineWidth,
      );
      canvas.drawRect(fullRect, outlinePaint);
      canvas.drawRect(fillRect, fillPaint);

      // Subtle directional chevron at the tip
      final arrowPaint = Paint()
        ..color = const Color(0xFFFF8A80).withValues(alpha: 0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final tipX = max(12.0, lineLength - 8);
      final path = Path()
        ..moveTo(tipX - 8, -7)
        ..lineTo(tipX, 0)
        ..lineTo(tipX - 8, 7);
      canvas.drawPath(path, arrowPaint);
      canvas.restore();
    }
  }
}
