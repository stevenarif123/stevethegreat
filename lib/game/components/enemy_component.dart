import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../../core/models/loot_item.dart';
import '../../core/services/combat_calculator.dart';
import '../emberlight_game.dart';
import 'floating_text_component.dart';
import 'loot_drop_component.dart';
import 'pillar_component.dart';
import 'telegraph_component.dart';
import 'vfx_components.dart';

enum EnemyKind { brambleSlime, frostThornHound }

enum _EnemyState { chase, windup, action, recover }

class EnemyComponent extends PositionComponent
    with HasGameReference<EmberlightGame> {
  EnemyComponent({
    required this.kind,
    required Vector2 position,
    required this.floor,
  }) : super(
          position: position,
          size: Vector2.all(kind == EnemyKind.brambleSlime ? 30 : 32),
          anchor: Anchor.center,
          priority: 15,
        ) {
    maxHp = (kind == EnemyKind.brambleSlime ? 55.0 : 75.0) + (floor - 1) * 18;
    hp = maxHp;
  }

  final EnemyKind kind;
  final int floor;
  late final double maxHp;
  late double hp;

  _EnemyState _state = _EnemyState.chase;
  double _stateTimer = 0.0;
  double _hitFlashTimer = 0.0;
  double _animTimer = 0.0;
  Vector2 _knockbackVel = Vector2.zero();
  Vector2 _dashVelocity = Vector2.zero();
  Vector2 _leapTarget = Vector2.zero();
  bool _hasDealtDashHit = false;
  final Random _rng = Random();
  bool _spriteLoaded = false;
  late final SpriteAnimationTicker _enemyTicker;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      if (kind == EnemyKind.brambleSlime) {
        final image = await game.images.load(
          'mystic_woods/sprites/characters/slime.png',
        );
        final sheet = SpriteSheet(image: image, srcSize: Vector2.all(32));
        _enemyTicker = sheet
            .createAnimation(row: 0, stepTime: 0.14, to: 4)
            .createTicker();
      } else {
        final image = await game.images.load(
          'mystic_woods/sprites/characters/skeleton.png',
        );
        final sheet = SpriteSheet(image: image, srcSize: Vector2.all(48));
        _enemyTicker = sheet
            .createAnimation(row: 3, stepTime: 0.11, to: 6)
            .createTicker();
      }
      _spriteLoaded = true;
    } catch (_) {
      _spriteLoaded = false;
    }
  }

  double get _baseSpeed => kind == EnemyKind.brambleSlime ? 68.0 : 94.0;

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt * 6.0;
    if (_spriteLoaded) {
      _enemyTicker.update(dt);
    }
    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;

    // Apply knockback decay
    if (_knockbackVel.length2 > 1) {
      position += _knockbackVel * dt;
      _knockbackVel *= pow(0.02, dt).toDouble();
    }

    final enraged = game.sessionState.isShadowEnraged;
    final speedMult = enraged ? 1.25 : 1.0;
    final windupMult = enraged ? 0.78 : 1.0;

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    switch (_state) {
      case _EnemyState.chase:
        if (dist > 1) {
          position += (toPlayer / dist) * _baseSpeed * speedMult * dt;
        }
        final triggerRange = kind == EnemyKind.brambleSlime ? 105.0 : 165.0;
        if (dist <= triggerRange) {
          _startWindup(toPlayer, windupMult);
        }
        break;

      case _EnemyState.windup:
        // Wait for TelegraphComponent callback
        break;

      case _EnemyState.action:
        _stateTimer -= dt;
        if (kind == EnemyKind.frostThornHound) {
          position += _dashVelocity * dt;
          if (!_hasDealtDashHit && position.distanceTo(player.position) < 28) {
            _hasDealtDashHit = true;
            player.takeDamage(22.0 + (floor - 1) * 3, position);
          }
        }
        if (_stateTimer <= 0) {
          _state = _EnemyState.recover;
          _stateTimer = kind == EnemyKind.brambleSlime ? 0.75 : 0.85;
        }
        break;

      case _EnemyState.recover:
        _stateTimer -= dt;
        if (_stateTimer <= 0) {
          _state = _EnemyState.chase;
        }
        break;
    }

    // Resolve pillar collisions (Hound slams & gets stunned if charging!)
    const enemyRadius = 15.0;
    for (final pillar in game.world.children.whereType<PillarComponent>()) {
      final delta = position - pillar.position;
      final minDist = enemyRadius + pillar.radius;
      if (delta.length2 < minDist * minDist && delta.length2 > 0.001) {
        final dist = delta.length;
        position += (delta / dist) * (minDist - dist);
        if (kind == EnemyKind.frostThornHound && _state == _EnemyState.action) {
          _state = _EnemyState.recover;
          _stateTimer = 1.35;
          game.triggerScreenShake(4.0);
          game.world.add(
            HitSparkComponent(
              position: position.clone(),
              color: const Color(0xFF80CBC4),
              count: 6,
            ),
          );
          game.world.add(
            FloatingTextComponent(
              text: 'STUNNED!',
              position: position.clone()..y -= 24,
              color: const Color(0xFF80CBC4),
              fontSize: 11,
            ),
          );
        }
      }
    }

    position.x = position.x.clamp(48, game.arenaSize.x - 48);
    position.y = position.y.clamp(48, game.arenaSize.y - 48);
  }

  void _startWindup(Vector2 toPlayer, double windupMult) {
    _state = _EnemyState.windup;
    if (kind == EnemyKind.brambleSlime) {
      _leapTarget = game.player.position.clone();
      final windupDuration = 0.65 * windupMult;
      game.world.add(
        TelegraphComponent(
          position: _leapTarget,
          shape: TelegraphShape.circle,
          radius: 48,
          duration: windupDuration,
          onTrigger: () {
            if (!isMounted) return;
            position = _leapTarget.clone();
            if (position.distanceTo(game.player.position) <= 50) {
              game.player.takeDamage(16.0 + (floor - 1) * 3, position);
            }
            _state = _EnemyState.action;
            _stateTimer = 0.15;
          },
        ),
      );
    } else {
      final dir = toPlayer.length > 0.01 ? toPlayer.normalized() : Vector2(1, 0);
      final angle = atan2(dir.y, dir.x);
      final windupDuration = 0.55 * windupMult;
      _dashVelocity = dir * 470.0;
      _hasDealtDashHit = false;
      game.world.add(
        TelegraphComponent(
          position: position.clone(),
          shape: TelegraphShape.line,
          lineLength: 175,
          lineWidth: 32,
          angleRad: angle,
          duration: windupDuration,
          onTrigger: () {
            if (!isMounted) return;
            _state = _EnemyState.action;
            _stateTimer = 0.32;
          },
        ),
      );
    }
  }

  void takeDamage(double amount, Vector2 sourcePos) {
    hp -= amount;
    _hitFlashTimer = 0.11;
    final away = (position - sourcePos);
    if (away.length2 > 0.01) {
      _knockbackVel = away.normalized() * 210;
    }

    game.world.add(
      FloatingTextComponent(
        text: '-${amount.round()}',
        position: position.clone()..y -= 20,
        color: const Color(0xFFFFD54F),
      ),
    );

    if (hp <= 0) {
      _spawnLoot();
      removeFromParent();
      game.onEnemyDefeated();
    }
  }

  void _spawnLoot() {
    final rareChance = CombatCalculator.effectiveRareDropChance(
      baseChance: 0.18,
      lanternFuel: game.sessionState.lanternFuel,
      floor: floor,
    );

    final roll = _rng.nextDouble();
    final LootItem item;
    if (roll < rareChance) {
      item = const LootItem(
        id: 'minor_ember_shard',
        name: 'Ember Shard',
        silverValue: 45,
        rarity: LootRarity.rare,
      );
    } else if (roll < 0.58) {
      item = const LootItem(
        id: 'cracked_relic',
        name: 'Cracked Relic',
        silverValue: 22,
        rarity: LootRarity.uncommon,
      );
    } else {
      item = const LootItem(
        id: 'rune_moss',
        name: 'Rune Moss',
        silverValue: 12,
        rarity: LootRarity.common,
      );
    }

    game.world.add(LootDropComponent(item: item, position: position.clone()));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final enraged = game.sessionState.isShadowEnraged;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, size.y - 2), width: 24, height: 9),
      Paint()..color = Colors.black45,
    );

    // Body
    Color bodyColor;
    if (_hitFlashTimer > 0) {
      bodyColor = Colors.white;
    } else if (kind == EnemyKind.brambleSlime) {
      bodyColor = enraged ? const Color(0xFF8E24AA) : const Color(0xFF4CAF50);
    } else {
      bodyColor = enraged ? const Color(0xFFD32F2F) : const Color(0xFF5C6BC0);
    }

    final bodyPaint = Paint()..color = bodyColor;
    final squash = _state == _EnemyState.windup
        ? 0.85
        : 1.0 + sin(_animTimer) * 0.07;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 / squash, squash);
    canvas.translate(-center.dx, -center.dy);

    if (kind == EnemyKind.brambleSlime) {
      if (_spriteLoaded) {
        final tint = _hitFlashTimer > 0
            ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
            : (enraged
                ? const ColorFilter.mode(
                    Color(0x889C27B0),
                    BlendMode.srcATop,
                  )
                : null);
        _enemyTicker.getSprite().render(
              canvas,
              position: Vector2(-8, -10),
              size: Vector2.all(48),
              overridePaint: Paint()
                ..filterQuality = FilterQuality.none
                ..colorFilter = tint,
            );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 26, height: 22),
            const Radius.circular(10),
          ),
          bodyPaint,
        );
      }
    } else {
      if (_spriteLoaded) {
        final tint = _hitFlashTimer > 0
            ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
            : (enraged
                ? const ColorFilter.mode(
                    Color(0x88D32F2F),
                    BlendMode.srcATop,
                  )
                : null);
        _enemyTicker.getSprite().render(
              canvas,
              position: Vector2(-18, -22),
              size: Vector2.all(68),
              overridePaint: Paint()
                ..filterQuality = FilterQuality.none
                ..colorFilter = tint,
            );
      } else {
        // Hound diamond/wolf silhouette
        final path = Path()
          ..moveTo(center.dx, 2)
          ..lineTo(size.x - 2, center.dy)
          ..lineTo(center.dx, size.y - 2)
          ..lineTo(2, center.dy)
          ..close();
        canvas.drawPath(path, bodyPaint);
      }
    }
    canvas.restore();

    // Glowing eyes (fallback when sprite is not used)
    if (!_spriteLoaded) {
      final eyeColor = _state == _EnemyState.windup
          ? const Color(0xFFFF5252)
          : const Color(0xFFFFF176);
      final eyePaint = Paint()..color = eyeColor;
      canvas.drawCircle(Offset(center.dx - 5, center.dy - 2), 2.3, eyePaint);
      canvas.drawCircle(Offset(center.dx + 5, center.dy - 2), 2.3, eyePaint);
    }

    // HP Bar
    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    const barW = 30.0;
    const barH = 4.0;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - barW / 2, -8, barW, barH),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - barW / 2, -8, barW * hpRatio, barH),
      Paint()..color = const Color(0xFFEF5350),
    );
  }
}
