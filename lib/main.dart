import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'core/input/hybrid_input_state.dart';
import 'core/state/game_session_state.dart';
import 'game/emberlight_game.dart';
import 'ui/hud_overlay.dart';
import 'ui/run_summary_modal.dart';

void main() {
  runApp(const EmberlightApp());
}

class EmberlightApp extends StatefulWidget {
  const EmberlightApp({super.key});

  @override
  State<EmberlightApp> createState() => _EmberlightAppState();
}

class _EmberlightAppState extends State<EmberlightApp> {
  late final GameSessionState _sessionState;
  late final HybridInputState _inputState;
  late final EmberlightGame _game;

  @override
  void initState() {
    super.initState();
    _sessionState = GameSessionState();
    _inputState = HybridInputState();
    _game = EmberlightGame(
      sessionState: _sessionState,
      inputState: _inputState,
    );
  }

  @override
  void dispose() {
    _sessionState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emberlight: Saga of Eldvik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0E1318),
        body: GameWidget<EmberlightGame>(
          game: _game,
          initialActiveOverlays: const ['hud'],
          overlayBuilderMap: {
            'hud': (context, game) => HudOverlay(
                  game: game,
                  state: _sessionState,
                  input: _inputState,
                ),
            'runSummary': (context, game) => RunSummaryModal(
                  game: game,
                  state: _sessionState,
                ),
          },
        ),
      ),
    );
  }
}
