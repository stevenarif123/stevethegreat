import 'package:flame/components.dart';

/// Unified input state fed by both PC keyboard and Mobile virtual controls.
class HybridInputState {
  Vector2 keyboardMove = Vector2.zero();
  Vector2 joystickMove = Vector2.zero();
  Vector2? mouseAimDirection;

  bool attackPressed = false;
  bool dashPressed = false;
  bool skillPressed = false;
  bool interactPressed = false;
  bool useOilPressed = false;

  /// Combines joystick and keyboard input into a normalized direction vector.
  Vector2 get moveDirection {
    final combined = joystickMove.length2 > 0.01 ? joystickMove : keyboardMove;
    if (combined.length2 > 1.0) {
      return combined.normalized();
    }
    return combined;
  }

  void clearOneShotActions() {
    attackPressed = false;
    dashPressed = false;
    skillPressed = false;
    interactPressed = false;
    useOilPressed = false;
  }
}
