import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../formatting/locale_dates.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../providers/community_provider.dart';
import '../providers/purchase_provider.dart';
import '../models/community_post.dart';
import '../l10n/strings.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = ['wins', 'hard', 'advice', 'milestones'];
  static const _tabKeys = ['successes', 'hardMoments', 'advice', 'milestones'];
  final _tabEmojis = ['🎉', '💪', '💡', '🏆'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final isPro = context.read<PurchaseProvider>().isPro;
        context.read<CommunityProvider>().loadPosts(
          _categories[_tabController.index],
          isPro: isPro,
        );
      }
    });
    final isPro = context.read<PurchaseProvider>().isPro;
    context.read<CommunityProvider>().loadPosts(_categories[0], isPro: isPro);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'community')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: List.generate(4, (i) => Tab(text: '${_tabEmojis[i]} ${S.t(context, _tabKeys[i])}')),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showNewPostDialog(),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) => _PostsList(category: cat)).toList(),
      ),
    );
  }

  void _showNewPostDialog() {
    final controller = TextEditingController();
    String selectedCat = _categories[_tabController.index];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.t(context, 'newPost'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _categories.asMap().entries.map((e) {
                return ChoiceChip(
                  label: Text('${_tabEmojis[e.key]} ${S.t(context, _tabKeys[e.key])}'),
                  selected: selectedCat == e.value,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(color: selectedCat == e.value ? AppColors.primary : AppColors.textSecondary),
                  onSelected: (_) {
                    selectedCat = e.value;
                    (ctx as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: AppConstants.maxPostLength,
              maxLines: 4,
              decoration: InputDecoration(hintText: S.t(context, 'share')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  final result = await context.read<CommunityProvider>().createPost(selectedCat, text);
                  controller.dispose();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (result != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                  }
                },
                child: Text(S.t(context, 'publish')),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  final String category;
  const _PostsList({required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final isPro = context.watch<PurchaseProvider>().isPro;
    final posts = provider.postsForCategory(category);

    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (posts.isEmpty) return Center(child: Text(S.t(context, 'noPosts'), style: const TextStyle(color: AppColors.textSecondary)));

    return RefreshIndicator(
      onRefresh: () => provider.loadPosts(category, isPro: isPro),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length + (isPro ? 0 : 1),
        itemBuilder: (context, i) {
          // Last item for free users: PRO history upsell banner
          if (!isPro && i == posts.length) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/paywall', arguments: 'community_history'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, top: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Odblokuj pełną historię w Recovery+',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
                  ],
                ),
              ),
            );
          }
          return _PostCard(post: posts[i]);
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final catEmoji = {'wins': '🎉', 'hard': '💪', 'advice': '💡', 'milestones': '🏆'}[post.category] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$catEmoji ${post.content}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.read<CommunityProvider>().toggleLike(post),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              Text(LocaleDates.dMMMHm(context, post.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showReportMenu(context),
                child: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: AppColors.error),
              title: Text(S.t(context, 'report'), style: const TextStyle(color: AppColors.error)),
              onTap: () {
                context.read<CommunityProvider>().flagPost(post.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'reported'))));
              },
            ),
          ],
        ),
      ),
    );
  }
}
