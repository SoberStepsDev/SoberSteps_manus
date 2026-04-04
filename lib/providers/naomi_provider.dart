// ignore_for_file: curly_braces_in_flow_control_structures — cluster detector uses dense single-line if filters
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/return_to_self.dart';
import '../services/encryption_service.dart';

class NaomiFeedbackRateLimitException implements Exception {}

/// Naomi Mode — 4 rotating questions + Claude (Anthropic) feedback (fallback local)
class NaomiProvider extends ChangeNotifier {
  List<NaomiEntry> _entries = [];
  List<NaomiEntry> get entries => _entries;
  bool _loading = false;
  bool get loading => _loading;

  String? _lastCluster;

  final _enc = EncryptionService();
  final _supabase = Supabase.instance.client;

  static const List<Map<String, String>> rotatingQuestions = [
    {
      'type': 'self_compassion',
      'question': 'Co byś powiedział przyjacielowi, który czuje to samo co Ty teraz?',
    },
    {
      'type': 'curiosity',
      'question': 'Co ciekawego zauważyłeś dzisiaj w swoich myślach?',
    },
    {
      'type': 'body_scan',
      'question': 'Gdzie w ciele czujesz to, co teraz przeżywasz?',
    },
    {
      'type': 'future_self',
      'question': 'Ciekawe, co Twoje przyszłe „ja" pomyślałoby o tym momencie…',
    },
  ];

  /// Cluster-specific follow-up questions shown after a response is detected.
  static const Map<String, Map<String, String>> _clusterQuestions = {
    'samoocena': {
      'type': 'self_compassion',
      'question': 'Co byś powiedział komuś bliziemu, gdyby oceniał się tak surowo jak Ty siebie teraz?',
    },
    'wstyd': {
      'type': 'self_compassion',
      'question': 'Kto lub co nauczyło Cię tego wstydu? Czy to naprawdę Twój głos?',
    },
    'beznadziejnosc': {
      'type': 'body_scan',
      'question': 'Kiedy mówisz "bez sensu" – gdzie to siedzi w Twoim ciele? Klatka, brzuch, gardło?',
    },
    'zagubienie': {
      'type': 'curiosity',
      'question': 'Zagubienie bywa początkiem czegoś nowego. Co się zmienia w Twoim życiu ostatnio?',
    },
    'bol': {
      'type': 'body_scan',
      'question': 'Ból jest tu, z Tobą. Gdybyś mógł mu zadać jedno pytanie – co byś zapytał?',
    },
    'zlosc': {
      'type': 'curiosity',
      'question': 'Pod każdą złością jest coś ważnego. Co tak naprawdę jest naruszone?',
    },
    'strach': {
      'type': 'future_self',
      'question': 'Twoje przyszłe „ja" przeszło przez ten strach. Co mu pomogło?',
    },
    'samotnosc': {
      'type': 'self_compassion',
      'question': 'Jesteś tu i piszesz – to też forma bycia z sobą. Czego teraz najbardziej Ci brakuje od innych?',
    },
    'pokusa': {
      'type': 'body_scan',
      'question': 'Pokusa ma swoje miejsce w ciele. Gdzie ją czujesz? Zostań z tym, zanim odpiszesz.',
    },
    'sukces': {
      'type': 'curiosity',
      'question': 'Co konkretnie sprawiło, że dzisiaj Ci się udało? Co możesz z tego zapamiętać?',
    },
    'zalowanie': {
      'type': 'future_self',
      'question': 'Twoje przyszłe „ja" patrzy na ten żal z dystansu. Co widzi, czego Ty jeszcze nie widzisz?',
    },
    'zmeczenie': {
      'type': 'body_scan',
      'question': 'Zmęczenie mówi "stop". Czego konkretnie już za dużo – i co możesz dziś odpuścić?',
    },
    'rodzina': {
      'type': 'self_compassion',
      'question': 'Gdyby ta osoba z rodziny wiedziała, co czujesz – co chciałbyś, żeby zrozumiała?',
    },
    'sens': {
      'type': 'future_self',
      'question': 'Kiedy ostatnio coś miało dla Ciebie wyraźny sens? Co to było i co wtedy robiłeś?',
    },
    'poprawa': {
      'type': 'curiosity',
      'question': 'Co stworzyło ten spokój? Chcę wiedzieć – co konkretnie zrobiłeś lub odpuściłeś?',
    },
    'nadzieja': {
      'type': 'future_self',
      'question': 'Ta nadzieja już w Tobie jest. Na co konkretnie czekasz – i co możesz zrobić dziś?',
    },
    'tozsamosc': {
      'type': 'curiosity',
      'question': 'Kim jesteś poza alkoholem, poza etykietkami? Co zostaje, gdy odejmiemy wszystko?',
    },
    'cialo': {
      'type': 'body_scan',
      'question': 'Twoje ciało daje sygnał. Czy słuchasz go z troską, czy z niecierpliwością?',
    },
    'praca': {
      'type': 'curiosity',
      'question': 'Stres związany z pracą czy pieniędzmi – co jest źródłem, a co objawem?',
    },
    'izolacja': {
      'type': 'self_compassion',
      'question': 'Zamknąłeś się. Co tak naprawdę chronisz, wycofując się od innych?',
    },
    'kontrola': {
      'type': 'body_scan',
      'question': 'Potrzeba kontroli często maskuje lęk. Czego tak naprawdę się boisz stracić?',
    },
    'perfekcjonizm': {
      'type': 'self_compassion',
      'question': 'Ile razy "wystarczająco dobrze" naprawdę Ci nie wystarczyło? Co musiałoby się wydarzyć, żeby to zmienić?',
    },
    'akceptacja': {
      'type': 'curiosity',
      'question': 'Akceptacja to nie rezygnacja. Co konkretnie decydujesz się przyjąć takim, jakie jest?',
    },
    'granice': {
      'type': 'future_self',
      'question': 'Powiedziałeś "nie" lub postawiłeś granicę. Jak to było? Co poczułeś po?',
    },
    'wdziecznosc': {
      'type': 'curiosity',
      'question': 'Wdzięczność to mięsień – im częściej ćwiczony, tym silniejszy. Co jeszcze, z czego nie zdajesz sobie sprawy, możesz docenić?',
    },
    'terazniejszosc': {
      'type': 'body_scan',
      'question': 'Jesteś tu, teraz. Oddech. Co widzisz, słyszysz, czujesz dokładnie w tej chwili?',
    },
    'zaufanie': {
      'type': 'self_compassion',
      'question': 'Zaufanie się buduje powoli. Czy ufasz choć trochę sobie – że dasz radę?',
    },
    'zmiana': {
      'type': 'future_self',
      'question': 'Zmieniasz się. To bywa dezorientujące. Co z nowej wersji siebie najbardziej Cię zaskakuje?',
    },
    'kryzys_nocny': {
      'type': 'body_scan',
      'question': 'Noc potrafi być ciężka. Gdzie to czujesz w ciele teraz – i co przyniosłoby ulgę, choćby małą?',
    },
    'inne_uzaleznienie': {
      'type': 'curiosity',
      'question': 'Każde uzależnienie wypełnia coś. Co próbuje wypełnić to, z czym teraz walczysz?',
    },
  };

