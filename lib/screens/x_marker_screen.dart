import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../l10n/strings.dart';
import '../formatting/locale_dates.dart';
import '../widgets/pro_gate_widget.dart';

/// X-Marker — daily self-care act checkbox.
/// Table: daily_self_acts (id, user_id, note, created_at)
class XMarkerScreen extends StatefulWidget {
  const XMarkerScreen({super.key});
  @override
  State<XMarkerScreen> createState() => _XMarkerScreenState();
}

class _XMarkerScreenState extends State<XMarkerScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _acts = [];
  bool _loading = true;
  bool _saving = false;
  bool _todayDone = false;

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
      AnalyticsService().track(AnalyticsService.eSelfCompassionOpened, {'card': 'x_marker'});
    });
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('daily_self_acts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(30);
      final acts = List<Map<String, dynamic>>.from(data);
      final today = DateTime.now();
      final todayDone = acts.any((a) {
        final dt = DateTime.tryParse(a['created_at'] ?? '');
        return dt != null && dt.year == today.year && dt.month == today.month && dt.day == today.day;
      });
      setState(() { _acts = acts; _todayDone = todayDone; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _mark() async {
    final note = _ctrl.text.trim();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final entry = {'id': const Uuid().v4(), 'user_id': user.id, 'note': note.isEmpty ? S.t(context, 'xMarkerDefaultNote') : note, 'created_at': DateTime.now().toIso8601String()};
    try {
      await Supabase.instance.client.from('daily_self_acts').insert(entry);
      _ctrl.clear();
      setState(() { _acts.insert(0, entry); _todayDone = true; });
      AnalyticsService().track(AnalyticsService.eXMarkerChecked);
      if (mounted) _showSuccess();
    } catch (_) {}
    setState(() => _saving = false);
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('✕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(S.t(ctx, 'xMarkerMarkedTitle'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(S.t(ctx, 'xMarkerSuccessBody'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(S.t(ctx, 'xMarkerThanks'), style: const TextStyle(color: AppColors.primary)))],
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(S.t(context, 'xMarkerTitle'), style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ProGateWidget(
        trigger: 'x_marker_gate',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(S.t(context, 'xMarkerHeading'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(S.t(context, 'xMarkerSub'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                if (!_todayDone) ...[
                  TextField(
                    controller: _ctrl, maxLength: 200,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: S.t(context, 'xMarkerHint'),
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _mark,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(S.t(context, 'xMarkerMarkToday'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ] else
                  Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(S.t(context, 'xMarkerMarkedToday'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
              ]),
            ),
            const SizedBox(height: 20),
            Text(S.t(context, 'xMarkerHistory'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _acts.isEmpty
                      ? Center(child: Text(S.t(context, 'xMarkerNoEntries'), style: const TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          itemCount: _acts.length,
                          itemBuilder: (context, i) {
                            final a = _acts[i];
                            final dt = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Text('✕', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(a['note'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                                Text(LocaleDates.mdShort(context, dt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ]),
                            );
                          },
                        ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
