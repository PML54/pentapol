// lib/tutorial/commands/selection_commands.dart
// Commandes de sélection dans le slider

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// SELECT_PIECE_FROM_SLIDER
class SelectPieceFromSliderCommand extends ScratchCommand {
  final int pieceNumber;

  const SelectPieceFromSliderCommand({required this.pieceNumber});

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.selectPieceFromSliderForTutorial(pieceNumber);
  }

  @override
  String get name => 'SELECT_PIECE_FROM_SLIDER';

  @override
  String get description => 'Sélectionne la pièce $pieceNumber du slider';

  factory SelectPieceFromSliderCommand.fromMap(Map<String, dynamic> params) {
    return SelectPieceFromSliderCommand(
      pieceNumber: params['pieceNumber'] as int,
    );
  }
}

/// HIGHLIGHT_PIECE_IN_SLIDER
class HighlightPieceInSliderCommand extends ScratchCommand {
  final int pieceNumber;

  const HighlightPieceInSliderCommand({required this.pieceNumber});

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.highlightPieceInSlider(pieceNumber);
  }

  @override
  String get name => 'HIGHLIGHT_PIECE_IN_SLIDER';

  @override
  String get description => 'Surligne la pièce $pieceNumber dans le slider';

  factory HighlightPieceInSliderCommand.fromMap(Map<String, dynamic> params) {
    return HighlightPieceInSliderCommand(
      pieceNumber: params['pieceNumber'] as int,
    );
  }
}

/// CLEAR_SLIDER_HIGHLIGHT
class ClearSliderHighlightCommand extends ScratchCommand {
  const ClearSliderHighlightCommand();

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.clearSliderHighlight();
  }

  @override
  String get name => 'CLEAR_SLIDER_HIGHLIGHT';

  @override
  String get description => 'Efface le surlignage du slider';
}

/// SCROLL_SLIDER
class ScrollSliderCommand extends ScratchCommand {
  final int positions;

  const ScrollSliderCommand({required this.positions});

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.scrollSlider(positions);
  }

  @override
  String get name => 'SCROLL_SLIDER';

  @override
  String get description => 'Fait défiler le slider de $positions positions';

  factory ScrollSliderCommand.fromMap(Map<String, dynamic> params) {
    return ScrollSliderCommand(positions: params['positions'] as int);
  }
}

/// SCROLL_SLIDER_TO_PIECE
class ScrollSliderToPieceCommand extends ScratchCommand {
  final int pieceNumber;

  const ScrollSliderToPieceCommand({required this.pieceNumber});

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.scrollSliderToPiece(pieceNumber);
  }

  @override
  String get name => 'SCROLL_SLIDER_TO_PIECE';

  @override
  String get description =>
      'Fait défiler le slider jusqu\'à la pièce $pieceNumber';

  factory ScrollSliderToPieceCommand.fromMap(Map<String, dynamic> params) {
    return ScrollSliderToPieceCommand(
      pieceNumber: params['pieceNumber'] as int,
    );
  }
}

/// RESET_SLIDER_POSITION
class ResetSliderPositionCommand extends ScratchCommand {
  const ResetSliderPositionCommand();

  @override
  Future<void> execute(TutorialContext context) async {
    context.gameNotifier.resetSliderPosition();
  }

  @override
  String get name => 'RESET_SLIDER_POSITION';

  @override
  String get description => 'Remet le slider à sa position initiale';
}
