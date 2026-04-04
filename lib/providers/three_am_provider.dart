import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/three_am_post.dart';
import '../services/analytics_service.dart';
import '../services/mirror_mind_service.dart';

class ThreeAmProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  List<ThreeAmPost> _resolvedPosts = [];
  int _resolvedCount = 0;
  bool _loading = false;

  /// ID of the current user's unresolved post (set after submitPost, cleared after resolve).
  String? _myActivePostId;

  List<ThreeAmPost> get resolvedPosts => _resolvedPosts;
  int get resolvedCount => _resolvedCount;
  bool get loading => _loading;

  /// Whether the current user has an active (unresolved) post.
  bool get hasActivePost => _myActivePostId != null;
  String? get myActivePostId => _myActivePostId;

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

  /// Load the current user's unresolved post on startup (for "I got through" button state).
  Future<void> loadMyActivePost() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await client
          .from('three_am_wall')
          .select('id')
          .eq('user_id', user.id)
          .is_('resolved_at', null)
          .order('created_at', ascending: false)
          .limit(1);
      if ((data as List).isNotEmpty) {
        _myActivePostId = data.first['id'] as String?;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Submit "I'm struggling" post. Returns null on success, error string on failure.
  /// Sets [_myActivePostId] on success for later resolve.
  Future<String?> submitPost() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 'Zaloguj się';

    try {
      final canPost = await client.rpc(
        'check_three_am_rate_limit',
        params: {'p_user_id': user.id},
      );
      if (canPost == false) return 'Poczekaj przed kolejnym wpisem';
    } catch (_) {}

    try {
      final response = await client
          .from('three_am_wall')
          .insert({'user_id': user.id})
          .select('id')
          .single();
      _myActivePostId = response['id'] as String?;
      _analytics.track('three_am_wall_posted');
      notifyListeners();
      return null;
    } catch (e) {
      return 'Coś poszło nie tak. Spróbuj ponownie.';
    }
  }

  /// Resolve the current user's active post.
  /// Uses [postId] if provided, otherwise falls back to [_myActivePostId].
  Future<String?> resolvePost(String? postId, {String? outcomeText}) async {
    final id = postId ?? _myActivePostId;
    if (id == null) return 'Brak aktywnego wpisu do zamknięcia';

    try {
      final update = <String, dynamic>{
        'resolved_at': DateTime.now().toIso8601String(),
      };
      if (outcomeText != null && outcomeText.isNotEmpty) {
        update['outcome_text'] = outcomeText;
      }
      await Supabase.instance.client
          .from('three_am_wall')
          .update(update)
          .eq('id', id);
      _myActivePostId = null;
      _analytics.track('three_am_wall_resolved');
      MirrorMindService().onThreeAmResolved(outcomeText: outcomeText);
      notifyListeners();
      await loadPosts();
      return null;
    } catch (e) {
      return 'Coś poszło nie tak. Spróbuj ponownie.';
    }
  }
}
