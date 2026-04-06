import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';
import '../widgets/pro_gate_widget.dart';

/// Self-Experiments screen — 3-day behavioral experiment.
/// Table: self_experiments (id, user_id, thought, action, results jsonb, created_at)
class ExperimentScreen extends StatefulWidget {
  const ExperimentScreen({super.key});
  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  final _thoughtCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  List<Map<String, dynamic>> _experiments = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<PurchaseProvider>().isPro) {
        setState(() => _loading = false);
        return;
      }
      _load();
      AnalyticsService().track(AnalyticsService.eSelfCompassionOpened, {'card': 'self_experiments'});
    });
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('self_experiments')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      setState(() { _experiments = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _start() async {
    final thought = _thoughtCtrl.text.trim();
    final action = _actionCtrl.text.trim();
    if (thought.isEmpty || action.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final entry = {
      'id': const Uuid().v4(),
      'user_id': user.id,
      'thought': thought,
      'action': action,
      'results': {'day1': null, 'day2': null, 'day3': null},
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await Supabase.instance.client.from('self_experiments').insert(entry);
      _thoughtCtrl.clear(); _actionCtrl.clear();
      setState(() => _experiments.insert(0, entry));
      AnalyticsService().track(AnalyticsService.eExperimentStarted);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t(context, 'experimentSnackStarted'))));
    } catch (_) {}
    setState(() => _saving = false);
  }

  Future<void> _recordResult(String id, String day, String result) async {
    final idx = _experiments.indexWhere((e) => e['id'] == id);
    if (idx == -1) return;
    final results = Map<String, dynamic>.from(_experiments[idx]['results'] ?? {});
    results[day] = result;
    setState(() => _experiments[idx] = {..._experiments[idx], 'results': results});
    try {
      await Supabase.instance.client.from('self_experiments').update({'results': results}).eq('id', id);
      final allDone = results['day1'] != null && results['day2'] != null && results['day3'] != null;
      if (allDone) AnalyticsService().track(AnalyticsService.eExperimentCompleted);
    } catch (_) {}
  }

  @override
  void dispose() { _thoughtCtrl.dispose(); _actionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(S.t(context, 'experimentTitle'), style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ProGateWidget(
        trigger: 'experiment_gate',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.t(context, 'experimentNewLabel'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            _field(context, _thoughtCtrl, S.t(context, 'experimentThoughtLabel'), S.t(context, 'experimentThoughtHint')),
            const SizedBox(height: 8),
            _field(context, _actionCtrl, S.t(context, 'experimentActionLabel'), S.t(context, 'experimentActionHint')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _start,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(S.t(context, 'experimentStartBtn'), style: const TextStyle(color: Colors.white)),
              ),
            ),
            if (_experiments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(S.t(context, 'experimentActiveLabel'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              if (_loading) const Center(child: CircularProgressIndicator()),
              ..._experiments.map((e) => _ExperimentCard(experiment: e, onResult: _recordResult)),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String label, String hint) => TextField(
    controller: ctrl, maxLines: 2, maxLength: 300,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintText: hint, hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true, fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}

class _ExperimentCard extends StatelessWidget {
  final Map<String, dynamic> experiment;
  final Future<void> Function(String id, String day, String result) onResult;
  const _ExperimentCard({required this.experiment, required this.onResult});

  @override
  Widget build(BuildContext context) {
    final results = Map<String, dynamic>.from(experiment['results'] ?? {});
    final dt = DateTime.tryParse(experiment['created_at'] ?? '') ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧪 ${experiment['thought'] ?? ''}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${S.t(context, 'experimentActionPrefix')} ${experiment['action'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            for (final day in ['day1', 'day2', 'day3'])
              Expanded(child: _DayChip(day: day, result: results[day], onTap: () async {
                final ctrl = TextEditingController(text: results[day]?.toString() ?? '');
                await showDialog(context: context, builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(S.t(context, 'experimentDayTitle').replaceAll('{n}', day.substring(3)), style: const TextStyle(color: AppColors.textPrimary)),
                  content: TextField(controller: ctrl, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: S.t(context, 'experimentObserveHint'), hintStyle: const TextStyle(color: AppColors.textSecondary))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t(context, 'cancel'))),
                    TextButton(onPressed: () { Navigator.pop(context); onResult(experiment['id'], day, ctrl.text.trim()); }, child: Text(S.t(context, 'save'), style: const TextStyle(color: AppColors.primary))),
                  ],
                ));
              })),
          ]),
          const SizedBox(height: 4),
          Text('${dt.day}.${dt.month}.${dt.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String day; final dynamic result; final VoidCallback onTap;
  const _DayChip({required this.day, required this.result, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: result != null ? AppColors.primary.withValues(alpha: 0.2) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: result != null ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3)),
      ),
      child: Center(child: Text(S.t(context, 'experimentDayTitle').replaceAll('{n}', day.substring(3)), style: TextStyle(color: result != null ? AppColors.primary : AppColors.textSecondary, fontSize: 12))),
    ),
  );
}
