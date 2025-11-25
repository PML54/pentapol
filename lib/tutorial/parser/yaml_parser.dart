// lib/tutorial/parser/yaml_parser.dart
// Parser YAML → TutorialScript

import 'package:yaml/yaml.dart';
import '../models/tutorial_script.dart';
import '../models/scratch_command.dart';
import '../commands/control_commands.dart';
import '../commands/message_commands.dart';
import '../commands/tutorial_mode_commands.dart';
import '../commands/selection_commands.dart';
import '../commands/board_selection_commands.dart';
import '../commands/placement_commands.dart';
import '../commands/highlight_commands.dart';
import '../commands/transform_commands.dart';

/// Parser de scripts YAML
class YamlScriptParser {
  /// Parse un fichier YAML en TutorialScript
  static TutorialScript parse(String yamlContent) {
    print('[PARSER] Début parsing...');

    try {
      final doc = loadYaml(yamlContent);
      print('[PARSER] YAML chargé, type: ${doc.runtimeType}');

      final docMap = doc as Map;
      print('[PARSER] Converti en Map, keys: ${docMap.keys}');

      // Créer le script de base
      final script = TutorialScript.fromMap(Map<String, dynamic>.from(docMap));
      print('[PARSER] Script de base créé: ${script.name}');

      // Parser les steps
      final stepsData = docMap['steps'];
      print('[PARSER] Steps data type: ${stepsData.runtimeType}');

      if (stepsData == null || stepsData is! List) {
        throw FormatException('Le script doit contenir au moins une step');
      }

      print('[PARSER] Nombre de steps: ${stepsData.length}');

      final steps = <ScratchCommand>[];
      for (int i = 0; i < stepsData.length; i++) {
        print('[PARSER] Parsing step $i...');
        final stepData = stepsData[i];
        print('[PARSER] Step $i data: $stepData');

        final command = _parseCommand(stepData);
        print('[PARSER] Step $i parsée: ${command.name}');
        steps.add(command);
      }

      print('[PARSER] Toutes les steps parsées !');
      return script.copyWith(steps: steps);

    } catch (e, stackTrace) {
      print('[PARSER] ERREUR: $e');
      print('[PARSER] Stack: $stackTrace');
      rethrow;
    }
  }

  /// Parse une commande depuis un Map
  /// Parse une commande depuis un Map
  static ScratchCommand _parseCommand(dynamic stepData) {
    // Convertir en Map de manière sûre
    final step = stepData is Map ? stepData : <String, dynamic>{};

    final commandName = step['command'] as String? ?? '';

    // Récupérer params de manière ultra-safe
    Map<String, dynamic> paramsMap = {};
    try {
      if (step.containsKey('params')) {
        final paramsValue = step['params'];
        if (paramsValue != null && paramsValue is Map) {
          paramsMap = Map<String, dynamic>.from(paramsValue);
        }
      }
    } catch (e) {
      print('[PARSER] Erreur parsing params pour $commandName: $e');
      paramsMap = {};
    }

    switch (commandName) {
    // Contrôle
      case 'WAIT':
        return WaitCommand.fromMap(paramsMap);
      case 'REPEAT':
        return RepeatCommand.fromMap(paramsMap);

    // Messages
      case 'SHOW_MESSAGE':
        return ShowMessageCommand.fromMap(paramsMap);
      case 'CLEAR_MESSAGE':
        return ClearMessageCommand();

    // Mode tutoriel
      case 'ENTER_TUTORIAL_MODE':
        return EnterTutorialModeCommand();
      case 'EXIT_TUTORIAL_MODE':
        return ExitTutorialModeCommand.fromMap(paramsMap);
      case 'CANCEL_TUTORIAL':
        return CancelTutorialCommand();
      case 'RESET_GAME':
        return ResetGameCommand();

    // Sélection Slider
      case 'SELECT_PIECE_FROM_SLIDER':
        return SelectPieceFromSliderCommand.fromMap(paramsMap);
      case 'HIGHLIGHT_PIECE_IN_SLIDER':
        return HighlightPieceInSliderCommand.fromMap(paramsMap);
      case 'CLEAR_SLIDER_HIGHLIGHT':
        return ClearSliderHighlightCommand();
      case 'SCROLL_SLIDER':
        return ScrollSliderCommand.fromMap(paramsMap);
      case 'SCROLL_SLIDER_TO_PIECE':
        return ScrollSliderToPieceCommand.fromMap(paramsMap);
      case 'RESET_SLIDER_POSITION':
        return ResetSliderPositionCommand();

    // Sélection Plateau
      case 'SELECT_PIECE_ON_BOARD_AT':
        return SelectPieceOnBoardAtCommand.fromMap(paramsMap);
      case 'SELECT_PIECE_ON_BOARD_WITH_MASTERCASE':
        return SelectPieceOnBoardWithMastercaseCommand.fromMap(paramsMap);
      case 'HIGHLIGHT_PIECE_ON_BOARD':
        return HighlightPieceOnBoardCommand.fromMap(paramsMap);
      case 'CANCEL_SELECTION':
        return CancelSelectionCommand();

    // Placement
      case 'PLACE_SELECTED_PIECE_AT':
        return PlaceSelectedPieceAtCommand.fromMap(paramsMap);
      case 'REMOVE_PIECE_AT':
        return RemovePieceAtCommand.fromMap(paramsMap);

    // Highlights
      case 'HIGHLIGHT_CELL':
        return HighlightCellCommand.fromMap(paramsMap);
      case 'HIGHLIGHT_CELLS':
        return HighlightCellsCommand.fromMap(paramsMap);
      case 'HIGHLIGHT_VALID_POSITIONS':
        return HighlightValidPositionsCommand.fromMap(paramsMap);
      case 'CLEAR_HIGHLIGHTS':
        return ClearHighlightsCommand();
      case 'HIGHLIGHT_MASTERCASE':
        return HighlightMastercaseCommand.fromMap(paramsMap);

    // Transformations
      case 'ROTATE_AROUND_MASTER':
        return RotateAroundMasterCommand.fromMap(paramsMap);
      case 'SYMMETRY_AROUND_MASTER':
        return SymmetryAroundMasterCommand.fromMap(paramsMap);

      default:
        throw FormatException('Commande inconnue: $commandName');
    }
  }

  /// Valide un script YAML sans le parser complètement
  static bool validate(String yamlContent) {
    try {
      final doc = loadYaml(yamlContent) as Map;

      // Vérifications basiques
      if (!doc.containsKey('id')) return false;
      if (!doc.containsKey('name')) return false;
      if (!doc.containsKey('steps')) return false;

      final steps = doc['steps'] as List?;
      if (steps == null || steps.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
