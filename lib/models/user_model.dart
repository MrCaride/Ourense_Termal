class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedDate;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedDate,
  });
}

class RedeemedReward {
  final String id;
  final String rewardId;
  final String couponCode;
  final DateTime redeemedDate;
  bool used;

  RedeemedReward({
    required this.id,
    required this.rewardId,
    required this.couponCode,
    required this.redeemedDate,
    this.used = false,
  });
}

class User {
  final String id;
  final String name;
  final String email;
  int points;
  int level;
  DateTime joinedDate;
  List<AchievementBadge> badges;
  List<RedeemedReward> redeemedRewards;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.points = 0,
    this.level = 1,
    required this.joinedDate,
    this.badges = const [],
    this.redeemedRewards = const [],
  });

  // Sumar puntos
  void addPoints(int amount) {
    points += amount;
    _checkLevelUp();
  }

  // Verificar si sube de nivel
  void _checkLevelUp() {
    int requiredPoints = level * 300;
    if (points >= requiredPoints) {
      level++;
    }
  }

  // Desbloquear insignia
  void unlockBadge(AchievementBadge badge) {
    if (!badges.any((b) => b.id == badge.id)) {
      badges.add(badge);
    }
  }

  // Canjear recompensa
  void redeemReward(String rewardId, String couponCode) {
    redeemedRewards.add(
      RedeemedReward(
        id: DateTime.now().toString(),
        rewardId: rewardId,
        couponCode: couponCode,
        redeemedDate: DateTime.now(),
      ),
    );
  }

  String getLevelTitle() {
    if (level == 1) return 'Novato Termal';
    if (level <= 3) return 'Explorador';
    if (level <= 5) return 'Aventurero';
    if (level <= 8) return 'Experto Termal';
    return 'Termal Master';
  }

  int getPointsToNextLevel() {
    return (level * 300) - points;
  }

  double getLevelProgress() {
    int currentLevelPoints = (level - 1) * 300;
    int nextLevelPoints = level * 300;
    double progress = (points - currentLevelPoints) / (nextLevelPoints - currentLevelPoints);
    return progress.clamp(0.0, 1.0);
  }
}
