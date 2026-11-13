import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum WorldPropKind {
  tallTree,
  roundTree,
  berryTree,
  bush,
  rock,
  log,
  mushroom,
  chest,
  crate,
}

/// Environment prop rendered from extracted pixel-art sprite sheets.
class WorldPropComponent extends PositionComponent {
  WorldPropComponent({
    required this.kind,
    required Vector2 position,
    this.collisionRadius = 0.0,
    Sprite? sprite,
    Vector2? renderSize,
  })  : _sprite = sprite,
        _renderSize = renderSize ?? Vector2.all(32),
        super(
          position: position,
          size: renderSize ?? Vector2.all(32),
          anchor: Anchor.center,
          priority: 13,
        );

  final WorldPropKind kind;
  final double collisionRadius;
  final Sprite? _sprite;
  final Vector2 _renderSize;

  @override
  void render(Canvas canvas) {
    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_renderSize.x / 2, _renderSize.y - 4),
        width: _renderSize.x * 0.72,
        height: _renderSize.y * 0.28,
      ),
      Paint()..color = Colors.black38,
    );

    if (_sprite != null) {
      _sprite.render(
        canvas,
        position: Vector2.zero(),
        size: _renderSize,
        overridePaint: Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      // Fallback shape if sprite failed to load
      canvas.drawCircle(
        Offset(_renderSize.x / 2, _renderSize.y / 2),
        _renderSize.x * 0.4,
        Paint()..color = const Color(0xFF2E7D32),
      );
    }
  }
}

/// Cozy Nordic wooden cabin in Eldvik Camp.
class CabinComponent extends PositionComponent {
  CabinComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(128, 108),
          anchor: Anchor.center,
          priority: 12,
        );

  final double collisionRadius = 52.0;

  @override
  void render(Canvas canvas) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 18, size.x - 4, size.y - 10),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black45,
    );

    // Timber walls
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 42, size.x - 20, size.y - 46),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawRect(
      Rect.fromLTWH(10, 42, size.x - 20, 6),
      Paint()..color = const Color(0xFF4E342E),
    );

    // Steep Nordic shingled roof
    final roof = Path()
      ..moveTo(0, 50)
      ..lineTo(size.x / 2, 4)
      ..lineTo(size.x, 50)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF455A64));
    canvas.drawPath(
      roof,
      Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 - 12, size.y - 36, 24, 32),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3E2723),
    );

    // Warm glowing window
    canvas.drawRect(
      Rect.fromLTWH(24, 62, 18, 16),
      Paint()..color = const Color(0xFFFFB74D),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x - 42, 62, 18, 16),
      Paint()..color = const Color(0xFFFFB74D),
    );
  }
}
