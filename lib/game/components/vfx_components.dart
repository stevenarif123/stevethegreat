import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _SparkParticle {
  _SparkParticle({
    required this.vel,
    required this.size,
  });

  Vector2 pos = Vector2.zero();
  final Vector2 vel;
  final double size;
}

/// Burst of glowing sparks when hitting an enemy or triggering Ember Cleave.
class HitSparkComponent extends PositionComponent {
  HitSparkComponent({
    required Vector2 position,
    this.color = const Color(0xFFFFD54F),
    int count = 8,
    double speed = 150.0,
  }) : super(position: position, anchor: Anchor.center, priority: 40) {
    final rng = Random();
    for (int i = 0; i < count; i++) {
      final angle = (pi * 2 * i / count) + (rng.nextDouble() - 0.5) * 0.5;
      final mag = speed * (0.55 + rng.nextDouble() * 0.65);
      _sparks.add(
        _SparkParticle(
          vel: Vector2(cos(angle), sin(angle)) * mag,
          size: 2.2 + rng.nextDouble() * 2.0,
        ),
      );
    }
  }

  final Color color;
  final List<_SparkParticle> _sparks = [];
  double _life = 0.24;
  static const double _maxLife = 0.24;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    for (final s in _sparks) {
      s.pos += s.vel * dt;
      s.vel.scale(0.90);
    }
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / _maxLife).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withValues(alpha: alpha);
    for (final s in _sparks) {
      canvas.drawCircle(Offset(s.pos.x, s.pos.y), s.size * alpha, paint);
    }
  }
}

/// Fading ghost silhouette spawned during Steinar/Steve's dodge dash.
class DashAfterimageComponent extends PositionComponent {
  DashAfterimageComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(22, 24),
          anchor: Anchor.center,
          priority: 18,
        );

  double _life = 0.20;
  static const double _maxLife = 0.20;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / _maxLife).clamp(0.0, 1.0) * 0.45;
    final paint = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      paint,
    );
  }
}
