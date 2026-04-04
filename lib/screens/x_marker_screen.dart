import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../app/theme.dart';
import '../services/analytics_service.dart';

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
    _load();
    AnalyticsService().track(AnalyticsService.eSelfCompassionOpened, {'card': 'x_marker'});
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
    final entry = {'id': const Uuid().v4(), 'user_id': user.id, 'note': note.isEmpty ? 'Akt troski o siebie ✕' : note, 'created_at': DateTime.now().toIso8601String()};
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
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('✕', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Zaznaczono.', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Jeden akt troski o siebie. Tyle wystarczy.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dziękuję', style: TextStyle(color: AppColors.primary)))],
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
        title: const Text('X-Marker', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Jeden akt troski o siebie na dziś', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Może to być cokolwiek — szklanka wody, 5 minut ciszy, spacer.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                if (!_todayDone) ...[
                  TextField(
                    controller: _ctrl, maxLength: 200,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Co zrobisz dla siebie dziś? (opcjonalnie)',
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
                      child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('✕  Zaznacz na dziś', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ] else
                  const Row(children: [
                    Icon(Icons.check_circle, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Zaznaczono na dziś ✕', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Historia aktów troski', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _acts.isEmpty
                      ? const Center(child: Text('Brak wpisów.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          itemCount: _acts.length,
                          itemBuilder: (_, i) {
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
                                Text('${dt.day}.${dt.month}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
