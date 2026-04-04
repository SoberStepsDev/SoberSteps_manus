import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/theme.dart';
import '../providers/purchase_provider.dart';
import '../widgets/pro_gate_widget.dart';
import '../models/rts_diagnostic.dart';

/// RTSProgressGraphWidget — PRO only.
/// Shows score history from rts_scores table as a line chart.
class RTSProgressGraphWidget extends StatefulWidget {
  const RTSProgressGraphWidget({super.key});
  @override
  State<RTSProgressGraphWidget> createState() => _RTSProgressGraphWidgetState();
}

class _RTSProgressGraphWidgetState extends State<RTSProgressGraphWidget> {
  List<Map<String, dynamic>> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final data = await Supabase.instance.client
          .from('rts_scores')
          .select('score, assessed_at')
          .eq('user_id', uid)
          .order('assessed_at', ascending: true)
          .limit(10);
      setState(() { _scores = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PurchaseProvider>().isPro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('📈', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('Postęp RTS', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          ProGateWidget(
            isPro: isPro,
            trigger: 'rts_progress_graph',
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _scores.length < 2
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Ukończ co najmniej 2 oceny, aby zobaczyć postęp.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                      )
                    : _LineChart(scores: _scores),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  const _LineChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    final maxScore = RtsDiagnostic.maxScore.toDouble();
    final values = scores.map((s) => (s['score'] as num).toDouble()).toList();
    final dates = scores.map((s) {
      final dt = DateTime.tryParse(s['assessed_at'] ?? '');
      return dt != null ? '${dt.day}.${dt.month}' : '';
    }).toList();

    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _ChartPainter(values: values, maxValue: maxScore),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dates.map((d) => Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9))).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  const _ChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = AppColors.primary..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final chartH = size.height - 20;
    final step = size.width / (values.length - 1);

    Offset toOffset(int i) => Offset(i * step, chartH - (values[i] / maxValue * chartH));

    // Fill area
    final fillPath = Path()..moveTo(0, chartH);
    for (int i = 0; i < values.length; i++) fillPath.lineTo(toOffset(i).dx, toOffset(i).dy);
    fillPath.lineTo((values.length - 1) * step, chartH);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < values.length; i++) path.lineTo(toOffset(i).dx, toOffset(i).dy);
    canvas.drawPath(path, paint);

    // Dots
    for (int i = 0; i < values.length; i++) canvas.drawCircle(toOffset(i), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
