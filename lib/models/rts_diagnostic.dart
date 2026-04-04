class RtsDiagnosticQuestion {
  const RtsDiagnosticQuestion({required this.prompt, required this.options});
  final String prompt;
  final List<String> options;
}

enum RtsDiagnosticProfile {
  returningToYourself,
  innerCritic,
  invisibleWound,
  survivalMode,
}

class RtsDiagnostic {
  RtsDiagnostic._();

  static const questions = <RtsDiagnosticQuestion>[
    RtsDiagnosticQuestion(
      prompt: 'When I look in the mirror, I usually…',
      options: [
        'See someone worthy of love',
        'Focus on what\'s wrong with me',
        'Feel neutral',
        'Avoid looking too long',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'When I make a mistake, I usually…',
      options: [
        'Learn from it and move on',
        'Replay it in my head for days',
        'Apologize excessively',
        'Pretend it didn\'t happen',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'When someone compliments me, I…',
      options: [
        'Accept it and feel good',
        'Dismiss it',
        'Feel uncomfortable',
        'Wonder what they want from me',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'My inner voice is mostly…',
      options: [
        'Supportive and kind',
        'Critical and harsh',
        'Quiet — I don\'t notice it much',
        'Loud and impossible to silence',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'When I compare myself to others, I feel…',
      options: [
        'Inspired',
        'Like I\'m never enough',
        'Indifferent',
        'Angry at myself for falling behind',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'I believe I deserve good things in life…',
      options: [
        'Always',
        'Only when I\'ve earned it',
        'Rarely',
        'Never — others deserve it more',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'When I set a boundary, I feel…',
      options: [
        'Confident and clear',
        'Guilty and selfish',
        'Anxious about their reaction',
        'I don\'t set boundaries',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'Rest and relaxation feel…',
      options: [
        'Necessary and restorative',
        'Like I need to earn them first',
        'Uncomfortable',
        'Like wasted time',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'When I fail at something, I think…',
      options: [
        '"I\'ll do better next time"',
        '"I should have tried harder"',
        '"I\'m just not good enough"',
        '"Why do I even bother"',
      ],
    ),
    RtsDiagnosticQuestion(
      prompt: 'At the end of the day, I treat myself…',
      options: [
        'With the same kindness I\'d give a friend',
        'Fairly, but with high standards',
        'Much harsher than anyone else',
        'I don\'t think about it at all',
      ],
    ),
  ];

  static int scoreAnswers(List<int> optionIndices) {
    var s = 0;
    for (final i in optionIndices) {
      if (i >= 0 && i <= 3) s += i;
    }
    return s;
  }

  static RtsDiagnosticProfile profileForScore(int score) {
    if (score <= 7) return RtsDiagnosticProfile.returningToYourself;
    if (score <= 14) return RtsDiagnosticProfile.innerCritic;
    if (score <= 21) return RtsDiagnosticProfile.invisibleWound;
    return RtsDiagnosticProfile.survivalMode;
  }

  static String profileTitle(RtsDiagnosticProfile p) {
    return switch (p) {
      RtsDiagnosticProfile.returningToYourself => 'Returning to Yourself',
      RtsDiagnosticProfile.innerCritic => 'The Inner Critic',
      RtsDiagnosticProfile.invisibleWound => 'The Invisible Wound',
      RtsDiagnosticProfile.survivalMode => 'Survival Mode',
    };
  }

  static String profileBody(RtsDiagnosticProfile p) {
    return switch (p) {
      RtsDiagnosticProfile.returningToYourself =>
        'The foundation is already there — the path deepens it. Pace: normal; tone: exploratory.',
      RtsDiagnosticProfile.innerCritic =>
        'Worth has been tied to performance. Pace: challenging; tone: confrontational with care.',
      RtsDiagnosticProfile.invisibleWound =>
        'Harshness toward yourself is so internalized it feels like truth. Pace: slow; tone: gentle.',
      RtsDiagnosticProfile.survivalMode =>
        'A long war with yourself. Pace: very slow; no demands; maximum safety.',
    };
  }

  static String profileKey(RtsDiagnosticProfile p) {
    return switch (p) {
      RtsDiagnosticProfile.returningToYourself => 'returning',
      RtsDiagnosticProfile.innerCritic => 'inner_critic',
      RtsDiagnosticProfile.invisibleWound => 'invisible_wound',
      RtsDiagnosticProfile.survivalMode => 'survival',
    };
  }

  static RtsDiagnosticProfile? profileFromStorageKey(String? key) {
    if (key == null || key.isEmpty) return null;
    return switch (key) {
      'returning' => RtsDiagnosticProfile.returningToYourself,
      'inner_critic' => RtsDiagnosticProfile.innerCritic,
      'invisible_wound' => RtsDiagnosticProfile.invisibleWound,
      'survival' => RtsDiagnosticProfile.survivalMode,
      _ => null,
    };
  }
}

/// Sync with `profiles.rts_diagnostic_score` / `rts_diagnostic_profile` (Supabase).
class RtsDiagnosticResult {
  const RtsDiagnosticResult({required this.score, required this.profile});
  final int score;
  final RtsDiagnosticProfile profile;

  Map<String, dynamic> toJson() => {
        'score': score,
        'profile': RtsDiagnostic.profileKey(profile),
      };

  factory RtsDiagnosticResult.fromJson(Map<String, dynamic> json) {
    final s = json['score'];
    final p = json['profile'];
    final score = s is int ? s : int.tryParse('$s') ?? 0;
    final profile = RtsDiagnostic.profileFromStorageKey(p?.toString()) ??
        RtsDiagnostic.profileForScore(score);
    return RtsDiagnosticResult(score: score, profile: profile);
  }
}
