import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../l10n/strings.dart';
import '../providers/sobriety_provider.dart';

class SavingsHealthScreen extends StatefulWidget {
  const SavingsHealthScreen({super.key});

  @override
  State<SavingsHealthScreen> createState() => _SavingsHealthScreenState();
}

class _SavingsHealthScreenState extends State<SavingsHealthScreen> {
  double _dailyCost = 15.0;

  @override
  void initState() {
    super.initState();
    _loadCost();
  }

  Future<void> _loadCost() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _dailyCost = prefs.getDouble('daily_substance_cost') ?? 15.0);
  }

  Future<void> _setCost(double cost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_substance_cost', cost);
    setState(() => _dailyCost = cost);
  }

  @override
  Widget build(BuildContext context) {
    final days = context.watch<SobrietyProvider>().daysSober;
    final saved = days * _dailyCost;
    final hours = days * 24;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(S.t(context, 'savingsHealth'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Money saved
            _BigCard(
              icon: Icons.savings_rounded,
              color: AppColors.gold,
              title: '\$${saved.toStringAsFixed(0)}',
              subtitle: S.t(context, 'saved'),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            _CostEditor(dailyCost: _dailyCost, onChanged: _setCost),
            const SizedBox(height: 24),

            // Health benefits
            Align(
              alignment: Alignment.centerLeft,
              child: Text(S.t(context, 'bodyHealing'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 16),
            ..._healthTimeline.map((h) {
              final achieved = hours >= h.hoursNeeded;
              return _HealthCard(data: h, achieved: achieved);
            }),
            const SizedBox(height: 24),

            // Stats grid
            Align(
              alignment: Alignment.centerLeft,
              child: Text(S.t(context, 'inNumbers'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(value: '${(days * 7).toStringAsFixed(0)}h', label: S.t(context, 'sleepNoHangover'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(value: '${(days * 0.5).toStringAsFixed(1)} L', label: S.t(context, 'waterNotAlcohol'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(value: (days * 200).toStringAsFixed(0), label: S.t(context, 'caloriesLess'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(value: days.toString(), label: S.t(context, 'goodDecisions'))),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _BigCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CostEditor extends StatelessWidget {
  final double dailyCost;
  final ValueChanged<double> onChanged;

  const _CostEditor({required this.dailyCost, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(S.t(context, 'dailyCost'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Text('\$', style: TextStyle(color: AppColors.textPrimary)),
          Expanded(child: Slider(value: dailyCost, min: 1, max: 100, activeColor: AppColors.gold, onChanged: onChanged)),
          Text('\$${dailyCost.toStringAsFixed(0)}${S.t(context, 'perDay')}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final _HealthItem data;
  final bool achieved;

  const _HealthCard({required this.data, required this.achieved});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: achieved ? AppColors.success.withValues(alpha: 0.5) : AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: achieved ? AppColors.success.withValues(alpha: 0.2) : AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(achieved ? Icons.check : Icons.lock, size: 20, color: achieved ? AppColors.success : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: TextStyle(color: achieved ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(data.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(data.timeLabel, style: TextStyle(color: achieved ? AppColors.success : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.gold)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _HealthItem {
  final int hoursNeeded;
  final String timeLabel;
  final String label;
  final String description;
  const _HealthItem(this.hoursNeeded, this.timeLabel, this.label, this.description);
}

const _healthTimeline = [
  _HealthItem(1, '1h', 'Tętno spada', 'Ciśnienie krwi zaczyna się normalizować.'),
  _HealthItem(8, '8h', 'Tlen w normie', 'Poziom tlenu we krwi wraca do normy.'),
  _HealthItem(24, '24h', 'Ryzyko zawału spada', 'Zmniejsza się ryzyko zawału serca.'),
  _HealthItem(48, '48h', 'Nerwy się regenerują', 'Zakończenia nerwowe zaczynają odrastać. Smak i węch wracają.'),
  _HealthItem(72, '72h', 'Oddychanie łatwiejsze', 'Oskrzela się rozluźniają. Pojemność płuc rośnie.'),
  _HealthItem(336, '2 tyg', 'Krążenie lepsze', 'Znaczna poprawa krążenia krwi i funkcji płuc.'),
  _HealthItem(720, '30 dni', 'Wątroba dziękuje', 'Enzymy wątrobowe wracają do normy. Energia rośnie.'),
  _HealthItem(2160, '90 dni', 'Mózg się przebudowuje', 'Neuroplastyczność mózgu — nowe ścieżki neuronowe. Lepszy sen, pamięć, koncentracja.'),
  _HealthItem(4320, '180 dni', 'Odporność wzrasta', 'Układ odpornościowy w pełni odbudowany.'),
  _HealthItem(8760, '1 rok', 'Nowe życie', 'Ryzyko chorób serca spadło o 50%. Skóra, waga, zdrowie psychiczne — wszystko lepiej.'),
];
