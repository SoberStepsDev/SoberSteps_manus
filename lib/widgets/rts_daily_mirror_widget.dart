import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';

/// Daily Mirror Widget — shows 1 of 5 rotating reflective questions.
/// 4 languages: PL, EN, ES, NL. Rotates daily (day-of-year % 5).
/// Privacy-first: answers stored locally only (SharedPreferences).
class RTSDailyMirrorWidget extends StatefulWidget {
  const RTSDailyMirrorWidget({super.key});
  @override
  State<RTSDailyMirrorWidget> createState() => _RTSDailyMirrorWidgetState();
}

class _RTSDailyMirrorWidgetState extends State<RTSDailyMirrorWidget> {
  static const _questions = {
    'pl': [
      'Co dziś czujesz wobec siebie — bez oceniania?',
      'Czego potrzebujesz teraz, czego nie dajesz sobie na co dzień?',
      'Kiedy ostatnio byłeś dla siebie życzliwy? Co to było?',
      'Co w sobie odkryłeś w ostatnich dniach?',
      'Gdybyś mógł powiedzieć sobie coś ważnego — co by to było?',
    ],
    'en': [
      'What do you feel toward yourself today — without judgment?',
      'What do you need right now that you rarely give yourself?',
      'When were you last kind to yourself? What did that look like?',
      'What have you discovered about yourself recently?',
      'If you could tell yourself something important — what would it be?',
    ],
    'es': [
      '¿Qué sientes hacia ti hoy, sin juzgarte?',
      '¿Qué necesitas ahora que rara vez te das?',
      '¿Cuándo fuiste amable contigo por última vez?',
      '¿Qué has descubierto sobre ti mismo recientemente?',
      'Si pudieras decirte algo importante, ¿qué sería?',
    ],
    'nl': [
      'Wat voel je vandaag voor jezelf — zonder oordeel?',
      'Wat heb je nu nodig dat je jezelf zelden geeft?',
      'Wanneer was je voor het laatst vriendelijk voor jezelf?',
      'Wat heb je de laatste tijd over jezelf ontdekt?',
      'Als je jezelf iets belangrijks kon zeggen — wat zou dat zijn?',
    ],
  };

  final _ctrl = TextEditingController();
  String _lang = 'pl';
  String? _savedAnswer;
  bool _editing = false;
  bool _saved = false;

  int get _questionIndex => DateTime.now().dayOfYear % 5;
  String get _question => (_questions[_lang] ?? _questions['pl']!)[_questionIndex];

  @override
  void initState() {
    super.initState();
    _loadSaved();
    AnalyticsService().track('rts_daily_mirror_viewed');
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mirror_answer_${DateTime.now().toIso8601String().substring(0, 10)}_$_questionIndex';
    final answer = prefs.getString(key);
    if (mounted) setState(() { _savedAnswer = answer; _ctrl.text = answer ?? ''; });
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'mirror_answer_${DateTime.now().toIso8601String().substring(0, 10)}_$_questionIndex';
    await prefs.setString(key, text);
    setState(() { _savedAnswer = text; _editing = false; _saved = true; });
    AnalyticsService().track('rts_daily_mirror_answered');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🪞', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(S.t(context, 'rtsDailyMirrorTitle'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            // Language selector
            DropdownButton<String>(
              value: _lang,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'pl', child: Text('PL')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
                DropdownMenuItem(value: 'es', child: Text('ES')),
                DropdownMenuItem(value: 'nl', child: Text('NL')),
              ],
              onChanged: (v) => setState(() { _lang = v!; _loadSaved(); }),
            ),
          ]),
          const SizedBox(height: 10),
          Text(_question, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          if (_savedAnswer != null && !_editing) ...[
            Text(_savedAnswer!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Text(S.t(context, 'rtsDailyMirrorEdit'), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ] else ...[
            TextField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: S.t(context, 'rtsDailyMirrorHint'),
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(S.t(context, 'rtsDailyMirrorPrivacy'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const Spacer(),
              if (_saved)
                Text(S.t(context, 'rtsDailyMirrorSaved'), style: const TextStyle(color: Colors.greenAccent, fontSize: 12))
              else
                TextButton(
                  onPressed: _save,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                  child: Text(S.t(context, 'save'), style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}

extension _DateTimeExt on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays;
  }
}
