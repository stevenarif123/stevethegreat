import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/models/loot_item.dart';
import '../emberlight_game.dart';
import 'floating_text_component.dart';

class LootDropComponent extends PositionComponent
    with HasGameReference<EmberlightGame> {
  LootDropComponent({
    required this.item,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(18),
          anchor: Anchor.center,
          priority: 12,
        );

  final LootItem item;
  double _bobTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _bobTimer += dt * 4.5;

    final player = game.player;
    final dist = position.distanceTo(player.position);
    if (dist < 28) {
      final added = game.sessionState.addLoot(item);
      if (added) {
        game.world.add(
          FloatingTextComponent(
            text: '+${item.name}',
            position: position.clone()..y -= 12,
            color: _rarityColor(item.rarity),
            fontSize: 12,
          ),
        );
        removeFromParent();
      }
    } else if (dist < 75) {
      // Gentle magnetic pull when close
      final dir = (player.position - position).normalized();
      position += dir * 130 * dt;
    }
  }

  Color _rarityColor(LootRarity rarity) {
    switch (rarity) {
      case LootRarity.common:
        return const Color(0xFFB0BEC5);
      case LootRarity.uncommon:
        return const Color(0xFF80CBC4);
      case LootRarity.rare:
        return const Color(0xFFFFB74D);
    }
  }

  @override
  void render(Canvas canvas) {
    final bobOffset = sin(_bobTimer) * 2.5;
    final color = _rarityColor(item.rarity);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 + bobOffset), 10, glow);

    final core = Paint()..color = color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 + bobOffset), 6, core);

    final rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2 + bobOffset), 6, rim);
  }
}
