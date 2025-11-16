// Modified: 2025-11-16 08:30:00
// lib/config/game_config.dart
// Configuration globale du jeu et progression pédagogique

/// Niveau d'expérience du joueur
enum PlayerLevel {
  beginner,    // Débutant : UI simplifiée
  intermediate, // Intermédiaire : toutes les fonctions
  advanced,    // Avancé : stats, défis
  expert,      // Expert : mode compétition
}

/// Configuration des fonctionnalités selon le niveau
class GameConfig {
  final PlayerLevel level;
  
  const GameConfig({required this.level});
  
  // 🎮 Fonctionnalités UI
  bool get showSolutionCounter => level != PlayerLevel.beginner;
  bool get showRotationButton => level != PlayerLevel.beginner;
  bool get showMirrorButton => level.index >= PlayerLevel.intermediate.index;
  bool get showUndoButton => true; // Toujours visible
  bool get showViewSolutionsButton => level.index >= PlayerLevel.intermediate.index;
  bool get enableInSituRotation => level.index >= PlayerLevel.advanced.index;
  bool get showHints => level == PlayerLevel.beginner;
  
  // 🤖 Coach IA
  bool get enableAICoach => true; // Toujours actif
  CoachPersonality get coachPersonality {
    switch (level) {
      case PlayerLevel.beginner:
        return CoachPersonality.encouraging; // Très encourageant
      case PlayerLevel.intermediate:
        return CoachPersonality.helpful; // Aide stratégique
      case PlayerLevel.advanced:
        return CoachPersonality.challenging; // Défis
      case PlayerLevel.expert:
        return CoachPersonality.competitive; // Compétitif
    }
  }
  
  // ⏱️ Timings
  Duration get longPressDuration {
    switch (level) {
      case PlayerLevel.beginner:
        return const Duration(milliseconds: 400); // Plus lent
      case PlayerLevel.intermediate:
        return const Duration(milliseconds: 300);
      case PlayerLevel.advanced:
      case PlayerLevel.expert:
        return const Duration(milliseconds: 200); // Rapide
    }
  }
  
  // 🎯 Objectifs pédagogiques
  List<LearningGoal> get currentGoals {
    switch (level) {
      case PlayerLevel.beginner:
        return [
          LearningGoal.understandDragDrop,
          LearningGoal.completeFirstPuzzle,
        ];
      case PlayerLevel.intermediate:
        return [
          LearningGoal.useRotation,
          LearningGoal.understandSymmetry,
          LearningGoal.complete5Puzzles,
        ];
      case PlayerLevel.advanced:
        return [
          LearningGoal.optimizeTime,
          LearningGoal.exploreSolutions,
          LearningGoal.complete20Puzzles,
        ];
      case PlayerLevel.expert:
        return [
          LearningGoal.speedRun,
          LearningGoal.multiplayerReady,
        ];
    }
  }
  
  // 🎨 Thème visuel
  GameTheme get theme {
    switch (level) {
      case PlayerLevel.beginner:
        return GameTheme.colorful; // Couleurs vives
      case PlayerLevel.intermediate:
        return GameTheme.balanced;
      case PlayerLevel.advanced:
      case PlayerLevel.expert:
        return GameTheme.minimalist; // Sobre
    }
  }
}

/// Personnalité du coach IA
enum CoachPersonality {
  encouraging,  // "Bravo ! Continue comme ça !"
  helpful,      // "Essaie de placer le L en haut à gauche"
  challenging,  // "Peux-tu faire mieux que 2min ?"
  competitive,  // "Tu es 5ème du classement mondial !"
}

/// Objectifs d'apprentissage
enum LearningGoal {
  understandDragDrop,
  completeFirstPuzzle,
  useRotation,
  understandSymmetry,
  complete5Puzzles,
  complete20Puzzles,
  optimizeTime,
  exploreSolutions,
  speedRun,
  multiplayerReady,
}

/// Thème visuel
enum GameTheme {
  colorful,    // Couleurs vives, animations
  balanced,    // Équilibré
  minimalist,  // Sobre, pro
}

/// Messages du coach selon le contexte
class CoachMessages {
  static String getWelcomeMessage(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return "👋 Bienvenue ! Je suis Penta, ton guide. "
               "Je vais t'apprendre à jouer avec les pentominos !";
      case PlayerLevel.intermediate:
        return "🎯 Salut ! Prêt pour de nouveaux défis ?";
      case PlayerLevel.advanced:
        return "🚀 Let's go ! Montre-moi ce que tu sais faire.";
      case PlayerLevel.expert:
        return "🏆 Champion ! En route vers le top 10 ?";
    }
  }
  
  static String getFirstPiecePlaced(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return "✨ Excellent ! Tu as placé ta première pièce. "
               "Continue, il en reste 11 !";
      case PlayerLevel.intermediate:
        return "👍 Bon début ! Pense aux rotations.";
      case PlayerLevel.advanced:
        return "⚡ Rapide ! Temps actuel : {time}";
      case PlayerLevel.expert:
        return "🔥 En feu ! Record à battre : {record}";
    }
  }
  
  static String getStuckHint(PlayerLevel level, int solutionsCount) {
    if (level == PlayerLevel.beginner) {
      if (solutionsCount == 0) {
        return "🤔 Hmm... Cette configuration n'a pas de solution. "
               "Essaie de retirer une pièce et de la replacer différemment.";
      } else {
        return "💡 Astuce : Commence par les coins et les bords !";
      }
    }
    return "";
  }
  
  static String getGeometryLesson(String concept) {
    switch (concept) {
      case 'rotation':
        return "🔄 La rotation fait tourner une pièce de 90°. "
               "Certaines pièces ont 4 orientations différentes !";
      case 'symmetry':
        return "🪞 La symétrie crée l'image miroir d'une pièce. "
               "Comme si tu la retournais !";
      case 'area':
        return "📐 Chaque pentomino couvre 5 cases. "
               "12 pièces × 5 cases = 60 cases (le plateau 6×10) !";
      case 'tessellation':
        return "🧩 Le pavage, c'est remplir un espace sans trou ni chevauchement. "
               "Il existe 9356 solutions différentes !";
      default:
        return "";
    }
  }
}

/// Configuration par défaut (débutant)
const kDefaultConfig = GameConfig(level: PlayerLevel.beginner);

