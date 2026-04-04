import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountabilityProvider extends ChangeNotifier {
  List<FamilyObserver> _observers = [];
  bool _loading = false;

  List<FamilyObserver> get observers => _observers;
  bool get loading => _loading;

  Future<void> loadObservers() async {
    _loading = true;
    notifyListeners();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _loading = false;
        notifyListeners();
        return;
      }
      final data = await Supabase.instance.client
          .from('family_observers')
          .select()
          .eq('subscriber_user_id', user.id)
          .order('invited_at', ascending: false);
      _observers = (data as List).map((e) => FamilyObserver.fromJson(e)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<String?> invitePartner(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Enter email';
    if (!trimmed.contains('@')) return 'Invalid email';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'Login required';
      await Supabase.instance.client.from('family_observers').insert({
        'subscriber_user_id': user.id,
        'observer_email': trimmed,
        'status': 'pending',
      });
      await loadObservers();
      return null;
    } catch (e) {
      if (e.toString().contains('duplicate') || e.toString().contains('23505')) return 'Ta osoba już zaproszona';
      return 'Nie udało się wysłać zaproszenia';
    }
  }
}

class FamilyObserver {
  final String id;
  final String observerEmail;
  final String status;
  final DateTime invitedAt;
  final DateTime? acceptedAt;

  FamilyObserver({required this.id, required this.observerEmail, required this.status, required this.invitedAt, this.acceptedAt});

  factory FamilyObserver.fromJson(Map<String, dynamic> j) => FamilyObserver(
        id: j['id'],
        observerEmail: j['observer_email'] ?? '',
        status: j['status'] ?? 'pending',
        invitedAt: DateTime.parse(j['invited_at']),
        acceptedAt: j['accepted_at'] != null ? DateTime.parse(j['accepted_at']) : null,
      );

  bool get isAccepted => status == 'accepted';
}
