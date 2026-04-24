// Response shape for `GET /progress/trophies/{user_id}/pending-celebrations`.
// Hand-rolled (no codegen) — surface is small and stable.

class PendingCelebration {
  final String trophyId;
  final String name;
  final String description;
  final String icon;   // emoji OR Material icon key (server picks)
  final String tier;   // 'bronze' | 'silver' | 'gold' | 'platinum'
  final int? level;    // Tier-level for the badge; null for one-shots
  final int xpReward;
  final DateTime earnedAt;

  const PendingCelebration({
    required this.trophyId,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.level,
    required this.xpReward,
    required this.earnedAt,
  });

  factory PendingCelebration.fromJson(Map<String, dynamic> json) {
    return PendingCelebration(
      trophyId: json['trophy_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Trophy earned',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🏆',
      tier: json['tier']?.toString() ?? 'bronze',
      level: (json['level'] as num?)?.toInt(),
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      earnedAt: DateTime.tryParse(json['earned_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
