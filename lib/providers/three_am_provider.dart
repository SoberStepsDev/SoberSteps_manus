import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/three_am_post.dart';
import '../services/analytics_service.dart';

class ThreeAmProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  List<ThreeAmPost> _resolvedPosts = [];
  int _resolvedCount = 0;
  bool _loading = false;

  List<ThreeAmPost> get resolvedPosts => _resolvedPosts;
  int get resolvedCount => _resolvedCount;
  bool get loading => _loading;

  Future<void> loadPosts() async {
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final client = Supabase.instance.client;
      final countResult = await client
          .from('three_am_wall')
          .select()
          .not('resolved_at', 'is', null)
          .eq('is_visible', true)
          .count();
      _resolvedCount = countResult.count;

      final data = await client
          .from('three_am_wall')
          .select()
          .not('resolved_at', 'is', null)
          .eq('is_visible', true)
          .order('resolved_at', ascending: false)
          .limit(100);
      _resolvedPosts = (data as List).map((e) => ThreeAmPost.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<String?> submitPost() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 'Zaloguj się';

    try {
      final canPost = await client.rpc('check_three_am_rate_limit', params: {'p_user_id': user.id});
      if (canPost == false) return 'Poczekaj przed kolejnym wpisem';
    } catch (_) {}

    try {
      await client.from('three_am_wall').insert({
        'user_id': user.id,
      });
      _analytics.track('three_am_wall_posted');
      return null;
    } catch (e) {
      return 'Coś poszło nie tak. Spróbuj ponownie.';
    }
  }

  Future<String?> resolvePost(String postId, {String? outcomeText}) async {
    try {
      await Supabase.instance.client.from('three_am_wall').update({
        'resolved_at': DateTime.now().toIso8601String(),
        ...? (outcomeText != null ? {'outcome_text': outcomeText} : null),
      }).eq('id', postId);
      _analytics.track('three_am_wall_resolved');
      await loadPosts();
      return null;
    } catch (e) {
      return 'Coś poszło nie tak. Spróbuj ponownie.';
    }
  }
}
