import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/state/game_session_state.dart';
import '../emberlight_game.dart';

/// Renders a radial darkness vignette centered on the player inside dungeons.
class LanternDarknessOverlay extends PositionComponent
    with HasGameReference<EmberlightGame> {
  LanternDarknessOverlay() : super(priority: 100);

  @override
  void render(Canvas canvas) {
    final state = game.sessionState;
    if (state.zone != GameZone.hviskerotDungeon) return;

    final viewportSize = game.size;
    final fuelRatio = (state.lanternFuel / 100.0).clamp(0.0, 1.0);
    final lightRadius = 110.0 + 185.0 * fuelRatio;
    final center = Offset(viewportSize.x / 2, viewportSize.y / 2);

    final darknessPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0A0D12).withValues(alpha: 0.45),
          const Color(0xFF06080C).withValues(alpha: state.isShadowEnraged ? 0.90 : 0.78),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: lightRadius));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, viewportSize.x, viewportSize.y),
      darknessPaint,
    );
  }
}
