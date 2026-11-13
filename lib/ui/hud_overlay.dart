import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import '../core/constants/game_balance.dart';
import '../core/input/hybrid_input_state.dart';
import '../core/state/game_session_state.dart';
import '../game/emberlight_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.game,
    required this.state,
    required this.input,
  });

  final EmberlightGame game;
  final GameSessionState state;
  final HybridInputState input;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final inDungeon = state.zone == GameZone.hviskerotDungeon;

        return SafeArea(
          child: Stack(
            children: [
              // Top-left vitals & status
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 265,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xCC11161C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.isShadowEnraged
                          ? const Color(0xFFAB47BC)
                          : const Color(0xFF37474F),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              inDungeon
                                  ? 'HVISKEROT • FL ${state.floor}/3'
                                  : 'ELDVIK CAMP (SAFE)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: inDungeon
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFF80CBC4),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${state.silverCoins} Ag',
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _StatBar(
                        label: 'HP',
                        value: state.hp,
                        max: state.maxHp,
                        color: const Color(0xFFE53935),
                      ),
                      const SizedBox(height: 4),
                      _StatBar(
                        label: 'STM',
                        value: state.stamina,
                        max: state.maxStamina,
                        color: const Color(0xFF29B6F6),
                      ),
                      if (inDungeon) ...[
                        const SizedBox(height: 4),
                        _StatBar(
                          label: 'LNT',
                          value: state.lanternFuel,
                          max: GameBalance.maxLanternFuel,
                          color: state.isShadowEnraged
                              ? const Color(0xFFAB47BC)
                              : const Color(0xFFFFA726),
                        ),
                        if (state.isShadowEnraged)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'SHADOW ENRAGE: +35% Rare Drop',
                              style: TextStyle(
                                color: Color(0xFFCE93D8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Top-right backpack summary
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC11161C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF37474F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bag ${state.backpack.length}/${GameBalance.maxBackpackSlots}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Safe Pocket: ${state.backpack.where((e) => e.isSafePocket).length}/${GameBalance.safePocketSlots}',
                        style: const TextStyle(
                          color: Color(0xFF80CBC4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Context Interact Prompt
              if (state.interactPrompt != null)
                Positioned(
                  bottom: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD1A232C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Text(
                        state.interactPrompt!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom-left Virtual Joystick
              Positioned(
                bottom: 20,
                left: 20,
                child: _VirtualJoystick(
                  onChanged: (vec) => input.joystickMove = vec,
                ),
              ),

              // Bottom-right Action Buttons
              Positioned(
                bottom: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.interactPrompt != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _ActionButton(
                              label: 'USE',
                              hint: 'E',
                              color: const Color(0xFFFFA726),
                              size: 52,
                              onTap: () => input.interactPressed = true,
                            ),
                          ),
                        if (inDungeon)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _ActionButton(
                              label: 'OIL (${state.lanternOils})',
                              hint: '1',
                              color: const Color(0xFFFFCA28),
                              size: 52,
                              onTap: () => input.useOilPressed = true,
                            ),
                          ),
                        _ActionButton(
                          label: state.skillCooldownRemaining > 0
                              ? state.skillCooldownRemaining.toStringAsFixed(1)
                              : 'SKILL',
                          hint: 'K',
                          color: state.skillCooldownRemaining > 0
                              ? const Color(0xFF455A64)
                              : const Color(0xFFFF7043),
                          size: 56,
                          onTap: () => input.skillPressed = true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          label: 'DASH',
                          hint: 'SPC',
                          color: const Color(0xFF29B6F6),
                          size: 58,
                          onTap: () => input.dashPressed = true,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          label: 'ATK',
                          hint: 'J',
                          color: const Color(0xFFEF5350),
                          size: 68,
                          onTap: () => input.attackPressed = true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFF263238),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 30,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.hint,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String label;
  final String hint;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.25),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              hint,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({required this.onChanged});

  final ValueChanged<Vector2> onChanged;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  static const double _radius = 48.0;
  Offset _knob = Offset.zero;

  void _updateKnob(Offset localPos) {
    final delta = localPos - const Offset(_radius, _radius);
    final dist = delta.distance;
    final clamped = dist > _radius ? delta * (_radius / dist) : delta;
    setState(() => _knob = clamped);
    widget.onChanged(Vector2(clamped.dx / _radius, clamped.dy / _radius));
  }

  void _resetKnob() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(Vector2.zero());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _updateKnob(d.localPosition),
      onPanUpdate: (d) => _updateKnob(d.localPosition),
      onPanEnd: (_) => _resetKnob(),
      onPanCancel: _resetKnob,
      child: Container(
        width: _radius * 2,
        height: _radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x6611161C),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: _knob,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xCC80CBC4),
                border: Border.all(color: Colors.white70, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
