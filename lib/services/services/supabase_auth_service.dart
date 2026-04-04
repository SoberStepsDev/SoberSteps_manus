import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

String _oauthRedirectUrl() {
  if (kIsWeb) {
    final u = Uri.base;
    return u.replace(fragment: '').toString();
  }
  return AppConstants.authRedirectUrl;
}

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: AppConstants.authRedirectUrl,
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirectUrl(),
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirectUrl(),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> ensureProfile() async {
    try {
      final user = currentUser;
      if (user == null) return;
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing == null) {
        final meta = user.userMetadata ?? {};
        // Extract demographics from user metadata (set during signUp or from Google OAuth)
        final rawDisplayName = (meta['display_name'] as String?)?.trim();
        final rawFullName = (meta['full_name'] as String?)?.trim();
        final rawName = meta['name'] as String?;
        final displayName = (rawDisplayName?.isNotEmpty ?? false)
            ? rawDisplayName
            : (rawFullName?.isNotEmpty ?? false)
                ? rawFullName
                : rawName;
        final birthYear = meta['birth_year'] as int?;
        final gender = meta['gender'] as String?;

        final profileData = <String, dynamic>{'id': user.id};
        if (displayName != null) profileData['display_name'] = displayName;
        if (birthYear != null) profileData['birth_year'] = birthYear;
        if (gender != null) profileData['gender'] = gender;

        await _client.from('profiles').insert(profileData);
      }
    } catch (_) {}
  }

  Future<void> insertEmailLead(String email) async {
    try {
      await _client.from('email_leads').upsert({'email': email}, onConflict: 'email');
    } catch (_) {}
  }

  Future<void> signUpWithPassword(
    String email,
    String password, {
    String? displayName,
    int? birthYear,
    String? gender,
  }) async {
    final data = <String, dynamic>{
      'created_at': DateTime.now().toIso8601String(),
    };
    if (displayName != null && displayName.isNotEmpty) {
      data['display_name'] = displayName;
    }
    if (birthYear != null) data['birth_year'] = birthYear;
    if (gender != null) data['gender'] = gender;

    await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConstants.authRedirectUrl,
    );
  }
}
