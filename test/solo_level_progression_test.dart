// Modified: 2026-09-29 05:14 — vérifier que seule une réussite Solo sans lampe jaune débloque le
//           niveau suivant.
// test/solo_level_progression_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

PentoscopeState _completedLevel({
  required int level,
  required int hintCount,
  bool isProgression = true,
}) {
  return PentoscopeState.initial().copyWith(
    puzzle: PentoscopePuzzle(
      size: sizeForLevel(level),
      pieceIds: const [],
      solutionCount: 1,
    ),
    isComplete: true,
    isProgression: isProgression,
    hintCount: hintCount,
  );
}

void main() {
  test('une réussite Solo sans lampe jaune débloque le niveau suivant', () {
    expect(
      canAdvanceSoloLevel(_completedLevel(level: 3, hintCount: 0), 3),
      isTrue,
    );
  });

  test('une réussite avec lampe jaune ne débloque pas le niveau suivant', () {
    final assisted = _completedLevel(level: 3, hintCount: 1);
    expect(canAdvanceSoloLevel(assisted, 3), isFalse);
    expect(canOfferNextSoloLevel(assisted), isFalse);
  });

  test('un puzzle libre et le niveau maximal ne débloquent rien', () {
    expect(
      canAdvanceSoloLevel(
        _completedLevel(level: 3, hintCount: 0, isProgression: false),
        3,
      ),
      isFalse,
    );
    expect(
      canAdvanceSoloLevel(
        _completedLevel(level: kMaxLevel, hintCount: 0),
        kMaxLevel,
      ),
      isFalse,
    );
    expect(
      canOfferNextSoloLevel(_completedLevel(level: kMaxLevel, hintCount: 0)),
      isFalse,
    );
  });
}
