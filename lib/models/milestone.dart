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

class MilestoneData {
  final int days;
  final String title;
  final String message;
  final String subMessage;
  final String shareText;
  final String emoji;

  const MilestoneData({
    required this.days,
    required this.title,
    required this.message,
    required this.subMessage,
    this.shareText = '',
    required this.emoji,
  });

  static const List<MilestoneData> all = [
    MilestoneData(days: 1, title: 'Day 1', message: 'The hardest step is the first one.', subMessage: 'You took it.', emoji: '🌱'),
    MilestoneData(days: 3, title: '3 Days', message: 'Something real is beginning.', subMessage: 'Protect it.', emoji: '🔥'),
    MilestoneData(days: 7, title: '1 Week', message: 'A full week of choosing yourself.', subMessage: 'This is strength.', emoji: '⭐', shareText: 'I just hit 7 days sober with SoberSteps! One week of choosing myself.'),
    MilestoneData(days: 14, title: '2 Weeks', message: 'Two weeks. Your body is healing.', subMessage: 'Keep going.', emoji: '💪'),
    MilestoneData(days: 30, title: '30 Days', message: 'A full month.', subMessage: 'You did it.', emoji: '🏆', shareText: '30 days. A full month. I did it. #30DaysSober #SoberSteps'),
    MilestoneData(days: 60, title: '60 Days', message: 'Two months of freedom.', subMessage: 'Habits are forming.', emoji: '🛡️'),
    MilestoneData(days: 90, title: '90 Days', message: '90 days changes your brain.', subMessage: 'Science confirms it.', emoji: '🧠', shareText: '90 days changes your brain. I did it. #90DaysSober #SoberSteps'),
    MilestoneData(days: 180, title: '6 Months', message: 'Half a year of strength.', subMessage: 'You are unstoppable.', emoji: '🌟'),
    MilestoneData(days: 365, title: '1 Year', message: '365 choices. All yours.', subMessage: 'One year.', emoji: '👑', shareText: 'One year. 365 choices. All mine. #OneYearSober #SoberSteps'),
    MilestoneData(days: 730, title: '2 Years', message: 'Two years of living free.', subMessage: 'Incredible.', emoji: '🎯'),
    MilestoneData(days: 1825, title: '5 Years', message: 'Five years. A lifetime rebuilt.', subMessage: 'You are the proof.', emoji: '🏛️'),
  ];

  static MilestoneData? forDays(int d) {
    try {
      return all.firstWhere((m) => m.days == d);
    } catch (_) {
      return null;
    }
  }
}
