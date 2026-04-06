class MilestoneAchieved {
  final String id;
  final String userId;
  final int days;
  final DateTime achievedAt;
  final bool shared;

  MilestoneAchieved({
    required this.id,
    required this.userId,
    required this.days,
    required this.achievedAt,
    this.shared = false,
  });

  factory MilestoneAchieved.fromJson(Map<String, dynamic> json) => MilestoneAchieved(
        id: json['id'],
        userId: json['user_id'],
        days: json['days'],
        achievedAt: DateTime.parse(json['achieved_at']),
        shared: json['shared'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'days': days,
        'shared': shared,
      };
}

/// Milestone definitions — copy lives in lib/l10n/strings.dart (`milestoneVista_*` keys).
class MilestoneData {
  final int days;
  final String emoji;
  final bool hasShare;

  const MilestoneData({
    required this.days,
    required this.emoji,
    this.hasShare = false,
  });

  String get titleKey => 'milestoneVista_${days}_title';
  String get messageKey => 'milestoneVista_${days}_message';
  String get subKey => 'milestoneVista_${days}_sub';
  String? get shareKey => hasShare ? 'milestoneVista_${days}_share' : null;

  static const List<MilestoneData> all = [
    MilestoneData(days: 1, emoji: '🌱'),
    MilestoneData(days: 3, emoji: '🔥'),
    MilestoneData(days: 7, emoji: '⭐', hasShare: true),
    MilestoneData(days: 14, emoji: '💪'),
    MilestoneData(days: 30, emoji: '🏆', hasShare: true),
    MilestoneData(days: 60, emoji: '🛡️'),
    MilestoneData(days: 90, emoji: '🧠', hasShare: true),
    MilestoneData(days: 180, emoji: '🌟'),
    MilestoneData(days: 365, emoji: '👑', hasShare: true),
    MilestoneData(days: 730, emoji: '🎯'),
    MilestoneData(days: 1825, emoji: '🏗️', hasShare: true),
  ];

  static MilestoneData? forDays(int d) {
    try {
      return all.firstWhere((m) => m.days == d);
    } catch (_) {
      return null;
    }
  }
}
