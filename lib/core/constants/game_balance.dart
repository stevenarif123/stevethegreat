/// Centralized tuning constants for Emberlight: Saga of Eldvik.
class GameBalance {
  GameBalance._();

  // Player stats
  static const double playerMaxHp = 100.0;
  static const double playerMaxStamina = 100.0;
  static const double playerMoveSpeed = 185.0;

  // Stamina & Dash
  static const double dashStaminaCost = 25.0;
  static const double dashDuration = 0.18;
  static const double dashSpeed = 480.0;
  static const double dashIFrameDuration = 0.25;
  static const double staminaRegenPerSecond = 28.0;
  static const double staminaRegenDelay = 0.6;

  // Combat
  static const double attackStaminaCost = 8.0;
  static const double attackCooldown = 0.26;
  static const double comboResetWindow = 0.75;
  static const double weaponSkillCooldown = 4.0;
  static const double weaponSkillStaminaCost = 20.0;

  // Lantern & Risk-Reward
  static const double maxLanternFuel = 100.0;
  static const double lanternDecayPerSecond = 1.6;
  static const double lowLanternThreshold = 25.0; // <25% triggers Shadow Enrage
  static const double lowLanternRareDropBonus = 0.35;
  static const double lanternOilRestoreAmount = 40.0;

  // Bag & Safe Pocket
  static const int maxBackpackSlots = 12;
  static const int safePocketSlots = 2;
}
