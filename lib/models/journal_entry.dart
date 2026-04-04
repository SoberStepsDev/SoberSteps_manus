class JournalEntry {
  final String id;
  final String userId;
  final int mood;
  final int cravingLevel;
  final List<String> triggers;
  final String? note;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.cravingLevel,
    this.triggers = const [],
    this.note,
    required this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        userId: json['user_id'],
        mood: json['mood'],
        cravingLevel: json['craving_level'],
        triggers: (json['triggers'] as List?)?.cast<String>() ?? [],
        note: json['note'],
        createdAt: DateTime.parse(json['created_at']),
      );

  JournalEntry copyWith({String? id, String? userId, int? mood, int? cravingLevel, List<String>? triggers, String? note, DateTime? createdAt}) => JournalEntry(
        id: id ?? this.id, userId: userId ?? this.userId, mood: mood ?? this.mood,
        cravingLevel: cravingLevel ?? this.cravingLevel, triggers: triggers ?? this.triggers,
        note: note ?? this.note, createdAt: createdAt ?? this.createdAt);

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'mood': mood,
        'craving_level': cravingLevel,
        'triggers': triggers,
        'note': note,
      };
}
