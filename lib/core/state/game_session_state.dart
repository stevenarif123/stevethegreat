import 'package:flutter/foundation.dart';
import '../constants/game_balance.dart';
import '../models/loot_item.dart';
import '../services/combat_calculator.dart';

enum GameZone { eldvikCamp, hviskerotDungeon }

enum RunStatus { active, extracted, defeated }

class GameSessionState extends ChangeNotifier {
  GameZone zone = GameZone.eldvikCamp;
  RunStatus runStatus = RunStatus.active;

  double hp = GameBalance.playerMaxHp;
  double maxHp = GameBalance.playerMaxHp;
  double stamina = GameBalance.playerMaxStamina;
  double maxStamina = GameBalance.playerMaxStamina;
  double lanternFuel = GameBalance.maxLanternFuel;

  double skillCooldownRemaining = 0.0;
  int lanternOils = 2;
  int floor = 1;
  int silverCoins = 0;

  final List<LootItem> backpack = [];
  ExtractionOutcome? lastOutcome;
  String? interactPrompt;

  bool get isShadowEnraged =>
      zone == GameZone.hviskerotDungeon &&
      lanternFuel < GameBalance.lowLanternThreshold;

  void enterDungeon({int startFloor = 1}) {
    zone = GameZone.hviskerotDungeon;
    runStatus = RunStatus.active;
    floor = startFloor;
    hp = maxHp;
    stamina = maxStamina;
    lanternFuel = GameBalance.maxLanternFuel;
    lanternOils = 2;
    skillCooldownRemaining = 0;
    backpack.clear();
    lastOutcome = null;
    notifyListeners();
  }

  void returnToCamp() {
    zone = GameZone.eldvikCamp;
    runStatus = RunStatus.active;
    hp = maxHp;
    stamina = maxStamina;
    lanternFuel = GameBalance.maxLanternFuel;
    skillCooldownRemaining = 0;
    interactPrompt = null;
    notifyListeners();
  }

  void updateVitals({
    required double hp,
    required double stamina,
    required double lanternFuel,
    required double skillCooldownRemaining,
  }) {
    this.hp = hp.clamp(0, maxHp);
    this.stamina = stamina.clamp(0, maxStamina);
    this.lanternFuel = lanternFuel.clamp(0, GameBalance.maxLanternFuel);
    this.skillCooldownRemaining = skillCooldownRemaining.clamp(0, 99);
    notifyListeners();
  }

  bool addLoot(LootItem item) {
    if (backpack.length >= GameBalance.maxBackpackSlots) {
      return false;
    }
    final safeCount = backpack.where((e) => e.isSafePocket).length;
    final markSafe = safeCount < GameBalance.safePocketSlots;
    backpack.add(item.copyWith(isSafePocket: markSafe));
    notifyListeners();
    return true;
  }

  bool useLanternOil() {
    if (lanternOils <= 0 || zone != GameZone.hviskerotDungeon) return false;
    lanternOils--;
    lanternFuel = (lanternFuel + GameBalance.lanternOilRestoreAmount)
        .clamp(0, GameBalance.maxLanternFuel);
    notifyListeners();
    return true;
  }

  void finishRun({required bool extractedSafely}) {
    runStatus = extractedSafely ? RunStatus.extracted : RunStatus.defeated;
    lastOutcome = CombatCalculator.resolveRunLoot(
      backpack: backpack,
      extractedSafely: extractedSafely,
    );
    silverCoins += lastOutcome!.totalSilverEarned;
    backpack.clear();
    notifyListeners();
  }

  void setInteractPrompt(String? prompt) {
    if (interactPrompt == prompt) return;
    interactPrompt = prompt;
    notifyListeners();
  }
}
