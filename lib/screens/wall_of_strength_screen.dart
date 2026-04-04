import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/wall_provider.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';

/// Philosophy applied: raw, anonymous, no likes — just presence
class WallOfStrengthScreen extends StatefulWidget {
  const WallOfStrengthScreen({super.key});

  @override
  State<WallOfStrengthScreen> createState() => _WallOfStrengthScreenState();
}

class _WallOfStrengthScreenState extends State<WallOfStrengthScreen> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    context.read<WallProvider>().loadPosts();
    AnalyticsService().track('wall_of_strength_opened');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'karmaWriteFirst'))),
      );
      return;
    }
    if (_isPosting) return;
    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<WallProvider>().addPost(text);
      if (!mounted) return;
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'wallPostError'))),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wall = context.watch<WallProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'threeAmWall')),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                S.t(context, 'wallIntro'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: wall.loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : wall.posts.isEmpty
                      ? Center(
                          child: Text(
                            S.t(context, 'wallEmpty'),
                            style: TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: wall.posts.length,
                          itemBuilder: (_, i) {
                            final post = wall.posts[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.content,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    post.timestamp.toString().substring(0, 16),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(
                                  duration: 400.ms,
                                  delay: Duration(milliseconds: i * 60),
                                );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: S.t(context, 'wallHint'),
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPosting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : Tooltip(
                          message: S.t(context, 'publish'),
                          child: Semantics(
                            label: S.t(context, 'publish'),
                            button: true,
                            child: IconButton(
                              onPressed: _post,
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
