// lib/tutorial/commands/control_commands.dart
// Commandes de contrôle (WAIT, REPEAT)

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// Commande WAIT - Attend un certain temps
class WaitCommand extends ScratchCommand {
  final int durationMs;

  const WaitCommand({this.durationMs = 1000});

  @override
  Future<void> execute(TutorialContext context) async {
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  @override
  String get name => 'WAIT';

  @override
  String get description => 'Attend $durationMs millisecondes';

  factory WaitCommand.fromMap(Map<String, dynamic> params) {
    return WaitCommand(durationMs: params['duration'] as int? ?? 1000);
  }
}

/// Commande REPEAT - Répète un bloc de commandes
class RepeatCommand extends ScratchCommand {
  final int count;
  final List<ScratchCommand> commands;

  const RepeatCommand({required this.count, required this.commands});

  @override
  Future<void> execute(TutorialContext context) async {
    for (int i = 0; i < count; i++) {
      if (context.isCancelled) break;

      for (final command in commands) {
        await command.execute(context);
        if (context.isCancelled) break;
      }
    }
  }

  @override
  String get name => 'REPEAT';

  @override
  String get description => 'Répète $count fois';

  factory RepeatCommand.fromMap(Map<String, dynamic> params) {
    return RepeatCommand(
      count: params['count'] as int? ?? 1,
      commands: [], // Sera rempli par le parser
    );
  }
}
