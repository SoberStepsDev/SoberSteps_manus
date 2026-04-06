import 'package:flutter_test/flutter_test.dart';
import 'package:sobersteps/l10n/strings.dart';

void main() {
  test('every locale defines l10nParityKeys (brand + About)', () {
    for (final loc in S.debugLocaleCodes) {
      for (final key in S.l10nParityKeys) {
        final v = S.debugLookup(loc, key);
        expect(v, isNotNull, reason: 'locale=$loc missing key=$key');
        expect(v!.trim(), isNotEmpty, reason: 'locale=$loc empty key=$key');
      }
    }
  });
}
