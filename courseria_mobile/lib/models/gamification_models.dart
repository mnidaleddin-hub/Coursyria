class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int pointsReward;
  final String rarity;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.pointsReward,
    required this.rarity,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
      pointsReward: json['points_reward'] ?? 0,
      rarity: json['rarity'] ?? 'common',
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
    );
  }

  bool get isUnlocked => unlockedAt != null;
}

class Sticker {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final DateTime? purchasedAt;

  Sticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    this.purchasedAt,
  });

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      price: json['price'] ?? 0,
      purchasedAt: json['purchased_at'] != null ? DateTime.parse(json['purchased_at']) : null,
    );
  }

  bool get isPurchased => purchasedAt != null;
}
