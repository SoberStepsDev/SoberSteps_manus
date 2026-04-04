import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/return_to_self.dart';

/// Wall of Strength — anonymous, raw feed
class WallProvider extends ChangeNotifier {
  List<WallOfStrengthPost> _posts = [];
  List<WallOfStrengthPost> get posts => _posts;
  bool _loading = false;
  bool get loading => _loading;

  final _supabase = Supabase.instance.client;

  Future<void> loadPosts() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _supabase
          .from('return_to_self_wall')
          .select()
          .order('timestamp', ascending: false)
          .limit(50);
      _posts = (res as List).map((e) => WallOfStrengthPost.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> addPost(String content, {bool anonymous = true}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase.from('return_to_self_wall').insert({
      'id': const Uuid().v4(),
      'user_id': uid,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'anonymous': anonymous,
    });
    await loadPosts();
  }
}
