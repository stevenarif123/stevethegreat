import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PortalKind { enterDungeon, descendFloor, extractToCamp }

class PortalComponent extends PositionComponent {
  PortalComponent({
    required Vector2 position,
    required this.kind,
    required this.label,
    this.locked = false,
  }) : super(
          position: position,
          size: Vector2.all(54),
          anchor: Anchor.center,
          priority: 8,
        );

  final PortalKind kind;
  final String label;
  bool locked;
  double _pulse = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 3.0;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final baseColor = locked
        ? const Color(0xFF546E7A)
        : switch (kind) {
            PortalKind.enterDungeon => const Color(0xFF7E57C2),
            PortalKind.descendFloor => const Color(0xFF26A69A),
            PortalKind.extractToCamp => const Color(0xFFFFA726),
          };

    final pulseRadius = 22 + sin(_pulse) * 2.5;
    final glow = Paint()
      ..color = baseColor.withValues(alpha: locked ? 0.15 : 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, pulseRadius + 5, glow);

    final ring = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, pulseRadius, ring);

    final inner = Paint()..color = baseColor.withValues(alpha: 0.22);
    canvas.drawCircle(center, pulseRadius - 3, inner);

    final textPainter = TextPainter(
      text: TextSpan(
        text: locked ? 'Clear enemies' : label,
        style: TextStyle(
          color: locked ? Colors.white54 : Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, -16),
    );
  }
}
