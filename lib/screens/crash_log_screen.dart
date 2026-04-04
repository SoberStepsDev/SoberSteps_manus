import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../services/encryption_service.dart';
import 'paywall_screen.dart';

/// CrashLog — a deep or gentle journal for difficult moments.
/// Philosophy: Uśmiech (curiosity), Perspektywa (no finish line), Droga (80% is enough).
/// AI (Claude via crash-log-feedback Edge Function) responds to each entry.
/// All entries are AES-encrypted and stored in marginal_archive_entries.
class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key});

  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

enum _CrashLogMode { gentle, deep }

class _CrashLogScreenState extends State<CrashLogScreen> {
  final _controller = TextEditingController();
  final _enc = EncryptionService();
  final _supabase = Supabase.instance.client;

  _CrashLogMode _mode = _CrashLogMode.gentle;
  bool _isSaving = false;
  String? _fallbackGentle;
  String? _fallbackDeep;
  String? _errorSaving;
  String? _crashLogWriteFirst;
  bool _isLoadingHistory = false;
  String? _aiFeedback;
  List<_ArchiveEntry> _history = [];
  bool _showArchive = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('crash_log_opened');
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final data = await _supabase
          .from('marginal_archive_entries')
          .select('id, body_encrypted, ai_reply, mode, in_loop, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(30);
      final entries = <_ArchiveEntry>[];
      for (final row in (data as List)) {
        final decrypted = await _enc.decrypt(row['body_encrypted'] as String);
        entries.add(_ArchiveEntry(
          id: row['id'] as String,
          body: decrypted,
          aiReply: row['ai_reply'] as String? ?? '',
          mode: row['mode'] as String? ?? 'gentle',
          inLoop: row['in_loop'] as bool? ?? false,
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
      if (mounted) setState(() => _history = entries);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _submit() async {
    // Capture context-dependent strings before async gap
    _fallbackGentle = S.t(context, 'crashLogFallbackGentle');
    _fallbackDeep = S.t(context, 'crashLogFallbackDeep');
    _errorSaving = S.t(context, 'errorSaving');
    _crashLogWriteFirst = S.t(context, 'crashLogWriteFirst');
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_crashLogWriteFirst ?? S.t(context, 'crashLogWriteFirst'))),
      );
      return;
    }
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _aiFeedback = null;
    });
    HapticFeedback.lightImpact();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isSaving = false);
        return;
      }

      // Get AI feedback from Edge Function
      String aiReply = '';
      try {
        final session = _supabase.auth.currentSession;
        final token = session?.accessToken ?? '';
        final response = await _supabase.functions.invoke(
          'crash-log-feedback',
          body: {
            'entry': text,
            'mode': _mode == _CrashLogMode.deep ? 'deep' : 'gentle',
          },
          headers: {'Authorization': 'Bearer $token'},
        );
        final data = response.data as Map<String, dynamic>?;
        aiReply = data?['feedback'] as String? ?? '';
      } catch (e) {
        // Fallback: offline-friendly local response
        // Capture locale-dependent strings before async gap
        aiReply = _mode == _CrashLogMode.gentle
            ? (_fallbackGentle ?? 'You wrote it down. That takes courage.')
            : (_fallbackDeep ?? 'Something in what you wrote matters.');
      }

      // Encrypt and save
      final encrypted = await _enc.encrypt(text);
      await _supabase.from('marginal_archive_entries').insert({
        'user_id': user.id,
        'body_encrypted': encrypted,
        'ai_reply': aiReply,
        'mode': _mode == _CrashLogMode.deep ? 'deep' : 'gentle',
        'in_loop': false,
      });

      AnalyticsService().track('crash_log_saved', {
        'mode': _mode == _CrashLogMode.deep ? 'deep' : 'gentle',
        'has_ai_reply': aiReply.isNotEmpty,
      });

      if (mounted) {
        setState(() {
          _aiFeedback = aiReply;
          _isSaving = false;
        });
        _controller.clear();
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorSaving ?? S.t(context, 'errorSaving'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PurchaseProvider>().isPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          S.t(context, 'crashLogTitle'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showArchive ? Icons.edit_rounded : Icons.history_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: _showArchive
                ? S.t(context, 'crashLogWrite')
                : S.t(context, 'marginalArchiveTitle'),
            onPressed: () => setState(() => _showArchive = !_showArchive),
          ),
        ],
      ),
      body: _showArchive
          ? _buildArchive()
          : _buildWriteView(isPro),
    );
  }

  Widget _buildWriteView(bool isPro) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _ModeTab(
                    label: S.t(context, 'crashLogGentle'),
                    icon: Icons.spa_rounded,
                    selected: _mode == _CrashLogMode.gentle,
                    onTap: () => setState(() => _mode = _CrashLogMode.gentle),
                  )),
                  Expanded(child: _ModeTab(
                    label: S.t(context, 'crashLogDeep'),
                    icon: Icons.psychology_rounded,
                    selected: _mode == _CrashLogMode.deep,
                    onTap: () {
                      if (!isPro) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PaywallScreen(trigger: 'crash_log_deep'),
                        ));
                        return;
                      }
                      setState(() => _mode = _CrashLogMode.deep);
                    },
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mode == _CrashLogMode.gentle
                  ? S.t(context, 'crashLogGentleHint')
                  : S.t(context, 'crashLogDeepHint'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Text input
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                maxLength: 2000,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: S.t(context, 'crashLogPlaceholder'),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSaving
                    ? S.t(context, 'crashLogSending')
                    : S.t(context, 'crashLogSend')),
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // AI feedback
            if (_aiFeedback != null && _aiFeedback!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _AiFeedbackCard(feedback: _aiFeedback!),
            ],

            const SizedBox(height: 16),
            // Philosophy note
            Text(
              S.t(context, 'crashLogPhilosophy'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildArchive() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              S.t(context, 'marginalArchiveEmpty'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _history[index];
        return _ArchiveCard(entry: entry);
      },
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFeedbackCard extends StatelessWidget {
  final String feedback;
  const _AiFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Naomi',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ArchiveEntry {
  final String id;
  final String body;
  final String aiReply;
  final String mode;
  final bool inLoop;
  final DateTime createdAt;

  const _ArchiveEntry({
    required this.id,
    required this.body,
    required this.aiReply,
    required this.mode,
    required this.inLoop,
    required this.createdAt,
  });
}

class _ArchiveCard extends StatelessWidget {
  final _ArchiveEntry entry;
  const _ArchiveCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${entry.createdAt.day.toString().padLeft(2, '0')}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.mode == 'deep'
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.mode == 'deep' ? Icons.psychology_rounded : Icons.spa_rounded,
                size: 14,
                color: entry.mode == 'deep' ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                entry.mode == 'deep'
                    ? S.t(context, 'crashLogDeep')
                    : S.t(context, 'crashLogGentle'),
                style: TextStyle(
                  color: entry.mode == 'deep' ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.body,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.aiReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.aiReply,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
