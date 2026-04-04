import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const _key = 'app_locale';
  static const _supported = ['en', 'pl', 'es', 'fr', 'ru', 'nl'];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    _locale = Locale(_supported.contains(code) ? code : 'en');
    notifyListeners();
  }

  Future<void> setLocale(Locale l) async {
    if (!_supported.contains(l.languageCode)) return;
    _locale = l;
    await SharedPreferences.getInstance().then((p) => p.setString(_key, l.languageCode));
    notifyListeners();
  }
}
