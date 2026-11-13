enum LootRarity { common, uncommon, rare }

class LootItem {
  const LootItem({
    required this.id,
    required this.name,
    required this.silverValue,
    required this.rarity,
    this.isSafePocket = false,
  });

  final String id;
  final String name;
  final int silverValue;
  final LootRarity rarity;
  final bool isSafePocket;

  LootItem copyWith({bool? isSafePocket}) {
    return LootItem(
      id: id,
      name: name,
      silverValue: silverValue,
      rarity: rarity,
      isSafePocket: isSafePocket ?? this.isSafePocket,
    );
  }
}
