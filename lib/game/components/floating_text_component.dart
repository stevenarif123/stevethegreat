import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends TextComponent {
  FloatingTextComponent({
    required String text,
    required Vector2 position,
    Color color = Colors.white,
    double fontSize = 14,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 50,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        );

  double _life = 0.65;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y -= 36 * dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }
}
