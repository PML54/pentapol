// Modified: 2026-09-04 16:25 — création : test de generatePlayerId (identité 128 bits, CDC §7.4).
// test/player_id_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  group('generatePlayerId — identité 128 bits (§7.4)', () {
    test('32 caractères hexadécimaux (128 bits)', () {
      final id = generatePlayerId();
      expect(id.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(id), isTrue);
    });

    test('deux générations diffèrent (aléatoire)', () {
      final ids = {for (var i = 0; i < 50; i++) generatePlayerId()};
      expect(ids.length, 50); // aucune collision sur 50 tirages 128 bits
    });
  });
}
