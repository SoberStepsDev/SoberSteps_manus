/// PhilosophyCore — the heart of SoberSteps
/// Every UI string, notification, error, and animation passes through this.
/// Uśmiech ↔ Perspektywa ↔ Droga
enum PhilosophyCore {
  smile,
  perspective,
  path;

  /// Uśmiech: replace imperatives with curiosity-driven invitations
  static String applySmile(String raw) {
    final replacements = <RegExp, String>{
      RegExp(r'[Mm]usisz'): 'Możesz spróbować',
      RegExp(r'[Pp]owinieneś'): 'Może warto',
      RegExp(r'[Nn]ie poddawaj się'): 'Ciekawe, co się stanie, jeśli zostaniesz chwilę dłużej…',
      RegExp(r'[Zz]rób'): 'Może spróbujesz',
      RegExp(r'[Ww]alcz'): 'Poobserwuj z ciekawością',
      RegExp(r'[Oo]siągnij'): 'Sprawdź co się wydarzy',
      RegExp(r'You must'): 'You might try',
      RegExp("Don't give up"): 'Curious what happens if you stay a moment longer...',
      RegExp(r'You have to'): 'You could try',
    };
    var result = raw;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Perspektywa: no finish line, no goal — just "interesting what could be"
  static String applyPerspective(String raw) {
    final replacements = <RegExp, String>{
      RegExp(r'[Cc]el osiągnięty'): 'Ciekawe, co będzie dalej',
      RegExp(r'[Gg]ratulacje!'): 'Patrz, jak daleko już jesteś –',
      RegExp(r'[Bb]rawo!'): 'Jesteś tu –',
      RegExp(r'Goal reached'): 'Interesting what comes next',
      RegExp(r'Congratulations!'): "Look how far you've come \u2013",
      RegExp(r'Great job!'): "You're here \u2013",
    };
    var result = raw;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Droga: the infinite map that creates itself — 80% is enough
  static String applyPath(String raw) {
    final replacements = <RegExp, String>{
      RegExp(r'100%'): '80% wystarczy',
      RegExp(r'[Pp]erfekcyjnie'): '80% wystarczy',
      RegExp(r'[Ff]ailure'): 'a step on the path',
      RegExp(r'[Pp]orażka'): 'kolejny krok na drodze',
      RegExp(r'streak lost'): 'the path continues',
      RegExp(r'streak przerwany'): 'droga trwa dalej',
    };
    var result = raw;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Full pipeline: Smile → Perspective → Path
  static String apply(String raw) {
    return applyPath(applyPerspective(applySmile(raw)));
  }

  /// Philosophy-aligned loading messages
  static const List<String> loadingMessages = [
    '80% wystarczy…',
    'Ciekawe, co przyniesie ten moment…',
    'Droga sama się tworzy…',
    'Jesteś już tutaj – to wystarczy.',
    'Uśmiech wobec nieznanego…',
  ];

  /// Philosophy-aligned error messages
  static String errorMessage(String technical) {
    return 'Coś poszło inaczej niż planowaliśmy – '
        'ale 80% wystarczy. Spróbuj za chwilę.';
  }

  /// Philosophy-aligned empty state
  static const String emptyState =
      'Tu jeszcze nic nie ma – ciekawe, co tu wkrótce się pojawi…';

  /// Philosophy-aligned streak message
  static String streakMessage(int days) {
    if (days == 0) return 'Dzisiaj znów jesteś tutaj – ciekawe, co przyniesie ten dzień';
    if (days < 7) return 'Wróciłeś do siebie przez $days dni – droga się tworzy';
    if (days < 30) return '$days dni – patrz, jak daleko już jesteś';
    return 'Wróciłeś do siebie przez $days dni – 80% wystarczy, a Ty już tu jesteś';
  }

  /// Philosophy-aligned notification messages
  static const Map<String, String> notifications = {
    'daily_checkin': 'Dziś wystarczy 80% – może warto zapisać kilka słów?',
    'milestone': 'Ciekawe, co przyniesie ten dzień na Twojej drodze…',
    'streak': 'Patrz, jak długo już tu jesteś – ciekawe, co będzie dalej',
    'craving': 'Jeśli przyjdzie ochota – możesz poobserwować ją z ciekawością',
    'letter': 'Masz wiadomość od siebie z przeszłości…',
  };
}
