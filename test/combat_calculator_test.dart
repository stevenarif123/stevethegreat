import 'package:flutter_test/flutter_test.dart';
import 'package:stevethegreat/core/constants/game_balance.dart';
import 'package:stevethegreat/core/models/loot_item.dart';
import 'package:stevethegreat/core/services/combat_calculator.dart';

void main() {
  group('CombatCalculator', () {
    test('3-hit combo scales damage properly', () {
      expect(
        CombatCalculator.calculateComboDamage(baseDamage: 20, comboStep: 1),
        20.0,
      );
      expect(
        CombatCalculator.calculateComboDamage(baseDamage: 20, comboStep: 2),
        closeTo(23.0, 0.001),
      );
      expect(
        CombatCalculator.calculateComboDamage(baseDamage: 20, comboStep: 3),
        closeTo(29.0, 0.001),
      );
    });

    test('low lantern fuel (<25%) grants +35% rare drop bonus', () {
      final normalChance = CombatCalculator.effectiveRareDropChance(
        baseChance: 0.15,
        lanternFuel: 60.0,
        floor: 1,
      );
      final enragedChance = CombatCalculator.effectiveRareDropChance(
        baseChance: 0.15,
        lanternFuel: GameBalance.lowLanternThreshold - 1,
        floor: 1,
      );

      expect(normalChance, closeTo(0.15, 0.001));
      expect(enragedChance, closeTo(0.50, 0.001));
    });

    test('extraction keeps all loot; defeat keeps only Safe Pocket items', () {
      final bag = [
        const LootItem(
          id: 'shard',
          name: 'Ember Shard',
          silverValue: 45,
          rarity: LootRarity.rare,
          isSafePocket: true,
        ),
        const LootItem(
          id: 'moss',
          name: 'Rune Moss',
          silverValue: 12,
          rarity: LootRarity.common,
          isSafePocket: false,
        ),
      ];

      final extracted = CombatCalculator.resolveRunLoot(
        backpack: bag,
        extractedSafely: true,
      );
      expect(extracted.keptItems.length, 2);
      expect(extracted.lostItems, isEmpty);
      expect(extracted.totalSilverEarned, 57);

      final defeated = CombatCalculator.resolveRunLoot(
        backpack: bag,
        extractedSafely: false,
      );
      expect(defeated.keptItems.length, 1);
      expect(defeated.keptItems.first.id, 'shard');
      expect(defeated.lostItems.length, 1);
      expect(defeated.totalSilverEarned, 45);
    });
  });
}
