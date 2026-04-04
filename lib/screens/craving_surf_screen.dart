import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _previewTimer;
  int _secondsLeft = 600; // 10 minutes
  bool _running = false;
  int _ridingNow = 0;
  final _soundscape = SoundscapeService();
  final _analytics = AnalyticsService();
  String? _selectedSoundscape;

  // Free tier: 30s preview after 3rd use
  int _usageCount = 0;
  static const _previewThreshold = 3;
  static const _previewDuration = 30;

  @override
  void initState() {
    super.initState();
    _loadUsageCount();
  }

  Future<void> _loadUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _usageCount = prefs.getInt('craving_surf_usage') ?? 0);
  }

  Future<void> _incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    _usageCount++;
    await prefs.setInt('craving_surf_usage', _usageCount);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _previewTimer?.cancel();
    _soundscape.stop();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _analytics.track('craving_surf_started', {'has_soundscape': _selectedSoundscape != null});
    TtsService().playAsset('audio/craving/craving_intro.mp3');
    if (_selectedSoundscape == null) _soundscape.play('craving_wave');
    _insertSession();
    _incrementUsage();
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
    _previewTimer?.cancel();
    _soundscape.stop();
    setState(() => _running = false);
  }

  /// For free users: play soundscape for 30s then stop and show upsell.
  void _startPreview(String key) {
    _soundscape.play(key);
    setState(() => _selectedSoundscape = key);
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: _previewDuration), () {
      if (!mounted) return;
      _soundscape.stop();
      setState(() => _selectedSoundscape = null);
      _showPreviewEnded();
    });
  }

  void _showPreviewEnded() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('30s preview zakończony', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Odblokuj pełne soundscapes w Recovery+', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/paywall', arguments: 'craving_surf_preview');
                },
                child: const Text('Wypróbuj Recovery+ za darmo', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Może później', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
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
    HapticFeedback.heavyImpact();
    _analytics.track('craving_surf_completed', {'duration_sec': 600, 'soundscape_used': _selectedSoundscape});
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti emoji animation
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(S.t(context, 'youRodeTheWave'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('10 minut. Fala przeszła.', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Udostępnij'),
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                'Właśnie przeżyłem/am głód bez używania. 10 minut surfowania na fali. 🌊 #SoberSteps #CravingSurf',
                subject: 'Przeżyłem/am głód!',
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.t(context, 'ok')),
          ),
        ],
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
                  style: const TextStyle(
                      fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -2, color: AppColors.textPrimary)),
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
                  child: Text(_running ? S.t(context, 'stop') : S.t(context, 'start'),
                      style: const TextStyle(fontSize: 18)),
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
          // Free users get 30s preview after 3rd session; before that → paywall
          final canPreview = !isPremium && _usageCount >= _previewThreshold;

          return GestureDetector(
            onTap: () {
              if (isPremium) {
                setState(() => _selectedSoundscape = selected ? null : entry.key);
                if (!selected) {
                  _soundscape.play(entry.key);
                } else {
                  _soundscape.stop();
                }
              } else if (canPreview) {
                // 30s preview
                _startPreview(entry.key);
              } else {
                // Direct to paywall
                Navigator.of(context).pushNamed('/paywall', arguments: 'soundscape_picker');
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
                  if (!isPremium)
                    Icon(
                      canPreview ? Icons.play_circle_outline : Icons.lock,
                      size: 16,
                      color: canPreview ? AppColors.primary : AppColors.textSecondary,
                    ),
                  Text(entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 12)),
                  if (!isPremium && canPreview)
                    const Text('30s', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
