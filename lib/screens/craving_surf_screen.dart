import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../services/soundscape_service.dart';
import '../services/tts_service.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';

class CravingSurfScreen extends StatefulWidget {
  const CravingSurfScreen({super.key});

  @override
  State<CravingSurfScreen> createState() => _CravingSurfScreenState();
}

class _CravingSurfScreenState extends State<CravingSurfScreen> {
  Timer? _timer;
  int _secondsLeft = 600; // 10 minutes
  bool _running = false;
  int _ridingNow = 0;
  final _soundscape = SoundscapeService();
  final _analytics = AnalyticsService();
  String? _selectedSoundscape;

  @override
  void dispose() {
    _timer?.cancel();
    _soundscape.stop();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _analytics.track('craving_surf_started', {'has_soundscape': _selectedSoundscape != null});
    TtsService().playAsset('audio/craving/craving_intro.mp3');
    // Extend audio: play craving_wave in loop during session when no soundscape selected
    if (_selectedSoundscape == null) _soundscape.play('craving_wave');
    _insertSession();
    _fetchRidingCount();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        setState(() => _running = false);
        _showComplete();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft % 30 == 0) _fetchRidingCount();
    });
  }

  void _stop() {
    _timer?.cancel();
    _soundscape.stop();
    setState(() => _running = false);
  }

  Future<void> _insertSession() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client.from('craving_surf_sessions').insert({
        'user_id': user.id,
        'soundscape_used': _selectedSoundscape,
      });
    } catch (_) {}
  }

  Future<void> _fetchRidingCount() async {
    try {
      final result = await Supabase.instance.client
          .from('craving_surf_sessions')
          .select()
          .gte('started_at', DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String())
          .count();
      if (mounted) setState(() => _ridingNow = result.count);
    } catch (_) {}
  }

  void _showComplete() {
    _soundscape.stop();
    TtsService().playAsset('audio/craving/craving_end.mp3');
    _analytics.track('craving_surf_completed', {'duration_sec': 600, 'soundscape_used': _selectedSoundscape});
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 64, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(S.t(context, 'youRodeTheWave'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(S.t(context, 'ok')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseProvider>().isPremium;
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final progress = 1.0 - (_secondsLeft / 600);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'cravingSurf'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_ridingNow > 0)
                Text('$_ridingNow ${S.t(context, 'peopleRiding')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildSoundscapePicker(isPremium),
              const Spacer(),
              SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _WavePainter(progress: progress),
                  size: const Size(double.infinity, 100),
                ),
              ),
              const SizedBox(height: 32),
              Text('$minutes:$seconds',
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -2, color: AppColors.textPrimary)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _running ? AppColors.error : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_running) {
                      _stop();
                    } else {
                      _start();
                    }
                  },
                  child: Text(_running ? S.t(context, 'stop') : S.t(context, 'start'), style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundscapePicker(bool isPremium) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SoundscapeService.soundscapes.entries.map((entry) {
          final selected = _selectedSoundscape == entry.key;
          return GestureDetector(
            onTap: () {
              if (!isPremium) {
                Navigator.of(context).pushNamed('/paywall');
                return;
              }
              setState(() => _selectedSoundscape = selected ? null : entry.key);
              if (!selected) {
                _soundscape.play(entry.key);
              } else {
                _soundscape.stop();
              }
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceLight),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isPremium) const Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
                  Text(entry.value, textAlign: TextAlign.center, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final amplitude = 30.0 * (1.0 - progress * 0.7);
    final color = Color.lerp(AppColors.primary, AppColors.success, progress)!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + amplitude * sin(x * 0.03 + progress * 20);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}
