// Modified: 2026-11-17 09:07 — distinguer niveaux Solo et six ceintures de passage.
// test/player_level_labels_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/config/player_level_labels.dart';
import 'package:pentapol/config/challenge_belts.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';

void main() {
  for (final language in ['fr', 'en']) {
    test('six ceintures de passage et neuf niveaux Solo, $language', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      expect(kChallengeSizes.length, 6);
      expect(PentoscopeSize.values.length, 9);
      for (var i = 0; i < 6; i++) {
        expect(
          playerSizeLabel(l10n, kChallengeSizes[i]),
          beltLabel(l10n, i + 1),
        );
      }
      expect(playerLevelLabel(l10n, 1), l10n.homeSoloProgress(1, 3, 5));
      expect(playerLevelLabel(l10n, 99), l10n.homeSoloProgress(9, 6, 10));
    });
  }
}
