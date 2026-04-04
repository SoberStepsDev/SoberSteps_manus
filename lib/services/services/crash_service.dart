import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashService {
  CrashService._();

  static bool get _ready {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('CrashService: $error');
      if (stack != null) print(stack);
    }
    if (!_ready) return;
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  static Future<void> recordFatalError(FlutterErrorDetails details) async {
    if (!_ready) return;
    await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  static Future<void> setUserIdentifier(String userId) async {
    if (!_ready) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  static Future<void> log(String message) async {
    if (!_ready) return;
    await FirebaseCrashlytics.instance.log(message);
  }
}
