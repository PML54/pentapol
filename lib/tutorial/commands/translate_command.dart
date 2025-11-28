// lib/tutorial/commands/translate_command.dart
// Commande de translation (déplacement) de pièces

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// TRANSLATE - Translate une pièce vers une nouvelle position
///
/// Déplace une pièce placée vers une nouvelle position en utilisant sa mastercase.
/// La position de départ est détectée automatiquement.
///
/// Paramètres :
/// - pieceNumber: numéro de la pièce à déplacer
/// - toX, toY: position finale de la mastercase
/// - duration: durée de l'animation en ms (défaut: 500)
///
/// Syntaxe YAML :
/// ```yaml
/// - command: TRANSLATE
///   params:
///     pieceNumber: 6
///     toX: 5
///     toY: 7
///     duration: 1000
/// ```
class TranslateCommand extends ScratchCommand {
  final int pieceNumber;
  final int toX;
  final int toY;
  final int durationMs;

  const TranslateCommand({
    required this.pieceNumber,
    required this.toX,
    required this.toY,
    this.durationMs = 500,
  });

  @override
  Future<void> execute(TutorialContext context) async {
    // Trouver la pièce sur le plateau
    final gameState = context.gameNotifier.state;
    final targetPiece = gameState.placedPieces.firstWhere(
          (p) => p.piece.id == pieceNumber,
      orElse: () => throw StateError(
        'TRANSLATE: Pièce $pieceNumber non trouvée sur le plateau',
      ),
    );

    // Récupérer la position actuelle (ancre/gridX, gridY)
    final fromX = targetPiece.gridX;
    final fromY = targetPiece.gridY;
    final savedPositionIndex = targetPiece.positionIndex; // Sauvegarder l'orientation

    // Calculer le vecteur de translation
    final dx = toX - fromX;
    final dy = toY - fromY;

    print('[TUTORIAL] 📍 Translation pièce $pieceNumber:');
    print('[TUTORIAL]   Position actuelle (ancre): ($fromX, $fromY)');
    print('[TUTORIAL]   Position cible (ancre): ($toX, $toY)');
    print('[TUTORIAL]   Vecteur de translation: (Δx=$dx, Δy=$dy)');
    print('[TUTORIAL]   Orientation sauvegardée: $savedPositionIndex');

    // Supprimer la pièce du plateau
    context.gameNotifier.removePlacedPiece(targetPiece);

    // Attendre un peu
    await Future.delayed(Duration(milliseconds: durationMs ~/ 4));

    // Sélectionner la pièce depuis le slider
    context.gameNotifier.selectPieceFromSliderForTutorial(pieceNumber);

    // Restaurer l'orientation (cycler jusqu'à retrouver la bonne position)
    final currentPositionIndex = context.gameNotifier.state.selectedPositionIndex;
    if (currentPositionIndex != savedPositionIndex) {
      final numPositions = targetPiece.piece.numPositions;
      var cycles = (savedPositionIndex - currentPositionIndex) % numPositions;
      if (cycles < 0) cycles += numPositions;

      for (var i = 0; i < cycles; i++) {
        context.gameNotifier.cycleToNextOrientation();
      }
    }

    await Future.delayed(Duration(milliseconds: durationMs ~/ 4));

    // Placer à la nouvelle position
    context.gameNotifier.placeSelectedPieceForTutorial(toX, toY);

    print('[TUTORIAL]   ✅ Translation effectuée: ($fromX,$fromY) → ($toX,$toY)');

    // Attendre la fin de l'animation
    await Future.delayed(Duration(milliseconds: durationMs ~/ 2));
  }

  @override
  String get name => 'TRANSLATE';

  @override
  String get description =>
      'Translation de la pièce $pieceNumber vers ($toX,$toY)';

  factory TranslateCommand.fromMap(Map<String, dynamic> params) {
    // Conversion robuste des paramètres
    final pieceNum = params['pieceNumber'];
    final tX = params['toX'];
    final tY = params['toY'];
    final dur = params['duration'];

    // Validation
    if (pieceNum == null) {
      throw FormatException(
        'TRANSLATE: le paramètre "pieceNumber" est obligatoire',
      );
    }
    if (tX == null || tY == null) {
      throw FormatException(
        'TRANSLATE: les paramètres "toX" et "toY" sont obligatoires',
      );
    }

    return TranslateCommand(
      pieceNumber: pieceNum is int ? pieceNum : int.parse(pieceNum.toString()),
      toX: tX is int ? tX : int.parse(tX.toString()),
      toY: tY is int ? tY : int.parse(tY.toString()),
      durationMs: dur == null
          ? 500
          : (dur is int ? dur : int.parse(dur.toString())),
    );
  }
}