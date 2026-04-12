import 'package:flutter_test/flutter_test.dart';
import 'package:kumpan_key/l10n/app_strings.dart';

void main() {
  test('English strings are populated', () {
    final strings = AppStrings.of('en');
    expect(strings.appTitle, 'Kumpan Key');
    expect(strings.keyActive, 'Key Active');
    expect(strings.step1, isNotEmpty);
  });

  test('German strings are populated', () {
    final strings = AppStrings.of('de');
    expect(strings.appTitle, 'Kumpan Key');
    expect(strings.keyActive, 'Schlüssel aktiv');
    expect(strings.step1, isNotEmpty);
  });

  test('Unknown locale falls back to English', () {
    final strings = AppStrings.of('fr');
    expect(strings.keyActive, 'Key Active');
  });
}
