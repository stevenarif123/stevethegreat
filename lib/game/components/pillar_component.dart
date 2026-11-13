import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../emberlight_game.dart';

/// Solid Nordic rune pillar that blocks movement and stops enemy charges.
class PillarComponent extends PositionComponent
    with HasGameReference<EmberlightGame> {
  PillarComponent({
    required Vector2 position,
    this.radius = 22.0,
  }) : super(
          position: position,
          size: Vector2(36, 72),
          anchor: Anchor.center,
          priority: 14,
        );

  final double radius;
  Sprite? _columnSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final img = await game.images.load(
        'dungeon_0x72/0x72_DungeonTilesetII_v1.7/frames/column.png',
      );
      _columnSprite = Sprite(img);
    } catch (_) {
      _columnSprite = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.y - 8),
        width: radius * 2.1,
        height: radius * 0.9,
      ),
      Paint()..color = Colors.black45,
    );

    if (_columnSprite != null) {
      _columnSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        overridePaint: Paint()..filterQuality = FilterQuality.none,
      );
      // Subtle glowing Nordic rune on the column shaft
      canvas.drawCircle(
        Offset(center.dx, center.dy + 2),
        3.5,
        Paint()..color = const Color(0xFF80CBC4).withValues(alpha: 0.75),
      );
      return;
    }

    // Fallback stone base
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF455A64),
    );
  }
}

/// Flickering wall/ground torch for Nordic atmosphere.
class TorchComponent extends PositionComponent {
  TorchComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.center,
          priority: 11,
        );

  double _time = Random().nextDouble() * 10;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 7.5;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final flicker = sin(_time) * 2.0 + cos(_time * 1.7) * 1.2;

    canvas.drawCircle(
      center,
      20 + flicker,
      Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      5.5 + flicker * 0.25,
      Paint()..color = const Color(0xFFFFA726),
    );
    canvas.drawCircle(
      center,
      2.6,
      Paint()..color = const Color(0xFFFFF176),
    );
  }
}
