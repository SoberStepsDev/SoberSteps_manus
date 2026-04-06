import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/return_to_self.dart';
import '../services/encryption_service.dart';

/// Karma Mirror — evening question + history
class KarmaProvider extends ChangeNotifier {
  List<KarmaEntry> _entries = [];
  List<KarmaEntry> get entries => _entries;
  bool _loading = false;
  bool get loading => _loading;

  final _enc = EncryptionService();
  final _supabase = Supabase.instance.client;

  static const int eveningQuestionCount = 7;

  /// Index 0..6 — rotate daily; UI uses `S.t(context, 'karmaEveningQ$index')`.
  int get todayQuestionIndex {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return dayOfYear % eveningQuestionCount;
  }

  Future<void> loadEntries() async {
    _loading = true;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('return_to_self_karma')
          .select()
          .eq('user_id', uid)
          .order('response_date', ascending: false)
          .limit(30);
      _entries = (res as List).map((e) => KarmaEntry.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> saveAnswer(String answer) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final encrypted = await _enc.encrypt(answer);
    await _supabase.from('return_to_self_karma').insert({
      'id': const Uuid().v4(),
      'user_id': uid,
      'subcategory': 'evening_reflection',
      'response': encrypted,
      'response_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    await loadEntries();
  }

  Future<String> decryptAnswer(String encrypted) => _enc.decrypt(encrypted);
}
