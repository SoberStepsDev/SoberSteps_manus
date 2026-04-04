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
    MilestoneData(
      days: 1,
      title: 'Punkt widokowy: Dzień 1',
      message: 'Droga sama się tworzy pod Twoimi stopami.',
      subMessage: 'Pierwszy krok jest całym krokiem.',
      emoji: '🌱',
    ),
    MilestoneData(
      days: 3,
      title: 'Punkt widokowy: 3 dni',
      message: 'Ciekawe, co się wydarzy, jeśli zostaniesz tu jeszcze jeden dzień…',
      subMessage: 'Coś prawdziwego zaczyna się tworzyć.',
      emoji: '🔥',
    ),
    MilestoneData(
      days: 7,
      title: 'Punkt widokowy: 7 dni',
      message: 'Tydzień. Patrz, jak daleko już jesteś.',
      subMessage: 'Nie ma mety — jest tylko droga.',
      emoji: '⭐',
      shareText: '7 dni trzeźwości. Punkt widokowy na drodze powrotu do siebie. 🌱 #SoberSteps',
    ),
    MilestoneData(
      days: 14,
      title: 'Punkt widokowy: 2 tygodnie',
      message: 'Można poobserwować tę drogę z ciekawością.',
      subMessage: 'Dwa tygodnie. Twoje ciało pamięta.',
      emoji: '💪',
    ),
    MilestoneData(
      days: 30,
      title: 'Punkt widokowy: 30 dni',
      message: 'Wróciłeś do siebie. To wystarczy.',
      subMessage: 'Cały miesiąc. Twoja droga.',
      emoji: '🏆',
      shareText: '30 dni trzeźwości. Wróciłem do siebie. 🏆 #SoberSteps #30Dni',
    ),
    MilestoneData(
      days: 60,
      title: 'Punkt widokowy: 60 dni',
      message: 'Każdy krok, który robisz, jest już całym krokiem.',
      subMessage: 'Dwa miesiące wolności.',
      emoji: '🛡️',
    ),
    MilestoneData(
      days: 90,
      title: 'Punkt widokowy: 90 dni',
      message: 'Może warto sprawdzić, co się stanie, jeśli pozwolisz sobie na więcej?',
      subMessage: '90 dni zmienia mózg. Nauka to potwierdza.',
      emoji: '🧠',
      shareText: '90 dni trzeźwości. Droga zmienia mózg — i zmienia ciebie. 🧠 #SoberSteps #90Dni',
    ),
    MilestoneData(
      days: 180,
      title: 'Punkt widokowy: 6 miesięcy',
      message: 'Pół roku drogi. Nie ma linii końcowej.',
      subMessage: 'Jest tylko następny zakręt.',
      emoji: '🌟',
    ),
    MilestoneData(
      days: 365,
      title: 'Punkt widokowy: 1 rok',
      message: '365 kroków. Wszystkie Twoje.',
      subMessage: 'Jutro też będzie droga. Dziś wystarczy być tu.',
      emoji: '👑',
      shareText: 'Rok trzeźwości. 365 kroków. Wszystkie moje. 👑 #SoberSteps #RokTrzeźwości',
    ),
    MilestoneData(
      days: 730,
      title: 'Punkt widokowy: 2 lata',
      message: 'Dwa lata wolności. Ciekawe, co jeszcze się wydarzy…',
      subMessage: 'Droga się rozszerza.',
      emoji: '🎯',
    ),
    MilestoneData(
      days: 1825,
      title: 'Punkt widokowy: 5 lat',
      message: 'Pięć lat. Życie odbudowane. Jesteś dowodem.',
      subMessage: 'Nie ma mety. Jest tylko horyzont.',
      emoji: '🏗️',
      shareText: 'Pięć lat trzeźwości. Życie odbudowane. Jestem dowodem. 🏗️ #SoberSteps #5Lat',
    ),
  ];

  static MilestoneData? forDays(int d) {
    try {
      return all.firstWhere((m) => m.days == d);
    } catch (_) {
      return null;
    }
  }
}
