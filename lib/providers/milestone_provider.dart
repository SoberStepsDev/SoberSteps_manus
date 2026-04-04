import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/milestone.dart';
import '../services/analytics_service.dart';

class MilestoneProvider extends ChangeNotifier {
  final AnalyticsService _analytics = AnalyticsService();
  List<MilestoneAchieved> _achieved = [];
  bool _loading = false;
  /// Set by deep links; consumed by [MilestonesScreen] inside [HomeScreen] tab bar.
  int? deepLinkMilestoneFocusDays;

  List<MilestoneAchieved> get achieved => _achieved;
  bool get loading => _loading;

  void setDeepLinkMilestoneFocus(int days) {
    deepLinkMilestoneFocusDays = days;
    notifyListeners();
  }

  void clearDeepLinkMilestoneFocus() {
    if (deepLinkMilestoneFocusDays == null) return;
    deepLinkMilestoneFocusDays = null;
    notifyListeners();
  }

  bool isAchieved(int days) => _achieved.any((m) => m.days == days);

  Future<void> loadMilestones() async {
    _loading = true;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final data = await client
          .from('milestones_achieved')
          .select()
          .eq('user_id', user.id)
          .order('days');
      _achieved = (data as List).map((e) => MilestoneAchieved.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> recordMilestone(int days) async {
    if (isAchieved(days)) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client.from('milestones_achieved').insert({
        'user_id': user.id,
        'days': days,
      });
      _analytics.track('milestone_celebrate', {'days': days});
      await loadMilestones();
    } catch (_) {}
  }
}
