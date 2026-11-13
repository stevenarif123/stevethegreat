import 'dart:math';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../core/input/hybrid_input_state.dart';
import '../core/state/game_session_state.dart';
import 'components/arena_floor_component.dart';
import 'components/enemy_component.dart';
import 'components/floating_text_component.dart';
import 'components/lantern_darkness_overlay.dart';
import 'components/loot_drop_component.dart';
import 'components/pillar_component.dart';
import 'components/player_component.dart';
import 'components/portal_component.dart';
import 'components/telegraph_component.dart';
import 'components/world_prop_component.dart';

class EmberlightGame extends FlameGame with KeyboardEvents, TapCallbacks {
  EmberlightGame({
    required this.sessionState,
    required this.inputState,
  });

  final GameSessionState sessionState;
  final HybridInputState inputState;

  final Vector2 arenaSize = Vector2(896, 640);
  late PlayerComponent player;
  final List<Rect> tiledCollisions = [];

  final Set<LogicalKeyboardKey> _heldKeys = {};
  double _shakeTimer = 0.0;
  double _shakeIntensity = 0.0;
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera = CameraComponent.withFixedResolution(width: 800, height: 450);
    camera.viewport.add(LanternDarknessOverlay());

    player = PlayerComponent(position: Vector2(arenaSize.x * 0.45, arenaSize.y * 0.5));
    await _loadEldvikCamp();
  }

  Future<void> _clearWorld() async {
    tiledCollisions.clear();
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }
  }

  Future<void> _loadEldvikCamp() async {
    await _clearWorld();
    sessionState.returnToCamp();

    var spawnPos = Vector2(arenaSize.x * 0.42, arenaSize.y * 0.52);
    var portalPos = Vector2(arenaSize.x * 0.78, arenaSize.y * 0.5);

    try {
      final tiledMap = await TiledComponent.load(
        'eldvik_camp.tmx',
        Vector2.all(32),
        images: images,
      );
      tiledMap.priority = 0;
      world.add(tiledMap);

      // Parse Collisions object layer (source 16px -> dest 32px = 2x scale)
      final collisionsLayer = tiledMap.tileMap.getLayer<ObjectGroup>('Collisions');
      if (collisionsLayer != null) {
        for (final obj in collisionsLayer.objects) {
          tiledCollisions.add(
            Rect.fromLTWH(
              obj.x * 2,
              obj.y * 2,
              obj.width * 2,
              obj.height * 2,
            ),
          );
        }
      }

      // Parse Objects layer (spawn & portal)
      final objectsLayer = tiledMap.tileMap.getLayer<ObjectGroup>('Objects');
      if (objectsLayer != null) {
        for (final obj in objectsLayer.objects) {
          if (obj.name == 'player_spawn') {
            spawnPos = Vector2(obj.x * 2, obj.y * 2);
          } else if (obj.name == 'portal_dungeon') {
            portalPos = Vector2(obj.x * 2, obj.y * 2);
          }
        }
      }
    } catch (_) {
      // Fallback ground if .tmx cannot be loaded
      world.add(ArenaFloorComponent(size: arenaSize));
    }

    player.resetForZone(spawnPos, fullRestore: true);
    world.add(player);

    world.add(
      PortalComponent(
        position: portalPos,
        kind: PortalKind.enterDungeon,
        label: 'Enter Hviskerot [E]',
      ),
    );

    // Cozy camp torches
    world.add(TorchComponent(position: Vector2(arenaSize.x * 0.27, arenaSize.y * 0.34)));
    world.add(TorchComponent(position: Vector2(arenaSize.x * 0.27, arenaSize.y * 0.66)));
    world.add(TorchComponent(position: Vector2(arenaSize.x * 0.72, arenaSize.y * 0.36)));
    world.add(TorchComponent(position: Vector2(arenaSize.x * 0.72, arenaSize.y * 0.64)));

    _populateCampProps();

    camera.follow(player);
  }

  Future<void> _populateCampProps() async {
    // Cozy Nordic Cabin at top-left
    world.add(CabinComponent(position: Vector2(185, 138)));

    Sprite? tallTree;
    Sprite? roundTree;
    Sprite? berryTree;
    Sprite? bush;
    Sprite? rock;
    Sprite? log;
    Sprite? mushroom;
    Sprite? chest;

    try {
      final biomImg = await images.load(
        'sprout_lands/Sprout Lands - Sprites - Basic pack/Objects/Basic_Grass_Biom_things.png',
      );
      tallTree = Sprite(biomImg, srcPosition: Vector2(0, 0), srcSize: Vector2(16, 32));
      roundTree = Sprite(biomImg, srcPosition: Vector2(16, 0), srcSize: Vector2(32, 32));
      berryTree = Sprite(biomImg, srcPosition: Vector2(48, 0), srcSize: Vector2(32, 32));
      bush = Sprite(biomImg, srcPosition: Vector2(16, 48), srcSize: Vector2(16, 16));
      rock = Sprite(biomImg, srcPosition: Vector2(128, 16), srcSize: Vector2(16, 16));
      log = Sprite(biomImg, srcPosition: Vector2(80, 32), srcSize: Vector2(16, 16));
      mushroom = Sprite(biomImg, srcPosition: Vector2(80, 0), srcSize: Vector2(16, 16));

      final chestImg = await images.load(
        'mystic_woods/sprites/objects/chest_01.png',
      );
      chest = Sprite(chestImg, srcPosition: Vector2(0, 0), srcSize: Vector2(16, 16));
    } catch (_) {}

    // Storage chest near cabin & campfire
    world.add(
      WorldPropComponent(
        kind: WorldPropKind.chest,
        position: Vector2(282, 168),
        collisionRadius: 14,
        sprite: chest,
        renderSize: Vector2.all(32),
      ),
    );

    // Forest grove perimeter around Eldvik Camp
    final treeSpots = <Vector2>[
      Vector2(70, 75),
      Vector2(345, 70),
      Vector2(455, 68),
      Vector2(575, 72),
      Vector2(700, 75),
      Vector2(825, 85),
      Vector2(835, 200),
      Vector2(835, 430),
      Vector2(820, 545),
      Vector2(690, 555),
      Vector2(560, 558),
      Vector2(420, 555),
      Vector2(290, 552),
      Vector2(150, 545),
      Vector2(70, 495),
      Vector2(68, 365),
      Vector2(68, 240),
    ];

    for (int i = 0; i < treeSpots.length; i++) {
      final isTall = i % 3 == 0;
      final isBerry = i % 4 == 1;
      world.add(
        WorldPropComponent(
          kind: isTall
              ? WorldPropKind.tallTree
              : (isBerry ? WorldPropKind.berryTree : WorldPropKind.roundTree),
          position: treeSpots[i],
          collisionRadius: isTall ? 18 : 24,
          sprite: isTall ? tallTree : (isBerry ? berryTree : roundTree),
          renderSize: isTall ? Vector2(36, 72) : Vector2(68, 68),
        ),
      );
    }

    // Cozy details: bushes, rocks, logs, mushrooms
    final detailSpots = [
      (WorldPropKind.log, Vector2(205, 345), log, 14.0),
      (WorldPropKind.rock, Vector2(380, 140), rock, 14.0),
      (WorldPropKind.rock, Vector2(620, 455), rock, 14.0),
      (WorldPropKind.bush, Vector2(510, 150), bush, 12.0),
      (WorldPropKind.bush, Vector2(495, 470), bush, 12.0),
      (WorldPropKind.mushroom, Vector2(355, 485), mushroom, 0.0),
      (WorldPropKind.mushroom, Vector2(650, 150), mushroom, 0.0),
    ];

    for (final d in detailSpots) {
      world.add(
        WorldPropComponent(
          kind: d.$1,
          position: d.$2,
          sprite: d.$3,
          collisionRadius: d.$4,
          renderSize: Vector2.all(32),
        ),
      );
    }
  }

  Future<void> _loadDungeonFloor(int floor) async {
    await _clearWorld();
    if (floor == 1) {
      sessionState.enterDungeon(startFloor: 1);
    } else {
      sessionState.floor = floor;
    }

    world.add(ArenaFloorComponent(size: arenaSize));
    player.resetForZone(
      Vector2(110, arenaSize.y * 0.5),
      fullRestore: floor == 1,
    );
    world.add(player);

    // Extraction Gate (left side, always unlocked)
    world.add(
      PortalComponent(
        position: Vector2(95, arenaSize.y * 0.28),
        kind: PortalKind.extractToCamp,
        label: 'Extract to Eldvik [E]',
      ),
    );

    // Descend Gate (right side, unlocks when enemies cleared)
    if (floor < 3) {
      world.add(
        PortalComponent(
          position: Vector2(arenaSize.x - 105, arenaSize.y * 0.5),
          kind: PortalKind.descendFloor,
          label: 'Floor ${floor + 1} [E]',
          locked: true,
        ),
      );
    }

    // Tactical Nordic rune pillars + dungeon crates + wall torches
    world.add(PillarComponent(position: Vector2(arenaSize.x * 0.38, arenaSize.y * 0.33)));
    world.add(PillarComponent(position: Vector2(arenaSize.x * 0.38, arenaSize.y * 0.67)));
    world.add(PillarComponent(position: Vector2(arenaSize.x * 0.64, arenaSize.y * 0.50)));

    try {
      final crateImg = await images.load(
        'dungeon_0x72/0x72_DungeonTilesetII_v1.7/frames/crate.png',
      );
      final crateSprite = Sprite(crateImg);
      world.add(
        WorldPropComponent(
          kind: WorldPropKind.crate,
          position: Vector2(180, 130),
          collisionRadius: 15,
          sprite: crateSprite,
          renderSize: Vector2.all(32),
        ),
      );
      world.add(
        WorldPropComponent(
          kind: WorldPropKind.crate,
          position: Vector2(215, 138),
          collisionRadius: 15,
          sprite: crateSprite,
          renderSize: Vector2.all(32),
        ),
      );
      world.add(
        WorldPropComponent(
          kind: WorldPropKind.crate,
          position: Vector2(arenaSize.x - 160, arenaSize.y - 120),
          collisionRadius: 15,
          sprite: crateSprite,
          renderSize: Vector2.all(32),
        ),
      );
    } catch (_) {}

    world.add(TorchComponent(position: Vector2(70, 70)));
    world.add(TorchComponent(position: Vector2(arenaSize.x - 70, 70)));
    world.add(TorchComponent(position: Vector2(70, arenaSize.y - 70)));
    world.add(TorchComponent(position: Vector2(arenaSize.x - 70, arenaSize.y - 70)));

    // Spawn enemies scaling with floor
    final enemyCount = 3 + floor;
    for (int i = 0; i < enemyCount; i++) {
      final kind = i.isEven ? EnemyKind.brambleSlime : EnemyKind.frostThornHound;
      final spawnPos = Vector2(
        340 + _rng.nextDouble() * (arenaSize.x - 460),
        100 + _rng.nextDouble() * (arenaSize.y - 200),
      );
      world.add(EnemyComponent(kind: kind, position: spawnPos, floor: floor));
    }

    camera.follow(player);
  }

  void onEnemyDefeated() {
    final remaining = world.children.whereType<EnemyComponent>().length - 1;
    if (remaining <= 0) {
      for (final portal in world.children.whereType<PortalComponent>()) {
        portal.locked = false;
      }
      world.add(
        FloatingTextComponent(
          text: 'FLOOR CLEARED!',
          position: player.position.clone()..y -= 36,
          color: const Color(0xFF80CBC4),
          fontSize: 16,
        ),
      );
    }
  }

  void tryInteract() {
    for (final portal in world.children.whereType<PortalComponent>()) {
      if (portal.position.distanceTo(player.position) <= 62) {
        if (portal.locked) {
          world.add(
            FloatingTextComponent(
              text: 'Defeat enemies first!',
              position: player.position.clone()..y -= 28,
              color: const Color(0xFFFF8A80),
              fontSize: 12,
            ),
          );
          return;
        }
        switch (portal.kind) {
          case PortalKind.enterDungeon:
            _loadDungeonFloor(1);
            return;
          case PortalKind.descendFloor:
            _loadDungeonFloor(sessionState.floor + 1);
            return;
          case PortalKind.extractToCamp:
            sessionState.finishRun(extractedSafely: true);
            overlays.add('runSummary');
            return;
        }
      }
    }
  }

  void onPlayerDefeated() {
    // Clean active telegraphs so nothing lingers
    for (final t in world.children.whereType<TelegraphComponent>().toList()) {
      t.removeFromParent();
    }
    sessionState.finishRun(extractedSafely: false);
    overlays.add('runSummary');
  }

  Future<void> returnToCampFromOverlay() async {
    overlays.remove('runSummary');
    await _loadEldvikCamp();
  }

  void triggerScreenShake(double intensity) {
    _shakeIntensity = intensity;
    _shakeTimer = 0.12;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Y-Sorting for natural 2.5D depth
    player.priority = player.position.y.round();
    for (final enemy in world.children.whereType<EnemyComponent>()) {
      enemy.priority = enemy.position.y.round();
    }

    // Update interact prompt
    String? prompt;
    for (final portal in world.children.whereType<PortalComponent>()) {
      if (portal.position.distanceTo(player.position) <= 62) {
        prompt = portal.locked ? 'Clear all enemies to unlock' : portal.label;
        break;
      }
    }
    sessionState.setInteractPrompt(prompt);

    // Screen shake offset
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      camera.viewfinder.position = player.position +
          Vector2(
            (_rng.nextDouble() - 0.5) * 2 * _shakeIntensity,
            (_rng.nextDouble() - 0.5) * 2 * _shakeIntensity,
          );
    }

    // Remove unused loot drops if returning to camp
    if (sessionState.zone == GameZone.eldvikCamp) {
      for (final drop in world.children.whereType<LootDropComponent>().toList()) {
        drop.removeFromParent();
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (sessionState.runStatus != RunStatus.active) return;
    final worldTap = camera.globalToLocal(event.canvasPosition);
    final dir = worldTap - player.position;
    if (dir.length2 > 1) {
      inputState.mouseAimDirection = dir.normalized();
    }
    inputState.attackPressed = true;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _heldKeys
      ..clear()
      ..addAll(keysPressed);

    final move = Vector2.zero();
    if (_heldKeys.contains(LogicalKeyboardKey.keyW) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowUp)) {
      move.y -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyS) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowDown)) {
      move.y += 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyA) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      move.x -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyD) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowRight)) {
      move.x += 1;
    }
    inputState.keyboardMove = move;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        inputState.attackPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        inputState.dashPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        inputState.skillPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        inputState.interactPressed = true;
      } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        inputState.useOilPressed = true;
      }
    }

    return KeyEventResult.handled;
  }
}
