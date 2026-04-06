import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../constants/app_constants.dart';
import '../core/philosophy_core.dart';
import '../l10n/strings.dart';
import '../models/return_to_self.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/return_to_self_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/rts_daily_mirror_widget.dart';
import '../widgets/rts_progress_graph_widget.dart';
import 'rts_reassessment_screen.dart';

/// Philosophy applied: 30-day path as curiosity journey, not challenge
class ReturnToSelfScreen extends StatefulWidget {
  const ReturnToSelfScreen({super.key});

  @override
  State<ReturnToSelfScreen> createState() => _ReturnToSelfScreenState();
}

class _ReturnToSelfScreenState extends State<ReturnToSelfScreen> {
  static const _trackIds = ['self_hatred', 'perfectionism', 'toxic_relationships'];

  String _trackId = 'self_hatred';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPreferredTrack();
      _loadReturnToSelfProgress();
    });
    AnalyticsService().track('return_to_self_opened');
  }

  Future<void> _loadPreferredTrack() async {
    final prefs = await SharedPreferences.getInstance();
    final cat = prefs.getString('addiction_category');
    final st = prefs.getString('substance_type');
    if (!mounted) return;
    if (cat == 'return_to_self' && st != null && _trackIds.contains(st)) {
      setState(() => _trackId = st);
    }
  }

  void _loadReturnToSelfProgress() {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isLoggedIn) return;
    context.read<ReturnToSelfProvider>().loadProgress();
  }

  bool _isProOnlyTrack(String id) => AppConstants.returnToSelfProOnly.contains(id);

  String _trackTitleKey(String id) => switch (id) {
        'self_hatred' => 'rtsSelfHatred',
        'perfectionism' => 'rtsPerfectionism',
        'toxic_relationships' => 'rtsToxicRel',
        _ => 'rtsSelfHatred',
      };

  void _setTrack(String id) {
    if (_trackId == id) return;
    setState(() => _trackId = id);
    AnalyticsService().track('return_to_self_track_selected', {'track': id});
  }

  static const _phases = [
    {
      'type': ReturnToSelfType.awareness,
      'labelKey': 'rtsPhaseAwareness',
      'days': '1–7',
      'icon': Icons.visibility_outlined,
      'descKey': 'rtsPhaseAwarenessDesc',
    },
    {
      'type': ReturnToSelfType.distance,
      'labelKey': 'rtsPhaseDistance',
      'days': '8–14',
      'icon': Icons.zoom_out_map,
      'descKey': 'rtsPhaseDistanceDesc',
    },
    {
      'type': ReturnToSelfType.repair,
      'labelKey': 'rtsPhaseRepair',
      'days': '15–21',
      'icon': Icons.healing_outlined,
      'descKey': 'rtsPhaseRepairDesc',
    },
    {
      'type': ReturnToSelfType.integration,
      'labelKey': 'rtsPhaseIntegration',
      'days': '22–30',
      'icon': Icons.merge_type,
      'descKey': 'rtsPhaseIntegrationDesc',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    if (!isLoggedIn) return _buildLoginGate(context);

    final provider = context.watch<ReturnToSelfProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t(context, 'returnToSelf')),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_alt_rounded, color: AppColors.textSecondary),
            tooltip: S.t(context, 'rtsDiagnosticRetake'),
            onPressed: () => Navigator.pushNamed(context, '/rts-diagnostic'),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.loading
            ? Center(
                child: Text(
                  PhilosophyCore.loadingMessages[0],
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildTrackPicker(context),
                  const SizedBox(height: 20),
                  if (_trackId != 'self_hatred') ...[
                    _buildProTrackPlaceholder(context),
                    const SizedBox(height: 16),
                  ] else ...[
                  _buildIntro(),
                  const SizedBox(height: 24),
                  if (provider.streak != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: AppColors.gold, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              PhilosophyCore.streakMessage(provider.streak!.streakDays),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 24),
                  ],
                  ...List.generate(_phases.length, (i) {
                    final phase = _phases[i];
                    final type = phase['type'] as ReturnToSelfType;
                    final completed = provider.progress
                        .where((p) => p.type == type && p.completed)
                        .length;
                    final total = type == ReturnToSelfType.integration ? 9 : 7;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: completed == total
                              ? Border.all(color: AppColors.gold.withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(phase['icon'] as IconData, color: AppColors.primary, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  S.t(context, phase['labelKey'] as String),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${S.t(context, 'rtsDays')} ${phase['days']}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? completed / total : 0,
                                backgroundColor: AppColors.background,
                                valueColor: AlwaysStoppedAnimation(
                                  completed == total ? AppColors.gold : AppColors.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completed / $total',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            if (phase['descKey'] != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                S.t(context, phase['descKey'] as String),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(
                            duration: 500.ms,
                            delay: Duration(milliseconds: i * 100),
                          ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    S.t(context, 'rtsTools'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _ToolCard(
                    icon: Icons.auto_awesome,
                    label: S.t(context, 'karmaMirror'),
                    desc: S.t(context, 'karmaMirrorDesc'),
                    onTap: () => Navigator.pushNamed(context, '/karma-mirror'),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.psychology_outlined,
                    label: S.t(context, 'naomi'),
                    desc: S.t(context, 'naomiDesc'),
                    onTap: () => Navigator.pushNamed(context, '/naomi'),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.format_quote_rounded,
                    label: S.t(context, 'wallOfStrength'),
                    desc: S.t(context, 'wallOfStrengthDesc'),
                    onTap: () => Navigator.pushNamed(context, '/wall-of-strength'),
                  ),
                  const SizedBox(height: 24),
                  const RTSDailyMirrorWidget(),
                  const SizedBox(height: 16),
                  const RTSProgressGraphWidget(),
                  const SizedBox(height: 16),
                  _ToolCard(
                    icon: Icons.refresh_rounded,
                    label: 'Ponowna Ocena RTS',
                    desc: 'Sprawdź swój postęp po 30 dniach.',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RTSReassessmentScreen())),
                  ),
                  ],
                ],     ),
      ),
    );
  }

  Widget _buildTrackPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t(context, 'rtsPathSectionTitle'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._trackIds.map((id) {
          final selected = _trackId == id;
          final free = id == 'self_hatred';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _setTrack(id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.surfaceLight,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.t(context, _trackTitleKey(id)),
                          style: TextStyle(
                            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: free
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          free ? S.t(context, 'rtsBadgeFree') : S.recoveryPlus(context),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: free ? AppColors.primary : AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProTrackPlaceholder(BuildContext context) {
    final isPro = context.watch<PurchaseProvider>().isPro;
    final showRecoveryTeaser = _isProOnlyTrack(_trackId) && !isPro;
    final text = showRecoveryTeaser
        ? S.t(context, 'rtsProTrackPlaceholder')
        : S.t(context, 'rtsComingSoonTrack');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 40),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms);
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.self_improvement, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                S.t(context, 'rtsWhatIs'),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            S.t(context, 'rtsIntro'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            S.t(context, 'rtsDailyTask'),
            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  /// Philosophy applied: zaproszenie do zalogowania zamiast imperatywu
  Widget _buildLoginGate(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'returnToSelf')), backgroundColor: AppColors.background),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(S.t(context, 'loginToUse'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/auth'),
                  child: Text(S.t(context, 'login')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final VoidCallback onTap;

  const _ToolCard({required this.icon, required this.label, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
