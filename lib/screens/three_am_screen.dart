import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../providers/three_am_provider.dart';
import '../providers/auth_provider.dart';
import '../services/soundscape_service.dart';
import '../services/tts_service.dart';
import '../l10n/strings.dart';

class ThreeAmScreen extends StatefulWidget {
  const ThreeAmScreen({super.key});

  @override
  State<ThreeAmScreen> createState() => _ThreeAmScreenState();
}

class _ThreeAmScreenState extends State<ThreeAmScreen> {
  final _soundscape = SoundscapeService();

  @override
  void initState() {
    super.initState();
    final p = context.read<ThreeAmProvider>();
    p.loadPosts();
    p.loadMyActivePost();
    _soundscape.play('white_noise');
  }

  @override
  void dispose() {
    _soundscape.stop();
    TtsService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThreeAmProvider>();
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'threeAmWall'))),
      body: Column(
        children: [
          _buildSamhsaBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${provider.resolvedCount} ${S.t(context, 'peopleGotThrough3am')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.resolvedPosts.length,
                    itemBuilder: (context, i) {
                      final post = provider.resolvedPosts[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.outcomeText != null && post.outcomeText!.isNotEmpty)
                              Text(post.outcomeText!, style: const TextStyle(color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              S.t(context, 'iGotThrough'),
                              style: TextStyle(color: AppColors.success, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (isLoggedIn) _buildBottomActions(context, provider),
        ],
      ),
    );
  }

  Widget _buildSamhsaBanner() {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:${AppConstants.samhsaPhone}')),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: AppColors.crisisRed,
        child: Text(
          S.t(context, 'samhsaCrisis'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThreeAmProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.crisisRed, foregroundColor: AppColors.textPrimary),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  TtsService().playAsset('audio/three_am/breath_guide.mp3');
                  _submitStruggling(provider);
                },
                child: Text(S.t(context, 'iStruggling')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.textPrimary),
                onPressed: provider.hasActivePost
                    ? () {
                        HapticFeedback.lightImpact();
                        _resolveDialog(provider);
                      }
                    : null,
                child: Text(S.t(context, 'iGotThrough')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitStruggling(ThreeAmProvider provider) async {
    final result = await provider.submitPost();
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'holdOn'))),
      );
    }
  }

  Future<void> _resolveDialog(ThreeAmProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.t(context, 'youMadeIt')),
        content: TextField(
          controller: controller,
          maxLength: AppConstants.maxOutcomeLength,
          maxLines: 3,
          decoration: InputDecoration(hintText: S.t(context, 'howDoYouFeelNow')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.t(context, 'cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(S.t(context, 'save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    if (!mounted) return;
    // Pass null — provider uses _myActivePostId internally
    final error = await provider.resolvePost(
      null,
      outcomeText: result.trim().isEmpty ? null : result.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.t(context, 'congrats'))));
    }
  }
}
