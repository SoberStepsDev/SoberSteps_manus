import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/sobriety_provider.dart';
import '../services/tts_service.dart';

class MirrorMomentScreen extends StatefulWidget {
  const MirrorMomentScreen({super.key});

  @override
  State<MirrorMomentScreen> createState() => _MirrorMomentScreenState();
}

class _MirrorMomentScreenState extends State<MirrorMomentScreen> {
  static const _mirrorDays = [7, 14, 21, 28];

  static const _promptKeys = {
    7: 'reflection7',
    14: 'reflection14',
    21: 'reflection21',
    28: 'reflection28',
  };

  static const _subtitleKeys = {
    7: 'day7Reflection',
    14: 'day14Reflection',
    21: 'day21Reflection',
    28: 'day28Reflection',
  };

  final _controller = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  int _activeMirrorDay = 7;
  Set<int> _completedDays = {};

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final sobriety = context.read<SobrietyProvider>();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('mirror_completed') ?? [];
    final daysSober = sobriety.daysSober;

    // Find the most relevant mirror day
    int active = _mirrorDays.first;
    for (final d in _mirrorDays) {
      if (daysSober >= d) active = d;
    }

    setState(() {
      _completedDays = completed.map(int.parse).toSet();
      _activeMirrorDay = active;
    });

    // Play audio for the active mirror day
    TtsService().playAsset('audio/mirror/mirror_day$_activeMirrorDay.mp3');
  }

  @override
  void dispose() {
    _controller.dispose();
    TtsService().stop();
    super.dispose();
  }

  void _switchDay(int day) {
    if (day == _activeMirrorDay) return;
    TtsService().stop();
    setState(() => _activeMirrorDay = day);
    TtsService().playAsset('audio/mirror/mirror_day$day.mp3');
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('journal_entries').insert({
          'user_id': user.id,
          'mood': 5,
          'craving_level': 0,
          'triggers': <String>[],
          'note': '[Mirror Day $_activeMirrorDay] $text',
        });
      }
      final prefs = await SharedPreferences.getInstance();
      _completedDays.add(_activeMirrorDay);
      await prefs.setStringList(
        'mirror_completed',
        _completedDays.map((d) => d.toString()).toList(),
      );
      if (mounted) {
        setState(() {
          _saved = true;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysSober = context.watch<SobrietyProvider>().daysSober;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'mirrorMoment')),
        actions: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDaySelector(daysSober),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildPromptCard(),
                    const SizedBox(height: 24),
                    if (!_saved) ...[
                      _buildMirrorButton(),
                    const SizedBox(height: 16),
                    _buildTextField(),
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ] else
                      _buildSavedState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(int daysSober) {
    return Container(
      height: 56,
      color: AppColors.surface,
      child: Row(
        children: _mirrorDays.map((day) {
          final unlocked = daysSober >= day;
          final active = day == _activeMirrorDay;
          final done = _completedDays.contains(day);
          return Expanded(
            child: GestureDetector(
              onTap: unlocked ? () => _switchDay(day) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.t(context, 'day$day'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: unlocked
                            ? (active ? AppColors.primary : AppColors.textPrimary)
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (done)
                      const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                    if (!unlocked)
                      const Icon(Icons.lock, size: 12, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t(context, _subtitleKeys[_activeMirrorDay] ?? ''),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.graphic_eq, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              S.t(context, 'voicePlaying'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        S.t(context, _promptKeys[_activeMirrorDay] ?? ''),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMirrorButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.face_retouching_natural, color: AppColors.primary),
        label: Text(
          S.t(context, 'openMirror'),
          style: const TextStyle(color: AppColors.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final uri = Uri.parse('android.media.action.IMAGE_CAPTURE_SECURE');
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open your front camera to see yourself.')),
              );
            }
          }
        },
      ),
    );
  }
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      maxLines: 7,
      maxLength: 1000,
      decoration: InputDecoration(
        hintText: S.t(context, 'writeReflection'),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        counterStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      style: const TextStyle(color: AppColors.textPrimary, height: 1.6),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
              )
            : Text(S.t(context, 'saveReflection')),
      ),
    );
  }

  Widget _buildSavedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 40),
          const SizedBox(height: 12),
          Text(
            S.t(context, 'reflectionSaved'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            S.t(context, 'comeBackReady'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
