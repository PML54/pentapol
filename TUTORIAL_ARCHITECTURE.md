# 🏗️ Architecture du système Tutorial Pentapol

## 📖 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Principes de conception](#principes-de-conception)
3. [Architecture des modules](#architecture-des-modules)
4. [Flux de données](#flux-de-données)
5. [Cycle de vie d'un tutorial](#cycle-de-vie-dun-tutorial)
6. [État et persistence](#état-et-persistence)
7. [Étendre le système](#étendre-le-système)
8. [Débogage et logs](#débogage-et-logs)

---

## Vue d'ensemble

Le système de tutorials Pentapol est inspiré de **Scratch**, le langage visuel de programmation éducatif du MIT. Il permet de créer des séquences d'instructions qui guident l'utilisateur à travers les fonctionnalités du jeu de manière interactive.

### Philosophie

- **Déclaratif** : Les tutorials sont définis en YAML, pas en code
- **Scriptable** : Séquences d'instructions exécutées par un interpréteur
- **Modulaire** : Commandes indépendantes et réutilisables
- **Asynchrone** : Exécution non-bloquante avec gestion d'état
- **Visuel** : Feedback immédiat via overlay et highlights

### Stack technique
```
YAML Script
    ↓
Parser (yaml_parser.dart)
    ↓
TutorialScript (models/)
    ↓
ScratchInterpreter (interpreter/)
    ↓
Commands (commands/)
    ↓
GameNotifier (providers/)
    ↓
UI (widgets/)
```

---

## Principes de conception

### 1. Séparation des préoccupations
```
┌─────────────────────────────────────────────┐
│              Présentation                   │
│  (Widgets : Overlay, Controls)              │
├─────────────────────────────────────────────┤
│              État & Logique                 │
│  (Provider : TutorialNotifier)              │
├─────────────────────────────────────────────┤
│              Exécution                      │
│  (Interpreter : ScratchInterpreter)         │
├─────────────────────────────────────────────┤
│              Commandes                      │
│  (Commands : 28 commandes Phase 1)          │
├─────────────────────────────────────────────┤
│              Données                        │
│  (Models : Script, State, Context)          │
├─────────────────────────────────────────────┤
│              Parsing                        │
│  (Parser : YamlScriptParser)                │
└─────────────────────────────────────────────┘
```

### 2. Inversion de contrôle

Le système n'impose pas de flux rigide. Les commandes sont autonomes et communiquent via le contexte partagé (`TutorialContext`).

### 3. Immutabilité

L'état (`TutorialState`) est immutable. Toute modification crée un nouvel état via `copyWith()`.

### 4. Réactivité

Le système utilise **Riverpod** pour la gestion d'état réactive. Les widgets se reconstituent automatiquement quand l'état change.

---

## Architecture des modules

### Structure des fichiers
```
lib/tutorial/
├── tutorial.dart                    # Export principal
├── models/                          # Modèles de données
│   ├── scratch_command.dart         # Classe de base des commandes
│   ├── tutorial_context.dart        # Contexte d'exécution
│   ├── tutorial_script.dart         # Définition d'un script
│   └── tutorial_state.dart          # État du tutorial
├── interpreter/                     # Moteur d'exécution
│   └── scratch_interpreter.dart     # Interpréteur de scripts
├── parser/                          # Parsing YAML
│   └── yaml_parser.dart             # Parser de scripts
├── commands/                        # Commandes disponibles
│   ├── commands.dart                # Export des commandes
│   ├── control_commands.dart        # WAIT, REPEAT
│   ├── message_commands.dart        # SHOW_MESSAGE, CLEAR_MESSAGE
│   ├── tutorial_mode_commands.dart  # ENTER/EXIT_TUTORIAL_MODE
│   ├── selection_commands.dart      # Sélection slider
│   ├── board_selection_commands.dart # Sélection plateau
│   ├── placement_commands.dart      # Placement pièces
│   ├── highlight_commands.dart      # Highlights de cases
│   └── transform_commands.dart      # Rotations, symétries
├── providers/                       # Gestion d'état
│   └── tutorial_provider.dart       # Provider Riverpod
├── widgets/                         # Interface utilisateur
│   ├── tutorial_overlay.dart        # Overlay messages
│   └── tutorial_controls.dart       # Boutons Play/Pause/Stop
└── examples/                        # Exemples de scripts
    └── 01_intro_basics.yaml         # Tutorial d'introduction

assets/tutorials/                    # Scripts de production
└── 01_intro_basics.yaml
```

### Dépendances entre modules
```
┌──────────────┐
│   Widgets    │
└──────┬───────┘
       │ watch
       ↓
┌──────────────┐
│   Provider   │◄──────────────┐
└──────┬───────┘               │
       │ owns                  │ callbacks
       ↓                       │
┌──────────────┐        ┌──────┴────────┐
│ Interpreter  │───────►│   Commands    │
└──────┬───────┘ executes └──────┬────────┘
       │                         │
       │ uses                    │ modifies
       ↓                         ↓
┌──────────────┐        ┌────────────────┐
│   Context    │◄───────│  GameNotifier  │
└──────────────┘        └────────────────┘
```

---

## Flux de données

### 1. Chargement d'un script
```
[User clicks ?]
      ↓
[GameScreen loads YAML from assets]
      ↓
[YamlScriptParser.parse(yamlContent)]
      ↓
[TutorialScript object created]
      ↓
[tutorialProvider.notifier.loadScript(script)]
      ↓
[TutorialState updated with script]
      ↓
[UI shows Play button]
```

### 2. Exécution d'un script
```
[User clicks Play]
      ↓
[tutorialProvider.notifier.start()]
      ↓
[Create TutorialContext]
      ├─ gameNotifier: PentominoGameNotifier
      ├─ ref: Ref
      └─ variables: Map<String, dynamic>
      ↓
[Create ScratchInterpreter]
      ├─ script: TutorialScript
      ├─ context: TutorialContext
      └─ callbacks: onStepChanged, onCompleted, onError
      ↓
[interpreter.run()]
      ↓
[While loop: for each step]
      ├─ Execute command
      ├─ Update currentStep
      ├─ Call onStepChanged callback
      ├─ Wait 10ms (UI breathing room)
      └─ Check if cancelled
      ↓
[onCompleted callback]
      ↓
[Clean up state]
```

### 3. Exécution d'une commande
```
[Interpreter calls command.execute(context)]
      ↓
[Command accesses context.gameNotifier]
      ↓
[gameNotifier.someMethod()]
      ↓
[GameNotifier updates PentominoGameState]
      ↓
[Riverpod notifies listeners]
      ↓
[GameBoard widget rebuilds]
      ↓
[User sees visual change]
```

### 4. Mise à jour de l'UI
```
[State changes in TutorialNotifier]
      ↓
[Riverpod notifies TutorialOverlay]
      ↓
[Overlay checks state.currentMessage]
      ↓
[If message exists, show _MessageBox]
      ↓
[User sees message in blue box at top]
```

---

## Cycle de vie d'un tutorial

### Diagramme d'états
```
┌─────────────┐
│   INITIAL   │
│ (no script) │
└──────┬──────┘
       │ loadScript()
       ↓
┌─────────────┐
│   LOADED    │
│ (isLoaded)  │
└──────┬──────┘
       │ start()
       ↓
┌─────────────┐
│   RUNNING   │◄────────┐
│ (isRunning) │         │
└──────┬──────┘         │
       │                │
       ├─ pause() ──────┤
       │                │
       ├─ resume() ─────┤
       │                │
       ├─ stop() ───────┼──┐
       │                │  │
       ├─ onCompleted() ┤  │
       │                │  │
       ├─ onError() ────┤  │
       │                   │
       ↓                   ↓
┌─────────────┐    ┌──────────────┐
│  COMPLETED  │    │   STOPPED    │
│             │    │              │
└─────────────┘    └──────────────┘
       │                   │
       │ unloadScript()    │
       └───────┬───────────┘
               ↓
          ┌─────────────┐
          │   INITIAL   │
          └─────────────┘
```

### États du tutorial
```dart
class TutorialState {
  final TutorialScript? currentScript;    // Script chargé
  final ScratchInterpreter? interpreter;  // Moteur d'exécution
  final TutorialContext? context;         // Contexte partagé
  final bool isRunning;                   // En cours d'exécution
  final bool isPaused;                    // En pause
  final int currentStep;                  // Étape courante (0-based)
  final String? currentMessage;           // Message affiché
  final bool isLoaded;                    // Script chargé
}
```

### Propriétés calculées
```dart
// Progression 0.0 - 1.0
double get progress => totalSteps > 0 ? currentStep / totalSteps : 0.0;

// Nombre total d'étapes
int get totalSteps => currentScript?.steps.length ?? 0;

// Tutorial terminé
bool get isCompleted => currentStep >= totalSteps && totalSteps > 0;
```

---

## État et persistence

### Mode tutoriel vs Mode normal

Le jeu a deux modes distincts :
```dart
// Dans PentominoGameState
final bool isTutorialMode;
final PentominoGameState? savedStateBeforeTutorial;
```

**Entrée en mode tutoriel** :
```dart
void enterTutorialMode() {
  // Sauvegarder l'état actuel
  savedStateBeforeTutorial = state.copyWith();
  
  // Activer le flag
  state = state.copyWith(isTutorialMode: true);
}
```

**Sortie du mode tutoriel** :
```dart
void exitTutorialMode({bool restore = true}) {
  if (restore && savedStateBeforeTutorial != null) {
    // Restaurer l'état sauvegardé
    state = savedStateBeforeTutorial!.copyWith(
      isTutorialMode: false,
      savedStateBeforeTutorial: null,
    );
  } else {
    // Garder les modifications
    state = state.copyWith(
      isTutorialMode: false,
      savedStateBeforeTutorial: null,
    );
  }
}
```

### Contexte d'exécution

Le `TutorialContext` est le pont entre l'interpréteur et le jeu :
```dart
class TutorialContext {
  final PentominoGameNotifier gameNotifier;  // Accès au jeu
  final dynamic ref;                         // Ref Riverpod
  final Map<String, dynamic> variables;      // Variables du script
  
  String? currentMessage;                    // Message actuel
  bool isPaused;                             // Flag pause
  bool isCancelled;                          // Flag annulation
  
  // Méthodes de contrôle
  void setMessage(String text);
  void clearMessage();
  void pause();
  void resume();
  void cancel();
  Future<void> waitIfPaused();
}
```

### Variables de script

Les variables permettent de stocker des valeurs pendant l'exécution :
```yaml
variables:
  piece_to_place: 5
  target_x: 2
  target_y: 4
```
```dart
// Accès dans les commandes
final pieceNumber = context.getVariable('piece_to_place');
context.setVariable('score', 100);
context.incrementVariable('attempts', 1);
```

---

## Étendre le système

### Créer une nouvelle commande

#### 1. Créer la classe de commande
```dart
// lib/tutorial/commands/my_commands.dart

import '../models/scratch_command.dart';
import '../models/tutorial_context.dart';

/// Ma nouvelle commande
class MyNewCommand extends ScratchCommand {
  final String myParam;
  
  const MyNewCommand({required this.myParam});
  
  @override
  Future<void> execute(TutorialContext context) async {
    // Implémenter la logique
    context.gameNotifier.doSomething(myParam);
    
    // Optionnel : logs
    print('[TUTORIAL] MyNewCommand exécutée avec $myParam');
  }
  
  @override
  String get name => 'MY_NEW_COMMAND';
  
  @override
  String get description => 'Fait quelque chose avec $myParam';
  
  // Factory pour créer depuis le YAML
  factory MyNewCommand.fromMap(Map<String, dynamic> params) {
    return MyNewCommand(
      myParam: params['myParam'] as String? ?? 'default',
    );
  }
}
```

#### 2. Ajouter au parser
```dart
// lib/tutorial/parser/yaml_parser.dart

static ScratchCommand _parseCommand(dynamic stepData) {
  // ... code existant ...
  
  switch (commandName) {
    // ... autres commandes ...
    
    case 'MY_NEW_COMMAND':
      return MyNewCommand.fromMap(paramsMap);
    
    // ... reste ...
  }
}
```

#### 3. Exporter la commande
```dart
// lib/tutorial/commands/commands.dart

export 'my_commands.dart';
```

#### 4. Utiliser dans un script
```yaml
steps:
  - command: MY_NEW_COMMAND
    params:
      myParam: "test"
```

### Ajouter une méthode au GameNotifier

Si votre commande nécessite une nouvelle action dans le jeu :
```dart
// lib/providers/pentomino_game_provider.dart

// Dans la section TUTORIEL
void myNewMethodForTutorial(String param) {
  // Implémenter la logique
  print('[TUTORIAL] myNewMethodForTutorial appelée avec $param');
  
  // Modifier l'état si nécessaire
  state = state.copyWith(
    // ... modifications ...
  );
}
```

### Pattern Command

Le système utilise le **pattern Command** :
```dart
abstract class ScratchCommand {
  const ScratchCommand();
  
  // Exécuter la commande
  Future<void> execute(TutorialContext context);
  
  // Validation (optionnelle)
  bool validate() => true;
  
  // Métadonnées
  String get name;
  String get description;
}
```

**Avantages** :
- Chaque commande est isolée
- Facile à tester unitairement
- Extensible sans modifier l'interpréteur
- Peut être annulée (undo) si nécessaire

---

## Débogage et logs

### Niveaux de logs
```dart
// Parser
print('[PARSER] Début parsing...');
print('[PARSER] YAML chargé, type: $type');

// Interpréteur
print('[INTERPRETER] Démarrage du script: $name');
print('[INTERPRETER] Étape $step: $commandName');
print('[INTERPRETER] Erreur à l\'étape $step: $error');

// Provider
print('[TUTORIAL] Chargement du script: $name');
print('[TUTORIAL] Démarrage du tutoriel: $name');
print('[TUTORIAL] Tutoriel terminé: $name');

// Commandes
print('[TUTORIAL] Pièce $id sélectionnée');
print('[TUTORIAL] Case ($x, $y) surlignée');
print('[TUTORIAL] Mode tutoriel activé');

// Game Notifier
print('[GAME] Rotation 90° horaire autour de ($x, $y)');
print('[GAME] ✅ Rotation réussie');
```

### Filtrer les logs
```bash
# Tous les logs tutorial
flutter run 2>&1 | grep TUTORIAL

# Logs d'erreur uniquement
flutter run 2>&1 | grep -E "ERREUR|ERROR|Exception"

# Suivi d'exécution
flutter run 2>&1 | grep -E "INTERPRETER|Étape"

# Logs de parsing
flutter run 2>&1 | grep PARSER
```

### Débugger un script

1. **Vérifier le parsing** :
```dart
try {
  final script = YamlScriptParser.parse(yamlContent);
  print('✅ Script parsé : ${script.steps.length} étapes');
} catch (e) {
  print('❌ Erreur parsing : $e');
}
```

2. **Ajouter des prints dans les commandes** :
```dart
@override
Future<void> execute(TutorialContext context) async {
  print('[DEBUG] Avant exécution');
  await myAction();
  print('[DEBUG] Après exécution');
}
```

3. **Utiliser les breakpoints** :
```dart
// Dans ScratchInterpreter.run()
while (currentStep < script.steps.length) {
  final command = script.steps[currentStep];
  debugger(); // Breakpoint IDE
  await command.execute(context);
}
```

4. **Valider l'état** :
```dart
// Après chaque commande
print('[STATE] isRunning: ${state.isRunning}');
print('[STATE] currentStep: ${state.currentStep}');
print('[STATE] currentMessage: ${state.currentMessage}');
```

### Erreurs communes

#### 1. Commande inconnue
```
FormatException: Commande inconnue: TYPO_COMMAND
```
**Solution** : Vérifier l'orthographe dans le YAML et dans le parser.

#### 2. Paramètre manquant
```
type 'Null' is not a subtype of type 'int'
```
**Solution** : Vérifier que tous les paramètres requis sont fournis dans le YAML.

#### 3. Méthode non définie
```
The method 'someMethod' isn't defined for the type 'PentominoGameNotifier'
```
**Solution** : Ajouter la méthode dans le GameNotifier.

#### 4. État non mis à jour
```
[TUTORIAL] Pièce placée
// Mais l'UI ne change pas
```
**Solution** : Vérifier que l'état est copié avec `copyWith()` et non muté directement.

---

## Exemples d'architecture avancée

### Commande composite (future Phase 2)
```dart
class SequenceCommand extends ScratchCommand {
  final List<ScratchCommand> commands;
  
  @override
  Future<void> execute(TutorialContext context) async {
    for (final command in commands) {
      await command.execute(context);
      if (context.isCancelled) break;
    }
  }
}
```

### Commande conditionnelle (future Phase 2)
```dart
class IfCommand extends ScratchCommand {
  final bool Function(TutorialContext) condition;
  final ScratchCommand thenCommand;
  final ScratchCommand? elseCommand;
  
  @override
  Future<void> execute(TutorialContext context) async {
    if (condition(context)) {
      await thenCommand.execute(context);
    } else if (elseCommand != null) {
      await elseCommand!.execute(context);
    }
  }
}
```

### Interaction utilisateur (future Phase 2)
```dart
class WaitForUserTapCommand extends ScratchCommand {
  @override
  Future<void> execute(TutorialContext context) async {
    final completer = Completer<void>();
    
    // Enregistrer un listener
    context.gameNotifier.onTap = () {
      completer.complete();
    };
    
    // Attendre le tap
    await completer.future;
    
    // Nettoyer
    context.gameNotifier.onTap = null;
  }
}
```

---

## Performance et optimisation

### Bonnes pratiques

1. **Éviter les boucles while infinies** :
```dart
// ❌ Mauvais
while (true) {
  await command.execute(context);
}

// ✅ Bon
while (!context.isCancelled) {
  await command.execute(context);
}
```

2. **Donner du temps à l'UI** :
```dart
// Après chaque commande
await Future.delayed(Duration(milliseconds: 10));
```

3. **Libérer les ressources** :
```dart
void dispose() {
  interpreter?.stop();
  state = TutorialState.initial();
}
```

4. **Éviter les fuites mémoire** :
```dart
// Nettoyer les callbacks
onStepChanged = null;
onCompleted = null;
onError = null;
```

### Métriques
```dart
// Mesurer le temps d'exécution
final stopwatch = Stopwatch()..start();
await interpreter.run();
print('Durée: ${stopwatch.elapsedMilliseconds}ms');
```

---

## Tests

### Test unitaire d'une commande
```dart
test('WaitCommand waits for specified duration', () async {
  final command = WaitCommand(durationMs: 100);
  final context = MockTutorialContext();
  
  final stopwatch = Stopwatch()..start();
  await command.execute(context);
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
});
```

### Test d'intégration
```dart
testWidgets('Tutorial runs to completion', (tester) async {
  // Charger le script
  final script = TutorialScript.fromMap({...});
  
  // Démarrer
  await tester.pumpWidget(MyApp());
  final notifier = container.read(tutorialProvider.notifier);
  notifier.loadScript(script);
  notifier.start();
  
  // Attendre la fin
  await tester.pumpAndSettle(Duration(seconds: 10));
  
  // Vérifier
  expect(notifier.state.isCompleted, true);
});
```

---

## Roadmap Phase 2

### Commandes avancées

- [ ] `IF` / `ELSE` : Conditions
- [ ] `WHILE` : Boucles conditionnelles
- [ ] `FOR` : Boucles itératives
- [ ] `SET_VARIABLE` : Modifier une variable
- [ ] `WAIT_FOR_TAP` : Attendre un tap utilisateur
- [ ] `WAIT_FOR_PIECE_PLACED` : Attendre un placement
- [ ] `ANIMATION` : Transitions fluides

### Fonctionnalités

- [ ] Éditeur visuel de scripts
- [ ] Menu de sélection de tutorials
- [ ] Progression sauvegardée
- [ ] Badges et récompenses
- [ ] Mode rejouer
- [ ] Enregistrement des sessions

### Infrastructure

- [ ] Tests unitaires complets
- [ ] Tests d'intégration
- [ ] Documentation interactive
- [ ] Outil de validation de scripts
- [ ] Hot reload des scripts

---

## Références

### Design patterns utilisés

- **Command Pattern** : Encapsulation des commandes
- **Interpreter Pattern** : Exécution de scripts
- **State Pattern** : Gestion des états du tutorial
- **Provider Pattern** : Gestion d'état réactive (Riverpod)
- **Factory Pattern** : Création des commandes depuis YAML

### Inspirations

- **Scratch** (MIT) : Langage visuel de programmation
- **Game Maker** : System d'événements et actions
- **Unity Playmaker** : Visual scripting
- **Blueprints** (Unreal) : Node-based scripting

### Ressources

- [Riverpod Documentation](https://riverpod.dev/)
- [YAML Specification](https://yaml.org/)
- [Flutter State Management](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Design Patterns in Dart](https://refactoring.guru/design-patterns/dart)

---

**Document rédigé en Novembre 2025**

**Auteur** : Système Tutorial Pentapol

**Version** : 1.0 - Phase 1