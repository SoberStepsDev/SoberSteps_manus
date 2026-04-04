import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'encryption_service.dart';

/// GDPR Art. 20 — portable JSON export of user-owned Supabase rows (within RLS).
class DataExportService {
  final SupabaseClient _client;
  final EncryptionService _enc = EncryptionService();

  DataExportService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<File> exportToJsonFile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('not_authenticated');

    final uid = user.id;
    final exported = <String, dynamic>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': uid,
      'profiles': await _selectEq('profiles', 'id', uid),
      'journal_entries': await _selectEq('journal_entries', 'user_id', uid),
      'milestones_achieved': await _selectEq('milestones_achieved', 'user_id', uid),
      'future_letters': await _selectEq('future_letters', 'user_id', uid),
      'three_am_wall': await _selectEq('three_am_wall', 'user_id', uid),
      'craving_surf_sessions': await _selectEq('craving_surf_sessions', 'user_id', uid),
      'community_posts': await _selectEq('community_posts', 'user_id', uid),
      'family_observers': await _selectEq('family_observers', 'subscriber_user_id', uid),
      'return_to_self_progress': await _selectEq('return_to_self_progress', 'user_id', uid),
      'return_to_self_karma': await _decodeKarma(await _selectEq('return_to_self_karma', 'user_id', uid)),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exported);
    final dir = await getTemporaryDirectory();
    final safeName = 'sobersteps_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$safeName');
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<List<dynamic>> _selectEq(String table, String column, String value) async {
    try {
      final data = await _client.from(table).select().eq(column, value);
      return List<dynamic>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _decodeKarma(List<dynamic> rows) async {
    final out = <Map<String, dynamic>>[];
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final enc = row['answer_encrypted'] as String?;
      if (enc != null && enc.isNotEmpty) {
        try {
          row['answer_decrypted'] = await _enc.decrypt(enc);
        } catch (_) {
          row['answer_decrypted'] = null;
        }
      }
      out.add(row);
    }
    return out;
  }
}
