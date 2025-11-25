// lib/tutorial/commands/message_commands.dart
// Commandes de gestion des messages

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// Commande SHOW_MESSAGE - Affiche un message
class ShowMessageCommand extends ScratchCommand {
  final String text;

  const ShowMessageCommand({required this.text});

  @override
  Future<void> execute(TutorialContext context) async {
    context.setMessage(text);
  }

  @override
  String get name => 'SHOW_MESSAGE';

  @override
  String get description => 'Affiche: "$text"';

  factory ShowMessageCommand.fromMap(Map<String, dynamic> params) {
    return ShowMessageCommand(text: params['text'] as String? ?? '');
  }
}

/// Commande CLEAR_MESSAGE - Efface le message
class ClearMessageCommand extends ScratchCommand {
  const ClearMessageCommand();

  @override
  Future<void> execute(TutorialContext context) async {
    context.clearMessage();
  }

  @override
  String get name => 'CLEAR_MESSAGE';

  @override
  String get description => 'Efface le message';
}
