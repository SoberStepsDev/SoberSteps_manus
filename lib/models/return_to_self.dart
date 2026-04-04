/// Return to Self — 4 types + 30-day path
/// Awareness → Distance → Repair → Integration
enum ReturnToSelfType { awareness, distance, repair, integration }

class ReturnToSelfProgress {
  final String id;
  final String userId;
  final ReturnToSelfType type;
  final int day;
  final bool completed;

  ReturnToSelfProgress({
    required this.id,
    required this.userId,
    required this.type,
    required this.day,
    this.completed = false,
  });

  factory ReturnToSelfProgress.fromJson(Map<String, dynamic> j) =>
      ReturnToSelfProgress(
        id: j['id'],
        userId: j['user_id'],
        type: ReturnToSelfType.values.byName(j['type']),
        day: j['day'],
        completed: j['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'day': day,
        'completed': completed,
      };
}

class ReturnToSelfPathEntry {
  final String id;
  final String progressId;
  final String practiceType;
  final String? reflectionEncrypted;

  ReturnToSelfPathEntry({
    required this.id,
    required this.progressId,
    required this.practiceType,
    this.reflectionEncrypted,
  });

  factory ReturnToSelfPathEntry.fromJson(Map<String, dynamic> j) =>
      ReturnToSelfPathEntry(
        id: j['id'],
        progressId: j['progress_id'],
        practiceType: j['practice_type'],
        reflectionEncrypted: j['reflection_encrypted'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress_id': progressId,
        'practice_type': practiceType,
        'reflection_encrypted': reflectionEncrypted,
      };
}

class ReturnToSelfStreak {
  final String id;
  final String userId;
  final int streakDays;
  final DateTime lastCheck;

  ReturnToSelfStreak({
    required this.id,
    required this.userId,
    required this.streakDays,
    required this.lastCheck,
  });

  factory ReturnToSelfStreak.fromJson(Map<String, dynamic> j) =>
      ReturnToSelfStreak(
        id: j['id'],
        userId: j['user_id'],
        streakDays: j['streak_days'] ?? 0,
        lastCheck: DateTime.parse(j['last_check']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'streak_days': streakDays,
        'last_check': lastCheck.toIso8601String(),
      };
}

class MirrorSession {
  final String id;
  final String userId;
  final int durationSec;
  final DateTime timestamp;

  MirrorSession({
    required this.id,
    required this.userId,
    required this.durationSec,
    required this.timestamp,
  });

  factory MirrorSession.fromJson(Map<String, dynamic> j) => MirrorSession(
        id: j['id'],
        userId: j['user_id'],
        durationSec: j['duration_sec'] ?? 0,
        timestamp: DateTime.parse(j['timestamp']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'duration_sec': durationSec,
        'timestamp': timestamp.toIso8601String(),
      };
}

class KarmaEntry {
  final String id;
  final String userId;
  final String? answerEncrypted;
  final DateTime timestamp;

  KarmaEntry({
    required this.id,
    required this.userId,
    this.answerEncrypted,
    required this.timestamp,
  });

  factory KarmaEntry.fromJson(Map<String, dynamic> j) => KarmaEntry(
        id: j['id'],
        userId: j['user_id'],
        answerEncrypted: j['response'],
        timestamp: DateTime.tryParse(j['response_date'] ?? '') ?? DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'answer_encrypted': answerEncrypted,
        'timestamp': timestamp.toIso8601String(),
      };
}

class NaomiEntry {
  final String id;
  final String userId;
  final String questionType;
  final String? answerEncrypted;
  final String? feedback;

  NaomiEntry({
    required this.id,
    required this.userId,
    required this.questionType,
    this.answerEncrypted,
    this.feedback,
  });

  factory NaomiEntry.fromJson(Map<String, dynamic> j) => NaomiEntry(
        id: j['id'],
        userId: j['user_id'],
        questionType: j['subcategory'] ?? j['question_type'] ?? '',
        answerEncrypted: j['response'] ?? j['answer_encrypted'],
        feedback: j['feedback'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'question_type': questionType,
        'answer_encrypted': answerEncrypted,
        'feedback': feedback,
      };
}

class WallOfStrengthPost {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final bool anonymous;

  WallOfStrengthPost({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.anonymous = true,
  });

  factory WallOfStrengthPost.fromJson(Map<String, dynamic> j) =>
      WallOfStrengthPost(
        id: j['id'],
        userId: j['user_id'],
        content: j['content'],
        timestamp: DateTime.parse(j['timestamp']),
        anonymous: j['anonymous'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'anonymous': anonymous,
      };
}