  Map<String, String> get todayQuestion {
    if (_lastCluster != null) {
      final clusterQ = _clusterQuestions[_lastCluster!];
      if (clusterQ != null) return clusterQ;
    }
    final index = DateTime.now().day % rotatingQuestions.length;
    return rotatingQuestions[index];
  }

  Future<void> loadEntries() async {
    _loading = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('return_to_self_naomi')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      _entries = (res as List).map((e) => NaomiEntry.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> saveAnswer(String questionType, String answer) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final encrypted = await _enc.encrypt(answer);

    final cluster = _detectCluster(answer);
    _lastCluster = cluster == 'neutral' ? null : cluster;

    // Call Claude via Edge Function, fallback to local if unavailable
    final feedback = await _fetchAiFeedback(questionType, answer)
        ?? _generateLocalFeedback(cluster, questionType, answer);

    await _supabase.from('return_to_self_naomi').insert({
      'id': const Uuid().v4(),
      'user_id': uid,
      'subcategory': questionType,
      'response': encrypted,
      'feedback': feedback,
      'response_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    await loadEntries();
    notifyListeners();
  }

  /// Calls Supabase Edge Function → Claude (Anthropic). Returns null on any failure.
  Future<String?> _fetchAiFeedback(String questionType, String answer) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final res = await _supabase.functions.invoke(
        'naomi-feedback',
        body: {'question_type': questionType, 'answer': answer},
      );

      if (res.status == 429) throw NaomiFeedbackRateLimitException();
      if (res.status != 200) return null;
      final data = res.data as Map<String, dynamic>?;
      final feedback = data?['feedback'] as String?;
      return (feedback != null && feedback.isNotEmpty) ? feedback : null;
    } catch (_) {
      return null;
    }
  }

  /// Detects the dominant emotional cluster from the answer text.
  String _detectCluster(String answer) {
    final lower = answer.toLowerCase();

    // SAMOOCENA
    if (lower.contains('beznadziejn') || lower.contains('bezwartościow') ||
        lower.contains('do niczego') || lower.contains('nieudacznik') ||
        lower.contains('nie nadaję się') || lower.contains('nie jestem wystarczając') ||
        lower.contains('słaby jestem') || lower.contains('słaba jestem') ||
        lower.contains('przegrany') || lower.contains('przegrana') ||
        lower.contains('nie zasługuję') || lower.contains('jestem zerem') ||
        lower.contains('nic ze mnie') || lower.contains('gorszy') ||
        lower.contains('gorsza') || lower.contains('nikomu niepotrzebny')) return 'samoocena';

    // WSTYD
    if (lower.contains('wstyd') || lower.contains('wstydzę') || lower.contains('wstydzić') ||
        lower.contains('hańba') || lower.contains('żenujące') || lower.contains('żenada') ||
        lower.contains('jak mogłem') || lower.contains('jak mogłam') ||
        lower.contains('kompromitacja') || lower.contains('wstydliwy') ||
        lower.contains('nie chcę, żeby wiedzieli') || lower.contains('ukrywam')) return 'wstyd';

    // BEZNADZIEJNOŚĆ
    if (lower.contains('nie mam siły') || lower.contains('brak siły') ||
        lower.contains('nie dam rady') || lower.contains('nie mogę tak dalej') ||
        lower.contains('wszystko bez sensu') || lower.contains('nie ma sensu') ||
        lower.contains('ciemność') || lower.contains('pustka') ||
        lower.contains('nie warto') || lower.contains('rezygnuję') ||
        lower.contains('poddaję się') || lower.contains('nie widzę wyjścia') ||
        lower.contains('nie ma dla mnie nadziei') || lower.contains('koniec')) return 'beznadziejnosc';

    // ZAGUBIENIE
    if (lower.contains('nie wiem') || lower.contains('nie rozumiem') ||
        lower.contains('nie mam pojęcia') || lower.contains('zagubion') ||
        lower.contains('zagubiłem') || lower.contains('zagubiłam') ||
        lower.contains('chaos') || lower.contains('wszystko się miesza') ||
        lower.contains('nie ogarniam') || lower.contains('się pogubiłem') ||
        lower.contains('się pogubiłam') || lower.contains('nie wiem czego chcę') ||
        lower.contains('bez kierunku') || lower.contains('nie wiem co robię')) return 'zagubienie';

    // BÓL
    if (lower.contains('boli') || lower.contains('ból') || lower.contains('cierpię') ||
        lower.contains('cierpienie') || lower.contains('trudno mi') || lower.contains('jest mi trudno') ||
        lower.contains('ciężko mi') || lower.contains('jest ciężko') ||
        lower.contains('boli mnie') || lower.contains('nie znoszę') ||
        lower.contains('rani mnie') || lower.contains('zranion') ||
        lower.contains('głęboko boli') || lower.contains('serce boli')) return 'bol';

    // ZŁOŚĆ
    if (lower.contains('wkurwion') || lower.contains('wkurzon') || lower.contains('wściekł') ||
        lower.contains('jestem zły') || lower.contains('jestem zła') ||
        lower.contains('mam dość') || lower.contains('nie mogę znieść') ||
        lower.contains('frustracja') || lower.contains('frustruje') ||
        lower.contains('denerwuje mnie') || lower.contains('irytuje') ||
        lower.contains('nienawidz') || lower.contains('kurwa') ||
        lower.contains('wnerwiają mnie') || lower.contains('pierdziel')) return 'zlosc';

    // STRACH
    if (lower.contains('boję się') || lower.contains('boje się') || lower.contains('strach') ||
        lower.contains('lęk') || lower.contains('niepokój') || lower.contains('niepokoję') ||
        lower.contains('nerwowy') || lower.contains('nerwowa') ||
        lower.contains('panika') || lower.contains('przerażon') ||
        lower.contains('obawiam się') || lower.contains('bać się') ||
        lower.contains('przeraża mnie') || lower.contains('drżę') ||
        lower.contains('serce mi wali') || lower.contains('napad paniki')) return 'strach';

    // SAMOTNOŚĆ
    if (lower.contains('samotny') || lower.contains('samotna') || lower.contains('samotność') ||
        lower.contains('nikt mnie') || lower.contains('nikogo') ||
        lower.contains('nie mam nikogo') || lower.contains('jestem sam') ||
        lower.contains('jestem sama') || lower.contains('nikt nie rozumie') ||
        lower.contains('czuję się odcięty') || lower.contains('czuję się odcięta') ||
        lower.contains('nikt nie pyta') || lower.contains('nikt nie dzwoni') ||
        lower.contains('bez przyjaciół') || lower.contains('wszyscy mnie opuścili')) return 'samotnosc';

    // POKUSA / NAWRÓT
    if (lower.contains('napić') || lower.contains('sięgnąć po') || lower.contains('pokusa') ||
        lower.contains('kusi mnie') || lower.contains('ciągnie mnie') ||
        lower.contains('nawrót') || lower.contains('znowu chcę') ||
        lower.contains('chciałem się') || lower.contains('chciałam się') ||
        lower.contains('myśl o alkoholu') || lower.contains('myśl o piciu') ||
        lower.contains('jeden drink') || lower.contains('tylko raz') ||
        lower.contains('kontrolowane picie') || lower.contains('może już mogę')) return 'pokusa';

    // SUKCES / DUMA
    if (lower.contains('jeden dzień') || lower.contains('jeden krok') ||
        lower.contains('dzisiaj nie piłem') || lower.contains('dzisiaj nie piłam') ||
        lower.contains('udało mi się') || lower.contains('udało się') ||
        lower.contains('jestem z siebie') || lower.contains('dumny') ||
        lower.contains('dumna') || lower.contains('zrobiłem to') ||
        lower.contains('zrobiłam to') || lower.contains('poradziłem') ||
        lower.contains('poradziłam') || lower.contains('wygrałem') ||
        lower.contains('wygrałam') || lower.contains('jestem z siebie dumny')) return 'sukces';

    // ŻAŁOWANIE
    if (lower.contains('żałuję') || lower.contains('żałuje') || lower.contains('żal mi') ||
        lower.contains('kiedyś byłem') || lower.contains('kiedyś byłam') ||
        lower.contains('dawniej') || lower.contains('zmarnował') ||
        lower.contains('zmarnowałem') || lower.contains('zmarnowałam') ||
        lower.contains('stracone lata') || lower.contains('straciłem') ||
        lower.contains('gdybym tylko') || lower.contains('gdybym wtedy') ||
        lower.contains('przepraszam samego siebie') || lower.contains('żałuję przeszłości')) return 'zalowanie';

    // ZMĘCZENIE
    if (lower.contains('zmęczony') || lower.contains('zmęczona') ||
        lower.contains('jestem zmęczon') || lower.contains('nie śpię') ||
        lower.contains('bezsenność') || lower.contains('bez energii') ||
        lower.contains('wyczerpan') || lower.contains('opadam z sił') ||
        lower.contains('nie mam już energii') || lower.contains('ledwo wstaję') ||
        lower.contains('ledwo funkcjonuję') || lower.contains('nie mogę wstać') ||
        lower.contains('wypalony') || lower.contains('wypalona')) return 'zmeczenie';

    // RODZINA / RELACJE
    if (lower.contains('rodzina') || lower.contains('dzieci') || lower.contains('żona') ||
        lower.contains('mąż') || lower.contains('partner') || lower.contains('partnerka') ||
        lower.contains('mama') || lower.contains('tata') || lower.contains('ojciec') ||
        lower.contains('matka') || lower.contains('brat') || lower.contains('siostra') ||
        lower.contains('blisc') || lower.contains('związek') || lower.contains('rozstanie') ||
        lower.contains('rozwód') || lower.contains('kłótnia z') || lower.contains('córka') ||
        lower.contains('syn') || lower.contains('wnuki')) return 'rodzina';

    // SENS / CEL
    if (lower.contains('po co żyję') || lower.contains('sens życia') ||
        lower.contains('nie wiem po co') || lower.contains('nie ma celu') ||
        lower.contains('nie mam celu') || lower.contains('brak celu') ||
        lower.contains('do czego zmierzam') || lower.contains('jaki sens') ||
        lower.contains('bez sensu to wszystko') || lower.contains('po co w ogóle')) return 'sens';

    // POPRAWA / SPOKÓJ
    if (lower.contains('lepiej') || lower.contains('poprawa') || lower.contains('coraz lepiej') ||
        lower.contains('spokojniej') || lower.contains('czuję spokój') ||
        lower.contains('jest dobrze') || lower.contains('idzie mi') ||
        lower.contains('czuję się dobrze') || lower.contains('dobry dzień') ||
        lower.contains('jestem spokojny') || lower.contains('jest spokojnie')) return 'poprawa';

    // NADZIEJA
    if (lower.contains('nadzieja') || lower.contains('mam nadzieję') ||
        lower.contains('może się uda') || lower.contains('wierzę') ||
        lower.contains('wierze że') || lower.contains('może być lepiej') ||
        lower.contains('jest szansa') || lower.contains('uda się') ||
        lower.contains('optymistyczn') || lower.contains('liczę na') ||
        lower.contains('wierzę w siebie')) return 'nadzieja';

    // TOŻSAMOŚĆ
    if (lower.contains('kim jestem') || lower.contains('nie wiem kim jestem') ||
        lower.contains('zgubiłem siebie') || lower.contains('zgubiłam siebie') ||
        lower.contains('trzeźwy to') || lower.contains('nowa wersja') ||
        lower.contains('nie poznaję siebie') || lower.contains('kto to jest') ||
        lower.contains('moja tożsamość') || lower.contains('bez alkoholu jestem') ||
        lower.contains('człowiek bez alkoholu') || lower.contains('nie wiem, jaki jestem')) return 'tozsamosc';

    // CIAŁO / ZDROWIE
    if (lower.contains('zdrowie') || lower.contains('zdrowy') || lower.contains('zdrowa') ||
        lower.contains('choroba') || lower.contains('choruję') ||
        lower.contains('ciało mi mówi') || lower.contains('fizycznie') ||
        lower.contains('lekarza') || lower.contains('diagnoza') ||
        lower.contains('wątroba') || lower.contains('badania') ||
        lower.contains('leczenie') || lower.contains('ból fizyczny')) return 'cialo';

    // PRACA / PIENIĄDZE
    if (lower.contains('praca') || lower.contains('pieniądze') || lower.contains('finanse') ||
        lower.contains('długi') || lower.contains('dług') ||
        lower.contains('straciłem pracę') || lower.contains('straciłam pracę') ||
        lower.contains('szef') || lower.contains('zwolnienie') ||
        lower.contains('nie starcza') || lower.contains('nie mam na') ||
        lower.contains('bezrobotny') || lower.contains('kasa się skończyła') ||
        lower.contains('kredyt') || lower.contains('zaległości')) return 'praca';

    // IZOLACJA / WYCOFANIE
    if (lower.contains('zamknąłem się') || lower.contains('zamknęłam się') ||
        lower.contains('nie wychodzę') || lower.contains('unikam') ||
        lower.contains('izoluję się') || lower.contains('nie odbieram') ||
        lower.contains('nie odpowiadam') || lower.contains('schowałem się') ||
        lower.contains('schowałam się') || lower.contains('nie chcę kontaktu') ||
        lower.contains('zostawcie mnie') || lower.contains('chcę być sam')) return 'izolacja';

    // KONTROLA
    if (lower.contains('muszę kontrolować') || lower.contains('potrzebę kontroli') ||
        lower.contains('wszystko musi być') || lower.contains('nie daję się') ||
        lower.contains('nie mogę odpuścić') || lower.contains('muszę mieć pewność') ||
        lower.contains('planuję wszystko') || lower.contains('nie toleruję błędów') ||
        lower.contains('muszę wiedzieć') || lower.contains('kontroluję') ||
        lower.contains('nie lubię niespodzianek') || lower.contains('muszę to ogarnąć')) return 'kontrola';

    // PERFEKCJONIZM
    if (lower.contains('nie było idealne') || lower.contains('nie dość dobry') ||
        lower.contains('nie dość dobra') || lower.contains('mogło być lepiej') ||
        lower.contains('za mało') || lower.contains('powinienem był') ||
        lower.contains('powinnam była') || lower.contains('mogłem lepiej') ||
        lower.contains('mogłam lepiej') || lower.contains('nie spełniłem') ||
        lower.contains('nie spełniłam') || lower.contains('wymagam od siebie') ||
        lower.contains('stawiłem poprzeczkę')) return 'perfekcjonizm';

    // AKCEPTACJA
    if (lower.contains('akceptuję') || lower.contains('przyjmuję') ||
        lower.contains('godzę się') || lower.contains('ok jest tak') ||
        lower.contains('nie walczę') || lower.contains('pozwalam sobie') ||
        lower.contains('odpuszczam') || lower.contains('zgadzam się z tym') ||
        lower.contains('przyjmuję to') || lower.contains('takie jest życie') ||
        lower.contains('to nie zależy ode mnie')) return 'akceptacja';

    // GRANICE
    if (lower.contains('powiedziałem nie') || lower.contains('powiedziałam nie') ||
        lower.contains('postawiłem granicę') || lower.contains('postawiłam granicę') ||
        lower.contains('nie chcę więcej') || lower.contains('dosyć tego') ||
        lower.contains('odmówiłem') || lower.contains('odmówiłam') ||
        lower.contains('moje granice') || lower.contains('szanuję się') ||
        lower.contains('nie dam się') || lower.contains('powiedziałem stop')) return 'granice';

    // WDZIĘCZNOŚĆ
    if (lower.contains('wdzięczny') || lower.contains('wdzięczna') ||
        lower.contains('dziękuję') || lower.contains('jestem wdzięczny') ||
        lower.contains('doceniam') || lower.contains('jestem wdzięczna') ||
        lower.contains('to było piękne') || lower.contains('cieszę się z') ||
        lower.contains('mam szczęście') || lower.contains('jestem szczęśliwy') ||
        lower.contains('jestem szczęśliwa') || lower.contains('to cud')) return 'wdziecznosc';

    // TERAŹNIEJSZOŚĆ / MINDFULNESS
    if (lower.contains('teraz') || lower.contains('ta chwila') ||
        lower.contains('byłem obecny') || lower.contains('byłam obecna') ||
        lower.contains('medytacja') || lower.contains('medytowałem') ||
        lower.contains('oddech') || lower.contains('skupiłem się') ||
        lower.contains('uważność') || lower.contains('tu i teraz') ||
        lower.contains('mindfull') || lower.contains('mindfulness') ||
        lower.contains('byłem tu') || lower.contains('wróciłem do siebie')) return 'terazniejszosc';

    // ZAUFANIE
    if (lower.contains('nie ufam') || lower.contains('zaufanie') ||
        lower.contains('zawiedli mnie') || lower.contains('trudno mi ufać') ||
        lower.contains('nie wierzę') || lower.contains('kłamał') ||
        lower.contains('kłamała') || lower.contains('zdradzili mnie') ||
        lower.contains('nie wiem, czy mogę') || lower.contains('straciłem zaufanie') ||
        lower.contains('straciłam zaufanie') || lower.contains('zaufać to ryzyko')) return 'zaufanie';

    // ZMIANA
    if (lower.contains('zmieniłem się') || lower.contains('zmieniłam się') ||
        lower.contains('jestem inny') || lower.contains('jestem inna') ||
        lower.contains('to nie ten sam') || lower.contains('staję się') ||
        lower.contains('zmiana') || lower.contains('nowy ja') ||
        lower.contains('nowa ja') || lower.contains('rosnę') ||
        lower.contains('rozwijam się') || lower.contains('już nie taki')) return 'zmiana';

    // KRYZYS NOCNY
    if (lower.contains('w nocy') || lower.contains('o 3') || lower.contains('3 rano') ||
        lower.contains('nie mogę spać') || lower.contains('noc') ||
        lower.contains('środek nocy') || lower.contains('nie śpię') ||
        lower.contains('budzę się') || lower.contains('koszmar') ||
        lower.contains('nocna myśl') || lower.contains('wieczorem') ||
        lower.contains('o północy')) return 'kryzys_nocny';

    // INNE UZALEŻNIENIE
    if (lower.contains('papierosy') || lower.contains('palę') ||
        lower.contains('cukier') || lower.contains('telefon') ||
        lower.contains('gry') || lower.contains('hazard') ||
        lower.contains('pornografia') || lower.contains('zakupy') ||
        lower.contains('jedzenie') || lower.contains('objadanie') ||
        lower.contains('inne uzależnienie') || lower.contains('też jestem uzależnion') ||
        lower.contains('substancje') || lower.contains('narkotyki')) return 'inne_uzaleznienie';

    return 'neutral';
  }

  /// Local fallback — uses detected cluster first, then question type.
  String _generateLocalFeedback(String cluster, String questionType, String answer) {
    String pick(List<String> opts) => opts[answer.length % opts.length];

    switch (cluster) {
      case 'samoocena':
        return pick([
          'Ciekawe – mówisz to o sobie, a jednocześnie zadajesz sobie to pytanie. Coś w Tobie wciąż szuka.',
          'Kto Cię nauczył tego słowa o sobie? Bo ono nie brzmi jak Twój własny głos.',
          'Zostań chwilę z tą oceną. Czy to naprawdę Twoja – czy echo czegoś starszego?',
          'Beznadziejny? Naprawdę? A kto tu jest i pisze zamiast uciekać?',
        ]);
      case 'wstyd':
        return pick([
          'Wstyd jest jednym z najtrudniejszych uczuć. Co by się stało, gdybyś potraktował je jak gościa – a nie wroga?',
          'Czujesz wstyd. To znaczy, że coś dla Ciebie ważne. Nie musisz go teraz naprawiać.',
          'Wstyd często mówi: "zależy mi". Ciekawe, na czym Ci zależy w tej sytuacji?',
          'Nie musisz ukrywać tego przede mną. Tu nie ma ocen.',
        ]);
      case 'beznadziejnosc':
        return pick([
          'Kiedy mówisz "nie mam siły" – to już jest siła. Żeby to napisać, trzeba być obecnym.',
          'Pustka ma swój kształt. Ciekawe, czy wiesz, kiedy ostatnio wyglądała inaczej?',
          '"Bez sensu" to uczciwe miejsce. Nie musisz teraz znajdować sensu. Wystarczy być tu.',
          'To, co piszesz, brzmi jak granica. Granice są ważne – co mówi Ci ta?',
        ]);
      case 'zagubienie':
        return pick([
          '"Nie wiem" to jedna z najuczciwszych odpowiedzi. Zostań z tą niepewnością – ona też coś mówi.',
          'Ciekawe – czy to pierwsze takie zagubienie, czy coś znajomego, co wraca?',
          'Chaos w środku bywa sygnałem, że coś się zmienia. Posłuchaj go, zanim zaczniesz naprawiać.',
          'Zagubiłeś kierunek – ale masz nogi. Jeden mały krok na razie wystarczy.',
        ]);
      case 'bol':
        return pick([
          'To boli. To wystarczy. Nie musisz tego teraz naprawiać ani rozumieć.',
          'Mówisz, że jest ciężko. Czy pozwalasz sobie to czuć – czy od razu próbujesz to odpychać?',
          'Ból jest tutaj. Ciekawe – gdzie dokładnie go czujesz w tej chwili?',
          'Ból to informacja. Czego strzeże? Co jest pod nim?',
        ]);
      case 'zlosc':
        return pick([
          'Złość ma coś do powiedzenia. Ciekawe, co pod nią leży – co tak naprawdę boli?',
          'Czujesz złość. To energia. Dokąd chce Cię poprowadzić?',
          '"Mam dość" – czegoś konkretnego, czy ogólnie wszystkiego? Ciekawe, co by odpowiedziało Twoje ciało.',
          'Złość to sygnał, że coś ważnego jest naruszane. Co to jest?',
        ]);
      case 'strach':
        return pick([
          'Strach też Cię chroni. Ciekawe, czego teraz pilnuje?',
          'To, czego się boisz, mówi coś ważnego o tym, na czym Ci zależy.',
          'Lęk jest obecny. Nie musisz go pokonywać – wystarczy, że go zauważasz.',
          'Strach i odwaga często siedzą obok siebie. Że piszesz – to też odwaga.',
        ]);
      case 'samotnosc':
        return pick([
          'Samotność boli inaczej niż inne rzeczy. Czy to samotność fizyczna, czy coś głębszego?',
          'Piszesz. To nie jest bycie sam w złym sensie – to kontakt z sobą. To też ma wartość.',
          'Nikt nie rozumie – ciekawe, czy próbowałeś powiedzieć to słowami komuś bliziemu?',
          'Jesteś tu. Ja jestem tu. Przez chwilę nie jesteś sam.',
        ]);
      case 'pokusa':
        return pick([
          'Ta chęć przyszła. Zauważyłeś ją – i jesteś tu, nie tam. To nie jest mała rzecz.',
          'Ciekawe, w którym miejscu w ciele czujesz to przyciąganie. Zostań z tym pytaniem.',
          'Pokusa jest informacją – co Ci teraz brakuje? Co próbuje wypełnić?',
          'Jedna chwila na raz. Teraz – właśnie teraz – dajesz radę.',
        ]);
      case 'sukces':
        return pick([
          'To, co napisałeś, nie brzmi małe. Brzmi jak coś, o co naprawdę zadbałeś.',
          'Ciekawe – czy pozwalasz sobie to poczuć, czy już jesteś myślami przy następnym kroku?',
          'Zostań z tym przez chwilę. Naprawdę. Zanim pójdziesz dalej.',
          'To się liczy. I zasługujesz na to, żeby to usłyszeć.',
        ]);
      case 'zalowanie':
        return pick([
          'Żal to dowód, że zależy Ci. Ciekawe, czego nauczył Cię ten czas, który opłakujesz.',
          'Patrzysz wstecz z bólem. Ale piszesz w teraźniejszości. To też jest coś.',
          'Przeszłości nie zmienisz – ale to, co teraz zrobisz z tą wiedzą, należy do Ciebie.',
          'Żałowanie to most między tym, kim byłeś, a tym, kim się stajesz.',
        ]);
      case 'zmeczenie':
        return pick([
          'Zmęczenie też coś mówi. Czy to zmęczenie ciała, czy czegoś więcej?',
          'Ciekawe – kiedy ostatnio dałeś sobie prawdziwy odpoczynek? Nie przerwę, ale odpoczynek.',
          'Twoje ciało sygnalizuje granicę. Czy słuchasz go, czy jeszcze prosisz o trochę więcej?',
          'Zmęczony jesteś – ale jesteś. I to wystarczy na dziś.',
        ]);
      case 'rodzina':
        return pick([
          'Relacje z bliskimi to jeden z najtrudniejszych obszarów w tej drodze. Co teraz chcesz z tym zrobić?',
          'To, co czujesz w związku z bliskimi – zostań z tym. Nie musisz tego teraz naprawiać.',
          'Ciekawe, co by powiedziała ta osoba, gdyby wiedziała, co teraz piszesz.',
          'Rodzina potrafi być i oparciem, i źródłem bólu. Co jest teraz bardziej prawdziwe?',
        ]);
      case 'sens':
        return pick([
          'Pytanie o sens pojawia się zazwyczaj wtedy, gdy coś naprawdę ważnego się rusza w środku.',
          'Ciekawe – kiedy ostatnio coś miało dla Ciebie wyraźny sens. Co to było?',
          'Sens nie jest gdzieś tam. Buduje się w małych krokach – takich jak ten, który właśnie zrobiłeś.',
        ]);
      case 'poprawa':
        return pick([
          'Zauważyłeś "lepiej". Ciekawe – co konkretnie się zmieniło? To ważne, żeby to pamiętać.',
          'Spokój. To rzadkie i ważne. Zostań z nim chwilę dłużej niż zazwyczaj.',
          'Dobry moment. Ciekawe, co go stworzyło – co możesz powtórzyć?',
          'Zapamiętaj to uczucie. Dokładnie takie, jakie jest teraz.',
        ]);
      case 'nadzieja':
        return pick([
          'Nadzieja to nie złudzenie – to decyzja, żeby nie przestawać. Trzymaj jej.',
          'Ciekawe – co konkretnie dało Ci tę nadzieję? Bo ona ma swój adres.',
          'Kiedy mówisz "może się uda" – coś w Tobie już wie, że tak.',
          'Ta iskierka jest realna. Dmuchaj na nią ostrożnie.',
        ]);
      case 'tozsamosc':
        return pick([
          'Bez alkoholu możesz nie wiedzieć, kim jesteś – ale teraz masz szansę to odkryć po raz pierwszy.',
          'Tożsamość to nie gotowy produkt. Ciekawe, co odkryłeś o sobie w tym tygodniu.',
          '"Kim jestem?" – to jedno z najważniejszych pytań. I całe szczęście, że je zadajesz.',
          'Nowy Ty dopiero się buduje. Daj mu czas.',
        ]);
      case 'cialo':
        return pick([
          'Ciało pamięta rzeczy, które umysł próbuje zapomnieć. Co teraz mówi Twoje?',
          'Zdrowie to nie tylko brak choroby – to kontakt z własnym ciałem. Jesteś w nim?',
          'Ciekawe, co Twoje ciało chciałoby teraz – naprawdę, nie to, co "powinno".',
          'Słuchasz ciała – to już dużo. Co konkretnie Ci mówi?',
        ]);
      case 'praca':
        return pick([
          'Stres finansowy jest realny i wyczerpujący. Ciekawe – co jest w Twojej kontroli, a co nie?',
          'Praca i pieniądze dotykają poczucia bezpieczeństwa. Co teraz czujesz się w stanie zrobić?',
          'To ciężkie. Jeden krok naraz – co jest najważniejsze do ogarnięcia dziś?',
          'Trudna sytuacja materialna nie definiuje Twojej wartości.',
        ]);
      case 'izolacja':
        return pick([
          'Wycofanie się bywa ochroną. Ciekawe – przed czym teraz się chronisz?',
          'Zamknąłeś się. Czy to wybór, czy już przyzwyczajenie? Co by się stało, gdybyś zrobił jeden mały kontakt?',
          'Izolacja jest kusząca, ale droga. Czy jest ktoś, do kogo mógłbyś napisać jedną wiadomość?',
          'Schowanie się na chwilę – ok. Schowanie się na zawsze – nie.',
        ]);
      case 'kontrola':
        return pick([
          'Potrzeba kontroli często maskuje lęk. Czego tak naprawdę się boisz stracić?',
          'Ciekawe – co by się stało, gdybyś odpuścił jedną rzecz? Tylko jedną.',
          'Kontrola daje iluzję bezpieczeństwa. Co by Ci dało prawdziwe bezpieczeństwo?',
          'Nie wszystko musisz trzymać w rękach. Coś może spaść i przeżyjesz.',
        ]);
      case 'perfekcjonizm':
        return pick([
          '80% wystarczy. Dosłownie – to wystarczy. Nie musisz być idealny, żeby być wartościowy.',
          'Ciekawe – kto Ci powiedział, że musisz być lepszy niż jesteś? To był błąd.',
          'Perfekcjonizm to lęk przebrany za standardy. Co tak naprawdę się boisz, że się stanie, jeśli odpuścisz?',
          '"Mogło być lepiej" – ale było. I to też się liczy.',
        ]);
      case 'akceptacja':
        return pick([
          'Akceptacja to odwaga. Nie rezygnacja – decyzja, że nie będziesz walczyć z tym, czego nie zmienisz.',
          'Ciekawe, jak się czujesz, gdy to mówisz. Czy to ulga, czy nadal boli?',
          'Przyjmujesz. To nie jest słabość – to dojrzałość, której wielu szuka latami.',
          'Spokój płynący z akceptacji jest inny niż spokój z ucieczkią. Który to?',
        ]);
      case 'granice':
        return pick([
          'Powiedziałeś "nie" – i jesteś. To znaczy, że możesz. Jak to było?',
          'Granica jest aktem miłości – też do siebie. Ciekawe, jak się czujesz po jej postawieniu.',
          'Dosyć – to ważne słowo. Rzadko wypowiadane, a zmienia wiele.',
          'Granice to nie mury – to drzwi, które otwierasz sam.',
        ]);
      case 'wdziecznosc':
        return pick([
          'Ciekawe, że to zauważyłeś. Wdzięczność to umiejętność, która rośnie z praktyką.',
          'Doceniasz. W tej drodze to nie jest mała rzecz – to dowód, że zmieniasz optykę.',
          'Zostań z tym uczuciem chwilę. Naprawdę. Zasługujesz na to, żeby to poczuć.',
          'Wdzięczność chroni. Im więcej jej widzisz, tym mniej miejsca na to, co niszczy.',
        ]);
      case 'terazniejszosc':
        return pick([
          'Byłeś obecny. Wiesz, ile osób przez całe życie tego nie osiąga?',
          'Ta chwila jest wszystkim, co masz – i widać, że to wiesz.',
          'Oddech, obecność – to fundament. Ciekawe, co czujesz, gdy jesteś naprawdę tu.',
          'Teraz. To jedyne miejsce, w którym cokolwiek realnego się wydarza.',
        ]);
      case 'zaufanie':
        return pick([
          'Zaufanie się odbudowuje powoli – jak kości po złamaniu. Czy zaczynasz ufać sobie?',
          'Ktoś Cię zawiódł. To boli długo. Ciekawe, co by pomogło Ci się z tym powoli poruszać.',
          'Nie ufasz – to uczciwe po tym, co przeżyłeś. Skąd zaczyna się odbudowa?',
          'Mały krok zaufania – do siebie – to najważniejszy z możliwych.',
        ]);
      case 'zmiana':
        return pick([
          'Zmieniasz się. To dezorientuje i jednocześnie jest dokładnie tym, na co czekałeś.',
          'Stary Ty i nowy Ty mogą przez chwilę istnieć obok siebie. To normalne.',
          'Ciekawe, co z tej nowej wersji siebie najbardziej Cię zaskakuje.',
          'Zmiana to jedyny dowód, że jesteś żywy i rozwijasz się.',
        ]);
      case 'kryzys_nocny':
        return pick([
          'Noc jest trudna – myśli głośniejsze, wszystko bardziej intensywne. Jesteś tu. To ważne.',
          'O tej porze wszystko wydaje się większe niż jest. Rano będzie inaczej – wierzę Ci.',
          'Napisałeś w nocy. To odwaga. Czego teraz potrzebujesz – ciszy, słów, czy po prostu obecności?',
          'Trwasz. O 3 w nocy, trwasz. To nie jest mała rzecz.',
        ]);
      case 'inne_uzaleznienie':
        return pick([
          'Każde uzależnienie to próba poradzenia sobie z czymś. Co próbuje wypełnić to, z czym walczysz?',
          'Jedna droga się zamknęła – i czasem otwiera się inna. Zauważasz ten wzorzec?',
          'Ciekawe, co masz wspólnego z tą substancją lub zachowaniem. Co ona Ci "daje"?',
          'To nie słabość. To mechanizm. A mechanizmy można zmienić.',
        ]);
      default:
        // fallback by question type
        switch (questionType) {
          case 'self_compassion':
            return pick([
              'Ciekawe, że potrafisz spojrzeć na siebie z tej perspektywy – 80% wystarczy.',
              'Co byś powiedział komuś, kogo kochasz, gdyby czuł to samo co Ty teraz?',
            ]);
          case 'curiosity':
            return pick([
              'Obserwowanie myśli to już droga – nie musisz ich zmieniać.',
              'Ciekawe, która z tych myśli powtarza się najczęściej. Zostań z nią.',
            ]);
          case 'body_scan':
            return pick([
              'Ciało pamięta – dobrze, że je słuchasz. Zostań z tym chwilę.',
              'To, co czujesz w ciele, ma swoją mądrość. Nie tłumacz – poczuj.',
            ]);
          case 'future_self':
            return pick([
              'Przyszłe „ja" już tu jest – w tym, że zadajesz to pytanie.',
              'Ciekawe, co chciałbyś, żeby to przyszłe „ja" o Tobie wiedziało.',
            ]);
          default:
            return 'Dziękuję za ten moment z sobą – droga się tworzy.';
        }
    }
  }

  Future<String> decryptAnswer(String encrypted) => _enc.decrypt(encrypted);
}
