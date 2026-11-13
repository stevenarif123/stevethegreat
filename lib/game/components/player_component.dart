import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_balance.dart';
import '../../core/services/combat_calculator.dart';
import '../../core/state/game_session_state.dart';
import '../emberlight_game.dart';
import 'enemy_component.dart';
import 'floating_text_component.dart';
import 'pillar_component.dart';
import 'vfx_components.dart';
import 'world_prop_component.dart';

class PlayerComponent extends PositionComponent
    with HasGameReference<EmberlightGame> {
  PlayerComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(28, 32),
          anchor: Anchor.center,
          priority: 20,
        );

  double hp = GameBalance.playerMaxHp;
  double stamina = GameBalance.playerMaxStamina;
  Vector2 facing = Vector2(0, 1);

  double _dashTimer = 0.0;
  double _iFrameTimer = 0.0;
  double _attackCooldownTimer = 0.0;
  double _comboWindowTimer = 0.0;
  double _skillCooldownTimer = 0.0;
  double _staminaRegenDelayTimer = 0.0;
  double _slashVisualTimer = 0.0;
  double _skillVisualTimer = 0.0;
  double _afterimageTimer = 0.0;
  double _walkBobTimer = 0.0;
  int _comboStep = 0;

  Vector2 _dashDir = Vector2(0, 1);

  bool _spriteLoaded = false;
  bool _isMoving = false;
  late final Map<String, SpriteAnimationTicker> _anims;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final image = await game.images.load(
        'mystic_woods/sprites/characters/player.png',
      );
      final sheet = SpriteSheet(image: image, srcSize: Vector2.all(48));
      _anims = {
        'idleDown': sheet.createAnimation(row: 0, stepTime: 0.14, to: 6).createTicker(),
        'idleSide': sheet.createAnimation(row: 1, stepTime: 0.14, to: 6).createTicker(),
        'idleUp': sheet.createAnimation(row: 2, stepTime: 0.14, to: 6).createTicker(),
        'walkDown': sheet.createAnimation(row: 3, stepTime: 0.09, to: 6).createTicker(),
        'walkSide': sheet.createAnimation(row: 4, stepTime: 0.09, to: 6).createTicker(),
        'walkUp': sheet.createAnimation(row: 5, stepTime: 0.09, to: 6).createTicker(),
        'attackDown': sheet.createAnimation(row: 6, stepTime: 0.055, to: 4, loop: false).createTicker(),
        'attackSide': sheet.createAnimation(row: 7, stepTime: 0.055, to: 4, loop: false).createTicker(),
        'attackUp': sheet.createAnimation(row: 8, stepTime: 0.055, to: 4, loop: false).createTicker(),
      };
      _spriteLoaded = true;
    } catch (_) {
      _spriteLoaded = false;
    }
  }

  bool get isDashing => _dashTimer > 0;
  bool get isInvulnerable => _iFrameTimer > 0;

  void resetForZone(Vector2 spawnPos, {required bool fullRestore}) {
    position = spawnPos;
    if (fullRestore) {
      hp = GameBalance.playerMaxHp;
      stamina = GameBalance.playerMaxStamina;
      _skillCooldownTimer = 0.0;
    }
    _dashTimer = 0.0;
    _iFrameTimer = 0.0;
    _attackCooldownTimer = 0.0;
    _slashVisualTimer = 0.0;
    _skillVisualTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final input = game.inputState;
    final state = game.sessionState;

    if (state.runStatus != RunStatus.active) return;

    if (_iFrameTimer > 0) _iFrameTimer -= dt;
    if (_attackCooldownTimer > 0) _attackCooldownTimer -= dt;
    if (_skillCooldownTimer > 0) _skillCooldownTimer -= dt;
    if (_slashVisualTimer > 0) _slashVisualTimer -= dt;
    if (_skillVisualTimer > 0) _skillVisualTimer -= dt;

    if (_comboWindowTimer > 0) {
      _comboWindowTimer -= dt;
      if (_comboWindowTimer <= 0) _comboStep = 0;
    }

    // Stamina regen after delay
    if (_staminaRegenDelayTimer > 0) {
      _staminaRegenDelayTimer -= dt;
    } else if (!isDashing) {
      stamina = min(
        GameBalance.playerMaxStamina,
        stamina + GameBalance.staminaRegenPerSecond * dt,
      );
    }

    // Movement or Dash
    final moveDir = input.moveDirection;
    _isMoving = moveDir.length2 > 0.01;
    if (_isMoving) {
      facing = moveDir.normalized();
    }

    if (_spriteLoaded) {
      _currentTicker().update(dt);
    }

    // Dash has priority (can cancel attack recovery)
    if (input.dashPressed && !isDashing) {
      _tryDash(moveDir);
    }

    if (isDashing) {
      _dashTimer -= dt;
      position += _dashDir * GameBalance.dashSpeed * dt;
      _afterimageTimer -= dt;
      if (_afterimageTimer <= 0) {
        _afterimageTimer = 0.045;
        game.world.add(DashAfterimageComponent(position: position.clone()));
      }
    } else {
      if (moveDir.length2 > 0.01) {
        _walkBobTimer += dt * 12.0;
      } else {
        _walkBobTimer = 0.0;
      }
      position += moveDir * GameBalance.playerMoveSpeed * dt;

      if (input.skillPressed && _skillCooldownTimer <= 0) {
        _tryWeaponSkill();
      } else if (input.attackPressed && _attackCooldownTimer <= 0) {
        if (input.mouseAimDirection != null &&
            input.mouseAimDirection!.length2 > 0.01) {
          facing = input.mouseAimDirection!.normalized();
          input.mouseAimDirection = null;
        }
        _tryBasicAttack();
      }
    }

    if (input.useOilPressed) {
      if (state.useLanternOil()) {
        game.world.add(
          FloatingTextComponent(
            text: 'Lantern +40%',
            position: position.clone()..y -= 24,
            color: const Color(0xFFFFCC80),
          ),
        );
      }
    }

    if (input.interactPressed) {
      game.tryInteract();
    }

    input.clearOneShotActions();

    // Resolve pillar & solid prop collisions
    const playerRadius = 14.0;
    for (final pillar in game.world.children.whereType<PillarComponent>()) {
      final delta = position - pillar.position;
      final minDist = playerRadius + pillar.radius;
      if (delta.length2 < minDist * minDist && delta.length2 > 0.001) {
        final dist = delta.length;
        position += (delta / dist) * (minDist - dist);
      }
    }
    for (final prop in game.world.children.whereType<WorldPropComponent>()) {
      if (prop.collisionRadius <= 0) continue;
      final delta = position - prop.position;
      final minDist = playerRadius + prop.collisionRadius;
      if (delta.length2 < minDist * minDist && delta.length2 > 0.001) {
        final dist = delta.length;
        position += (delta / dist) * (minDist - dist);
      }
    }
    for (final cabin in game.world.children.whereType<CabinComponent>()) {
      final delta = position - cabin.position;
      final minDist = playerRadius + cabin.collisionRadius;
      if (delta.length2 < minDist * minDist && delta.length2 > 0.001) {
        final dist = delta.length;
        position += (delta / dist) * (minDist - dist);
      }
    }

    // Resolve Tiled collision rectangles (drawn in Tiled's Collisions layer)
    for (final rect in game.tiledCollisions) {
      final closestX = position.x.clamp(rect.left, rect.right);
      final closestY = position.y.clamp(rect.top, rect.bottom);
      final dx = position.x - closestX;
      final dy = position.y - closestY;
      final distSq = dx * dx + dy * dy;
      if (distSq < playerRadius * playerRadius && distSq > 0.0001) {
        final dist = sqrt(distSq);
        position.x += (dx / dist) * (playerRadius - dist);
        position.y += (dy / dist) * (playerRadius - dist);
      }
    }

    // Clamp to arena
    position.x = position.x.clamp(40, game.arenaSize.x - 40);
    position.y = position.y.clamp(40, game.arenaSize.y - 40);

    // Lantern decay in dungeon
    var fuel = state.lanternFuel;
    if (state.zone == GameZone.hviskerotDungeon) {
      fuel = max(0, fuel - GameBalance.lanternDecayPerSecond * dt);
    }

    state.updateVitals(
      hp: hp,
      stamina: stamina,
      lanternFuel: fuel,
      skillCooldownRemaining: _skillCooldownTimer,
    );
  }

  SpriteAnimationTicker _currentTicker() {
    final bool horizontal = facing.x.abs() > facing.y.abs();
    final String dirKey = horizontal
        ? 'Side'
        : (facing.y < 0 ? 'Up' : 'Down');
    if (_slashVisualTimer > 0) {
      return _anims['attack$dirKey']!;
    }
    if (_isMoving || isDashing) {
      return _anims['walk$dirKey']!;
    }
    return _anims['idle$dirKey']!;
  }

  void _tryDash(Vector2 moveDir) {
    if (stamina < GameBalance.dashStaminaCost) {
      game.world.add(
        FloatingTextComponent(
          text: 'Low Stamina',
          position: position.clone()..y -= 22,
          color: const Color(0xFF90CAF9),
          fontSize: 11,
        ),
      );
      return;
    }
    stamina -= GameBalance.dashStaminaCost;
    _staminaRegenDelayTimer = GameBalance.staminaRegenDelay;
    _dashTimer = GameBalance.dashDuration;
    _iFrameTimer = GameBalance.dashIFrameDuration;
    _dashDir = moveDir.length2 > 0.01 ? moveDir.normalized() : facing.clone();
  }

  void _tryBasicAttack() {
    if (stamina < GameBalance.attackStaminaCost) return;
    stamina -= GameBalance.attackStaminaCost;
    _staminaRegenDelayTimer = GameBalance.staminaRegenDelay * 0.7;

    _comboStep = (_comboStep % 3) + 1;
    _comboWindowTimer = GameBalance.comboResetWindow;
    _attackCooldownTimer = GameBalance.attackCooldown;
    _slashVisualTimer = 0.16;
    if (_spriteLoaded) {
      _anims['attackDown']?.reset();
      _anims['attackSide']?.reset();
      _anims['attackUp']?.reset();
    }

    final damage = CombatCalculator.calculateComboDamage(
      baseDamage: 18.0,
      comboStep: _comboStep,
    );

    final attackCenter = position + facing * 34;
    for (final enemy in game.world.children.whereType<EnemyComponent>()) {
      if (enemy.position.distanceTo(attackCenter) <= 44) {
        enemy.takeDamage(damage, position);
        game.world.add(HitSparkComponent(position: enemy.position.clone()));
        game.triggerScreenShake(3.0);
      }
    }
  }

  void _tryWeaponSkill() {
    if (stamina < GameBalance.weaponSkillStaminaCost) return;
    stamina -= GameBalance.weaponSkillStaminaCost;
    _staminaRegenDelayTimer = GameBalance.staminaRegenDelay;
    _skillCooldownTimer = GameBalance.weaponSkillCooldown;
    _skillVisualTimer = 0.28;

    game.world.add(
      FloatingTextComponent(
        text: 'EMBER CLEAVE!',
        position: position.clone()..y -= 28,
        color: const Color(0xFFFF8A65),
        fontSize: 13,
      ),
    );
    game.world.add(
      HitSparkComponent(
        position: position.clone(),
        color: const Color(0xFFFF7043),
        count: 14,
        speed: 220,
      ),
    );

    for (final enemy in game.world.children.whereType<EnemyComponent>()) {
      if (enemy.position.distanceTo(position) <= 84) {
        enemy.takeDamage(34.0, position);
        game.world.add(
          HitSparkComponent(
            position: enemy.position.clone(),
            color: const Color(0xFFFF7043),
          ),
        );
        game.triggerScreenShake(6.0);
      }
    }
  }

  void takeDamage(double amount, Vector2 sourcePos) {
    if (isInvulnerable) {
      game.world.add(
        FloatingTextComponent(
          text: 'DODGED!',
          position: position.clone()..y -= 24,
          color: const Color(0xFF80DEEA),
          fontSize: 12,
        ),
      );
      return;
    }

    hp = max(0, hp - amount);
    _iFrameTimer = 0.55;
    game.triggerScreenShake(7.0);

    game.world.add(
      FloatingTextComponent(
        text: '-${amount.round()}',
        position: position.clone()..y -= 22,
        color: const Color(0xFFFF5252),
      ),
    );

    if (hp <= 0) {
      game.onPlayerDefeated();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Skill 360 rune ring
    if (_skillVisualTimer > 0) {
      final t = _skillVisualTimer / 0.28;
      canvas.drawCircle(
        center,
        82 * (1 - t * 0.25),
        Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: 0.45 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }

    // Melee slash arc
    if (_slashVisualTimer > 0) {
      final angle = atan2(facing.y, facing.x);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final arcRect = Rect.fromCircle(center: const Offset(16, 0), radius: 28);
      canvas.drawArc(
        arcRect,
        -0.95,
        1.9,
        false,
        Paint()
          ..color = _comboStep == 3
              ? const Color(0xFFFFB74D)
              : const Color(0xFFE0F7FA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _comboStep == 3 ? 6 : 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, size.y - 2), width: 22, height: 8),
      Paint()..color = Colors.black45,
    );

    // Invulnerable blink / Dash ghost tint
    final alpha = isDashing
        ? 0.65
        : (isInvulnerable && (DateTime.now().millisecond % 140 < 70)
            ? 0.45
            : 1.0);

    if (_spriteLoaded) {
      final sprite = _currentTicker().getSprite();
      final flipX = facing.x < -0.1 && facing.x.abs() >= facing.y.abs();
      canvas.save();
      canvas.translate(center.dx, center.dy - 4);
      if (flipX) {
        canvas.scale(-1, 1);
      }
      sprite.render(
        canvas,
        position: Vector2(-36, -36),
        size: Vector2.all(72),
        overridePaint: Paint()
          ..filterQuality = FilterQuality.none
          ..color = Colors.white.withValues(alpha: alpha),
      );
      canvas.restore();
      return;
    }

    final bobY = sin(_walkBobTimer) * 1.5;

    // Nordic cloak (teal-slate)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 3 + bobY),
          width: 22,
          height: 20,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF2E7D8B).withValues(alpha: alpha),
    );

    // Head
    canvas.drawCircle(
      Offset(center.dx, center.dy - 7 + bobY),
      8,
      Paint()..color = const Color(0xFFFFCCBC).withValues(alpha: alpha),
    );

    // Nordic blade in hand
    final faceAngle = atan2(facing.y, facing.x);
    final swingOffset = _slashVisualTimer > 0
        ? (_comboStep.isEven ? -0.9 : 0.9) * (_slashVisualTimer / 0.16)
        : 0.0;
    canvas.save();
    canvas.translate(center.dx, center.dy + 2 + bobY);
    canvas.rotate(faceAngle + swingOffset);
    canvas.drawLine(
      const Offset(8, 5),
      const Offset(24, 5),
      Paint()
        ..color = const Color(0xFFCFD8DC).withValues(alpha: alpha)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(10, 1),
      const Offset(10, 9),
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: alpha)
        ..strokeWidth = 2.2,
    );
    canvas.restore();

    // Cracked Lantern glow dot at hip
    canvas.drawCircle(
      Offset(center.dx - facing.x * 7, center.dy + 4 + bobY),
      4,
      Paint()..color = const Color(0xFFFFB74D).withValues(alpha: alpha),
    );
  }
}
