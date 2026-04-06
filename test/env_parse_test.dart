import 'package:flutter_test/flutter_test.dart';
import 'package:sobersteps/env_loader.dart';

void main() {
  test('parseEnvContent skips comments and blank lines', () {
    expect(parseEnvContent('# x\n\nA=b\n'), {'A': 'b'});
  });

  test('parseEnvContent strips matching quotes', () {
    expect(parseEnvContent('K="hi"'), {'K': 'hi'});
    expect(parseEnvContent("K='hi'"), {'K': 'hi'});
  });
}
