// lib/tutorial/commands/transform_commands.dart
// Commandes de transformation de pièces

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// ROTATE_AROUND_MASTER
class RotateAroundMasterCommand extends ScratchCommand {
  final int pieceNumber;
  final int quarterTurns;
  final int durationMs;

  const RotateAroundMasterCommand({
    required this.pieceNumber,
    required this.quarterTurns,
    this.durationMs = 500,
  });

  @override
  Future<void> execute(TutorialContext context) async {
    // Utiliser la rotation isométrique CW (sens horaire)
    for (int i = 0; i < quarterTurns; i++) {
      context.gameNotifier.applyIsometryRotationCW();
    }
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  @override
  String get name => 'ROTATE_AROUND_MASTER';

  @override
  String get description =>
      'Fait pivoter la pièce $pieceNumber de ${quarterTurns * 90}°';

  factory RotateAroundMasterCommand.fromMap(Map<String, dynamic> params) {
    return RotateAroundMasterCommand(
      pieceNumber: params['pieceNumber'] as int,
      quarterTurns: params['quarterTurns'] as int,
      durationMs: params['duration'] as int? ?? 500,
    );
  }
}

/// SYMMETRY_AROUND_MASTER
class SymmetryAroundMasterCommand extends ScratchCommand {
  final int pieceNumber;
  final String symmetryKind;
  final int durationMs;

  const SymmetryAroundMasterCommand({
    required this.pieceNumber,
    required this.symmetryKind,
    this.durationMs = 500,
  });
  @override
  Future<void> execute(TutorialContext context) async {
    // Appliquer symétrie H ou V
    if (symmetryKind.toUpperCase() == 'H') {
      context.gameNotifier.applyIsometrySymmetryH();
    } else {
      context.gameNotifier.applyIsometrySymmetryV();
    }
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  @override
  String get name => 'SYMMETRY_AROUND_MASTER';

  @override
  String get description =>
      'Applique une symétrie $symmetryKind à la pièce $pieceNumber';

  factory SymmetryAroundMasterCommand.fromMap(Map<String, dynamic> params) {
    return SymmetryAroundMasterCommand(
      pieceNumber: params['pieceNumber'] as int,
      symmetryKind: params['symmetryKind'] as String,
      durationMs: params['duration'] as int? ?? 500,
    );
  }
}
