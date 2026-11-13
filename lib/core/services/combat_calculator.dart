import '../constants/game_balance.dart';
import '../models/loot_item.dart';

class ExtractionOutcome {
  const ExtractionOutcome({
    required this.keptItems,
    required this.lostItems,
    required this.totalSilverEarned,
  });

  final List<LootItem> keptItems;
  final List<LootItem> lostItems;
  final int totalSilverEarned;
}

/// Pure Dart combat & extraction calculations (unit-tested independently).
class CombatCalculator {
  const CombatCalculator._();

  static double calculateComboDamage({
    required double baseDamage,
    required int comboStep,
  }) {
    switch (comboStep) {
      case 1:
        return baseDamage;
      case 2:
        return baseDamage * 1.15;
      case 3:
        return baseDamage * 1.45;
      default:
        return baseDamage;
    }
  }

  static double effectiveRareDropChance({
    required double baseChance,
    required double lanternFuel,
    required int floor,
  }) {
    final floorBonus = (floor - 1) * 0.10;
    final lanternBonus = lanternFuel < GameBalance.lowLanternThreshold
        ? GameBalance.lowLanternRareDropBonus
        : 0.0;
    return (baseChance + floorBonus + lanternBonus).clamp(0.0, 0.95);
  }

  /// Resolves what the player keeps on extraction vs defeat.
  /// On defeat, only items marked [LootItem.isSafePocket] survive.
  static ExtractionOutcome resolveRunLoot({
    required List<LootItem> backpack,
    required bool extractedSafely,
  }) {
    if (extractedSafely) {
      final silver = backpack.fold<int>(0, (sum, item) => sum + item.silverValue);
      return ExtractionOutcome(
        keptItems: List.unmodifiable(backpack),
        lostItems: const [],
        totalSilverEarned: silver,
      );
    }

    final kept = backpack.where((item) => item.isSafePocket).toList();
    final lost = backpack.where((item) => !item.isSafePocket).toList();
    final silver = kept.fold<int>(0, (sum, item) => sum + item.silverValue);

    return ExtractionOutcome(
      keptItems: List.unmodifiable(kept),
      lostItems: List.unmodifiable(lost),
      totalSilverEarned: silver,
    );
  }
}
