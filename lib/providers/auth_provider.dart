import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final AnalyticsService _analytics = AnalyticsService();
  StreamSubscription<AuthState>? _sub;

  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get userId => _user?.id;

  AuthProvider() {
    _user = _authService.currentUser;
    _loading = false;
    _sub = _authService.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      if (_user != null) {
        _authService.ensureProfile();
        _analytics.setUserId(_user!.id);
      }
      notifyListeners();
    });
  }

  Future<void> signInWithOtp(String email) async {
    await _authService.signInWithOtp(email);
    _analytics.track('magic_link_sent');
  }

  Future<void> signUpWithPassword(
    String email,
    String password, {
    String? displayName,
    int? birthYear,
    String? gender,
  }) async {
    await _authService.signUpWithPassword(
      email,
      password,
      displayName: displayName,
      birthYear: birthYear,
      gender: gender,
    );
    _analytics.track('email_password_signup');
  }

  Future<void> signInWithPassword(String email, String password) async {
    await _authService.signInWithPassword(email, password);
    _analytics.track('email_password_signin');
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    _analytics.track('google_sign_in');
  }

  Future<void> signInWithApple() async {
    await _authService.signInWithApple();
    _analytics.track('apple_sign_in');
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPasswordForEmail(email);
    _analytics.track('password_reset_requested');
  }

  Future<void> signOut() async {
    _analytics.track(AnalyticsService.eSignOut);
    _analytics.clearUser();
    NotificationService().logout();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> insertEmailLead(String email) async {
    await _authService.insertEmailLead(email);
    _analytics.track('email_gate_submitted');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
