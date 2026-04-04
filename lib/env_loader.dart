import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, String> _parseEnvToMap(String raw) {
  final out = <String, String>{};
  for (var line in raw.split('\n')) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final k = line.substring(0, eq).trim();
    var v = line.substring(eq + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    if (k.isNotEmpty) out[k] = v;
  }
  return out;
}

Future<void> loadAppEnv() async {
  String bundled = '';
  try {
    bundled = await rootBundle.loadString('assets/config.env.example');
  } catch (_) {}
  final merged = _parseEnvToMap(bundled);
  try {
    final localBundled = await rootBundle.loadString('assets/config.env');
    merged.addAll(_parseEnvToMap(localBundled));
  } catch (_) {}
  if (!kIsWeb) {
    for (final path in ['assets/config.env', '.env']) {
      try {
        final f = File(path);
        if (await f.exists()) merged.addAll(_parseEnvToMap(await f.readAsString()));
      } catch (_) {}
    }
  }
  // flutter_dotenv ^6: loadFromString zwraca void, nie Future — bez await
  dotenv.loadFromString(
    envString: merged.isEmpty ? '' : merged.entries.map((e) => '${e.key}=${e.value}').join('\n'),
    isOptional: true,
  );
  if (!dotenv.isInitialized) {
    dotenv.loadFromString(envString: '', isOptional: true);
  }
}
