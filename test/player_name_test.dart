import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/models/player_name.dart';

void main() {
  test('normalise les espaces', () {
    expect(normalizePlayerName('  Marie   Lou  '), 'Marie Lou');
  });

  test('accepte les noms prevus', () {
    for (final name in [
      'Paul',
      'Marie-Lou',
      "O'Connor",
      'Léa 75',
      'Jean’Luc',
    ]) {
      expect(validatePlayerName(name), isNull, reason: name);
    }
  });

  test('refuse les noms hors prescription', () {
    expect(validatePlayerName('Al'), PlayerNameError.length);
    expect(validatePlayerName('123'), PlayerNameError.missingLetter);
    expect(validatePlayerName('Paul!'), PlayerNameError.invalidCharacter);
    expect(validatePlayerName('abcdefghijklmnopqrstu'), PlayerNameError.length);
  });
}
