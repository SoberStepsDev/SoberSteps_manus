import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../app/theme.dart';
import '../services/analytics_service.dart';

/// Inner Critic Log — records critical thoughts and reframes them as curiosity.
/// Table: inner_critic_log (id, user_id, content, created_at)
class KrytykLogScreen extends StatefulWidget {
  const KrytykLogScreen({super.key});
  @override
  State<KrytykLogScreen> createState() => _KrytykLogScreenState();
}

class _KrytykLogScreenState extends State<KrytykLogScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService().track(AnalyticsService.eSelfCompassionOpened, {'card': 'inner_critic'});
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('inner_critic_log')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      setState(() { _entries = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    final entry = {'id': const Uuid().v4(), 'user_id': user.id, 'content': text, 'created_at': DateTime.now().toIso8601String()};
    try {
      await Supabase.instance.client.from('inner_critic_log').insert(entry);
      _controller.clear();
      setState(() { _entries.insert(0, entry); });
      AnalyticsService().track(AnalyticsService.eInnerCriticLogged);
      if (mounted) _showReframe(text);
    } catch (_) {}
    setState(() => _saving = false);
  }

  void _showReframe(String thought) {
    final reframes = [
      'Co ciekawego możesz odkryć w tej myśli?',
      'Jak zareagowałbyś na przyjaciela z tą samą myślą?',
      'Co ta myśl próbuje Cię chronić?',
      'Czy ta myśl jest faktem, czy interpretacją?',
      'Jaka jest najbardziej życzliwa odpowiedź na tę myśl?',
    ];
    final reframe = reframes[DateTime.now().second % reframes.length];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🪞 Zamień krytykę w ciekawość', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(reframe, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dziękuję', style: TextStyle(color: AppColors.primary)))],
      ),
    );
  }

  Future<void> _delete(String id) async {
    setState(() => _entries.removeWhere((e) => e['id'] == id));
    try { await Supabase.instance.client.from('inner_critic_log').delete().eq('id', id); } catch (_) {}
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Wewnętrzny Krytyk', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zapisz myśl krytyczną', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  maxLength: 500,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Np. "Znowu zawiodłem…"',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Zapisz i zamień w ciekawość', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surface),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('Brak wpisów.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final e = _entries[i];
                          final dt = DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now();
                          return Dismissible(
                            key: Key(e['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(color: Colors.red.withOpacity(0.2), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete_outline, color: Colors.red)),
                            onDismissed: (_) => _delete(e['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['content'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${dt.day}.${dt.month}.${dt.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
