import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post.dart';
import '../services/analytics_service.dart';
import '../constants/app_constants.dart';

class CommunityProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  final Map<String, List<CommunityPost>> _posts = {};
  bool _loading = false;

  List<CommunityPost> postsForCategory(String cat) => _posts[cat] ?? [];
  bool get loading => _loading;

  Future<void> loadPosts(String category) async {
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('community_posts')
          .select()
          .eq('category', category)
          .eq('is_flagged', false)
          .order('created_at', ascending: false)
          .limit(50);
      _posts[category] = (data as List).map((e) => CommunityPost.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<String?> createPost(String category, String content) async {
    if (AppConstants.urlRegex.hasMatch(content)) return 'Linki są niedozwolone';
    if (content.length > AppConstants.maxPostLength) return 'Post jest za długi';

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 'Zaloguj się';

    try {
      final canPost = await client.rpc('check_post_rate_limit', params: {'p_user_id': user.id});
      if (canPost == false) return 'Poczekaj chwilę przed kolejnym postem';
    } catch (_) {}

    try {
      await client.from('community_posts').insert({
        'user_id': user.id,
        'category': category,
        'content': content,
      });
      _analytics.track('community_post_created', {'category': category});
      await loadPosts(category);
      return null;
    } catch (e) {
      return 'Coś poszło nie tak. Spróbuj ponownie.';
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final idx = _posts[post.category]?.indexWhere((p) => p.id == post.id) ?? -1;
    if (idx == -1) return;
    final newCount = post.likesCount + 1;
    _posts[post.category]![idx] = CommunityPost(
      id: post.id,
      userId: post.userId,
      category: post.category,
      content: post.content,
      likesCount: newCount,
      isFlagged: post.isFlagged,
      flagCount: post.flagCount,
      createdAt: post.createdAt,
    );
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('community_posts')
          .update({'likes_count': newCount}).eq('id', post.id);
    } catch (_) {}
  }

  Future<void> flagPost(String postId) async {
    try {
      await Supabase.instance.client.rpc('flag_post', params: {'p_post_id': postId});
    } catch (_) {}
  }
}
