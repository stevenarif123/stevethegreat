import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/state/game_session_state.dart';
import '../emberlight_game.dart';

class ArenaFloorComponent extends PositionComponent
    with HasGameReference<EmberlightGame> {
  ArenaFloorComponent({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: 0);

  Sprite? _grassTile;
  final List<Sprite> _dungeonFloors = [];
  Sprite? _wallMid;
  Sprite? _wallBannerGreen;
  bool _tilesLoaded = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final grassImg = await game.images.load(
        'mystic_woods/sprites/tilesets/grass.png',
      );
      _grassTile = Sprite(grassImg);

      for (int i = 1; i <= 8; i++) {
        final floorImg = await game.images.load(
          'dungeon_0x72/0x72_DungeonTilesetII_v1.7/frames/floor_$i.png',
        );
        _dungeonFloors.add(Sprite(floorImg));
      }

      _wallMid = Sprite(
        await game.images.load(
          'dungeon_0x72/0x72_DungeonTilesetII_v1.7/frames/wall_mid.png',
        ),
      );
      _wallBannerGreen = Sprite(
        await game.images.load(
          'dungeon_0x72/0x72_DungeonTilesetII_v1.7/frames/wall_banner_green.png',
        ),
      );
      _tilesLoaded = true;
    } catch (_) {
      _tilesLoaded = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final isCamp = game.sessionState.zone == GameZone.eldvikCamp;
    const tileSize = 32.0;
    final pixelPaint = Paint()..filterQuality = FilterQuality.none;

    if (_tilesLoaded) {
      final cols = (size.x / tileSize).ceil();
      final rows = (size.y / tileSize).ceil();

      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          final pos = Vector2(x * tileSize, y * tileSize);
          final tileVec = Vector2.all(tileSize);

          if (isCamp && _grassTile != null) {
            _grassTile!.render(
              canvas,
              position: pos,
              size: tileVec,
              overridePaint: pixelPaint,
            );
          } else if (!isCamp && _dungeonFloors.isNotEmpty) {
            // Deterministic variation so floor stones look hand-laid
            final hash = ((x * 73856093) ^ (y * 19349663)).abs();
            final idx = (hash % 10 < 6) ? 0 : (hash % _dungeonFloors.length);
            _dungeonFloors[idx].render(
              canvas,
              position: pos,
              size: tileVec,
              overridePaint: pixelPaint,
            );
          }
        }
      }

      if (isCamp) {
        _renderCampPathAndHearth(canvas);
      } else {
        _renderDungeonWalls(canvas, tileSize, pixelPaint);
      }
      return;
    }

    // Fallback plain ground if assets unavailable
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = isCamp ? const Color(0xFF28362B) : const Color(0xFF171E24),
    );
  }

  void _renderCampPathAndHearth(Canvas canvas) {
    // Cozy dirt path from cabin/campfire to Hviskerot portal
    final pathPaint = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.72);
    final borderPaint = Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.45);
    final pathRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x * 0.23, size.y * 0.47, size.x * 0.52, 42),
      const Radius.circular(18),
    );
    canvas.drawRRect(pathRect.inflate(3), borderPaint);
    canvas.drawRRect(pathRect, pathPaint);

    // Stone-ringed Hearthfire in Eldvik Camp
    final hearthCenter = Offset(size.x * 0.27, size.y * 0.50);
    canvas.drawCircle(
      hearthCenter,
      64,
      Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.14),
    );

    // Ring of stones
    for (int i = 0; i < 8; i++) {
      final a = (pi * 2 * i) / 8;
      canvas.drawCircle(
        Offset(
          hearthCenter.dx + cos(a) * 18,
          hearthCenter.dy + sin(a) * 15,
        ),
        5.5,
        Paint()..color = const Color(0xFF78909C),
      );
    }

    // Crossed logs
    final logPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(hearthCenter.dx - 11, hearthCenter.dy - 6),
      Offset(hearthCenter.dx + 11, hearthCenter.dy + 6),
      logPaint,
    );
    canvas.drawLine(
      Offset(hearthCenter.dx - 11, hearthCenter.dy + 6),
      Offset(hearthCenter.dx + 11, hearthCenter.dy - 6),
      logPaint,
    );

    // Warm flame core
    canvas.drawCircle(
      hearthCenter,
      9,
      Paint()..color = const Color(0xFFFF9800),
    );
    canvas.drawCircle(
      Offset(hearthCenter.dx, hearthCenter.dy - 2),
      5,
      Paint()..color = const Color(0xFFFFF176),
    );
  }

  void _renderDungeonWalls(
    Canvas canvas,
    double tileSize,
    Paint pixelPaint,
  ) {
    if (_wallMid == null) return;
    final cols = (size.x / tileSize).ceil();

    // Top stone wall row
    for (int x = 0; x < cols; x++) {
      final sprite = (x % 7 == 3 && _wallBannerGreen != null)
          ? _wallBannerGreen!
          : _wallMid!;
      sprite.render(
        canvas,
        position: Vector2(x * tileSize, 0),
        size: Vector2.all(tileSize),
        overridePaint: pixelPaint,
      );
    }

    // Left, right, bottom dark stone border
    final borderPaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0;
    canvas.drawRect(
      Rect.fromLTWH(11, 24, size.x - 22, size.y - 35),
      borderPaint,
    );
  }
}
