# Plan — ce que Pentapol garde sur l'appareil

> Établi le 2026-08-30 par cowork, en préparation d'une mise sur l'App Store.
> **Étape 1 faite** (`ea23af7`) : Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.
> Restent les étapes 2 à 4. L'abandon pur et simple de l'historique, un temps envisagé, a été
> écarté : on repart d'un schéma propre (§4).
>
> Numéros de ligne relevés après `fe3c331`.

---

## 1. Le principe

**Une seule base, drift/SQLite, et rien d'autre.** Pas de Supabase, pas de
`SharedPreferences`, pas de fichier à côté. Trois tables, trois natures de données :

| table | nature | durée de vie |
|---|---|---|
| `Settings` | préférences de l'appareil | permanente |
| `CurrentGame` | la partie en cours | jusqu'à la fin de cette partie |
| `SolvedSolutions` + `PuzzleStats` | ce que le joueur a accompli | permanente |

**Ce qu'on ne stocke pas, et pourquoi** — ça vaut la peine de l'écrire, c'est ce qui garde
la base petite :

- le **plateau** : `_rebuildPlateau()` le reconstruit depuis `placedPieces` ;
- les **solutions** : elles sont dans le `.bin` ou recalculées par le solveur ;
- `puzzle.solutions` : délibérément vide pour les rectangles complets (plan 6×10 §4.5) ;
- un **journal partie par partie** : voir §4.2.

---

## 2. La partie en cours — la table qui manque

C'est le manque le plus coûteux aujourd'hui, et celui auquel on pense en dernier. Quitter
l'application au milieu d'un 6×10 — qui dure — **perd tout**. Sur mobile, où l'on joue par
tranches de cinq minutes, c'est un défaut d'usage plus grave que les deux bugs de la semaine.

### 2.1 Le contenu, minimal

```dart
class CurrentGame extends Table {
  IntColumn  get id => integer().withDefault(const Constant(0))(); // ligne unique
  TextColumn get sizeName => text()();          // PentoscopeSize.name, ex. 'size6x10'
  TextColumn get pieceIds => text()();          // '1,2,3,…' — le tirage du puzzle
  IntColumn  get solutionCount => integer()();  // repris de PentoscopePuzzle
  TextColumn get placedPieces => text()();      // JSON : [{id,pos,x,y}, …]
  TextColumn get positionIndices => text()();   // JSON : {pieceId: orientation}
  IntColumn  get elapsedSeconds => integer()();
  IntColumn  get isometryCount => integer()();
  IntColumn  get translationCount => integer()();
  IntColumn  get deleteCount => integer()();
  IntColumn  get hintCount => integer()();
  DateTimeColumn get savedAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
}
```

Une seule ligne, écrasée. `sizeName` plutôt que l'index de l'enum : un `PentoscopeSize`
inséré au milieu ne doit pas transformer une partie 4×5 en 6×10.

### 2.2 Quand écrire

- **après chaque changement de `placedPieces`** — `tryPlacePiece`, `applyHint`,
  `removePlacedPiece` ;
- **au passage en arrière-plan**, pour figer `elapsedSeconds` : `main.dart`
  `_PentapolAppState` prend un `with WidgetsBindingObserver` et écrit sur
  `AppLifecycleState.paused`.

**Ne pas écrire à chaque tic du chrono** : le mixin tique toutes les 100 ms, ce serait dix
écritures par seconde pour rien. Le temps se fige à la mise en arrière-plan, c'est suffisant.

### 2.3 Quand effacer

À la **complétion** (il n'y a plus rien à reprendre) et au **démarrage d'une partie neuve**
(`startPuzzle`, `startPuzzleFromSeed`, `reset`).

### 2.4 La reprise

`startPuzzle` **génère** un puzzle : il ne peut pas servir à la reprise. Il faut un
`restoreGame(CurrentGame row)` qui reconstruit le `PentoscopePuzzle` depuis `pieceIds` et
`solutionCount` **sans passer par le générateur**, puis rejoue les placements.

> ⚠️ **`showSolution` n'est pas restaurable** : il s'appuie sur `puzzle.solutions[0]`, liste
> qu'on ne stocke pas. À la reprise, le remettre à `false`. C'est une perte acceptable ; la
> stocker coûterait plus cher que la fonctionnalité ne vaut.

> ⚠️ Au démarrage, la reprise entre en concurrence avec le puzzle 5×5 pré-généré de
> `main.dart` (l.48-53). Ordre à respecter : **lire la table d'abord**, ne générer un puzzle
> neuf que s'il n'y a pas de partie en cours.

---

## 3. Les réglages — inchangés

`Settings`, table clé/valeur, une ligne `app_settings` contenant tout `AppSettings`
sérialisé en JSON (`ui`, `game`, `duel`). C'est simple, ça absorbe l'ajout d'un champ sans
migration, et ça marche. **Ne rien y changer.**

> Correction d'une erreur de documentation du 2026-08-30 : le pseudo multijoueur n'est pas
> dans `SharedPreferences`, il est dans `DuelSettings.playerName`, donc dans ce JSON.

---

## 4. Les records — deux tables, parce que deux familles

### 4.1 Le schéma

```dart
/// Rectangles complets : une ligne par SOLUTION DÉCOUVERTE.
class SolvedSolutions extends Table {
  TextColumn get board => text()();                 // '6x10', '5x12', '4x15'
  IntColumn  get solutionNumber => integer()();     // 1..9356 pour le 6×10
  IntColumn  get timesSolved => integer().withDefault(const Constant(1))();
  IntColumn  get bestTimeSeconds => integer()();
  IntColumn  get bestActions => integer().nullable()();
  DateTimeColumn get firstSolvedAt => dateTime()();
  DateTimeColumn get lastSolvedAt => dateTime()();
  @override Set<Column> get primaryKey => {board, solutionNumber};
}

/// Puzzles à pièces tirées : pas de numéro de solution, un agrégat par taille.
class PuzzleStats extends Table {
  TextColumn get sizeName => text()();               // 'size4x5'
  IntColumn  get completed => integer().withDefault(const Constant(0))();
  IntColumn  get bestTimeSeconds => integer().nullable()();
  @override Set<Column> get primaryKey => {sizeName};
}
```

**`board` en clé dès maintenant**, même s'il n'y a qu'un 6×10 : le 5×12 et le 4×15 arrivent,
et c'est le défaut exact de l'ancienne `SolutionStats` — `solutionNumber` seul n'est pas
unique entre plateaux, la solution n° 5 du 6×10 et celle du 5×12 se confondraient.

**`(board, solutionNumber)` est déjà le schéma d'un classement partagé.** Les 9356 forment un
espace fini, énumérable, commun à tous les joueurs. Construire cette table en local
aujourd'hui laisse la porte ouverte sans l'ouvrir.

### 4.2 Décision : des agrégats, pas un journal

L'ancienne `GameSessions` écrivait **une ligne par partie**. Elle n'a jamais été consultée —
son unique lecteur était `DatabaseDebugScreen`, sur un écran devenu injoignable. Une table
qui grossit sans fin pour une donnée que personne ne lit n'a pas sa place dans une app
publiée. Si le journal devient utile un jour, l'ajouter est facile.

### 4.3 Le numéro de solution vient d'où

De `SolutionMatcher.findSolutionIndex`, exposé par une **cinquième méthode de
`SolutionSource`** :

```dart
/// L'index de la solution atteinte, ou null si la source ne sait pas la nommer.
int? solutionIndexOf(Plateau plateau);
```

`TableSolutionSource` la sert ; `LiveSolutionSource` renvoie `null`. **C'est exactement là
que passe la frontière entre les deux tables** : `null` → `PuzzleStats`, un entier →
`SolvedSolutions`. Aucun test de taille ailleurs dans le code.

---

## 5. La réécriture destructive, et sa date de péremption

L'application **n'est pas publiée** (`version: 1.0.0+1`). Il n'existe aucune base ailleurs
que sur les appareils de test de Paul, et ses lignes actuelles sont des parties du mode
classique supprimé. **Il n'y a donc rien à migrer.**

Mais réécrire les tables sans rien d'autre ne suffit pas : `onCreate` ne s'exécute que si le
fichier SQLite **n'existe pas**. Sur un appareil déjà installé, l'ancien fichier reste et le
premier accès à `SolvedSolutions` lève un `no such table` — à l'exécution, invisible pour
`flutter analyze`.

**Donc : `schemaVersion` passe à 2, avec une stratégie qui efface et recrée à tout changement
de version.** Drift fournit ça tout prêt. **Vérifié dans le pub-cache (drift 2.30.0) par le
CLI le 2026-08-30** : le nom est bien `destructiveFallback`, mais ce n'est **pas** « à passer
en `onUpgrade` » — c'est un *getter* d'extension (`DestructiveMigrationExtension on
GeneratedDatabase`) qui **retourne une `MigrationStrategy` complète** (avec son propre
`onCreate` et un `onUpgrade` qui drop+recrée toutes les entités). On l'assigne directement au
getter `migration` de la base :

```dart
@override
MigrationStrategy get migration => destructiveFallback;
```

Réf. : `.../drift-2.30.0/lib/src/runtime/query_builder/migration.dart` l.645.

C'est la réécriture voulue, mais déclarée dans le code plutôt que dans la tête : aucun geste
manuel à retenir, et l'intention est lisible.

> 🚨 **Date de péremption : la première soumission App Store.** Après publication, les
> données ne sont plus celles de Paul. Une réécriture destructive dans une mise à jour efface
> les records des joueurs, et elle ne se déclenchera que le jour où le schéma bougera — des
> mois plus tard, quand personne ne se souviendra qu'elle est là.
> **Le retrait de cette stratégie est inscrit dans `CHECKLIST_APPSTORE.md`.**

---

## 6. Le ménage qui vient avec

**`SharedPreferences` disparaît entièrement.** Son unique usage dans tout `lib/` est
`pentoscope_last_completed`, écrit par `_saveCompletedLevel` (`pentoscope_provider.dart`
l.678-692) et **jamais relu** : aucun `getString` nulle part. C'est de la donnée en écriture
seule. `_saveCompletedLevel` est remplacée par l'écriture dans `SolvedSolutions` /
`PuzzleStats`, et le paquet sort de `pubspec.yaml` s'il n'a plus d'autre usage.

**`supabase_flutter` sort de `pubspec.yaml`.** `lib/bootstrap.dart` dit lui-même « Vide -
Supabase n'est pas utilisé ». Aujourd'hui l'app en porte tous les inconvénients — poids du
binaire, déclaration App Privacy à remplir — et aucun bénéfice. Supprimer aussi
`lib/bootstrap.dart`, qui ne contient que ce commentaire.

**`DatabaseDebugScreen` disparaît** : son seul accès était `HomeScreen`, supprimé. S'il faut
un jour regarder les records, ce sera un écran de jeu, pas un écran de debug.

---

## 7. Ordre d'exécution

1. **Ménage** — retirer `supabase_flutter` et `bootstrap.dart`, supprimer
   `DatabaseDebugScreen`, `flutter pub get`. Commit seul, aucune fonctionnalité touchée.
2. **Schéma** — les quatre tables (`Settings` inchangée, `CurrentGame`, `SolvedSolutions`,
   `PuzzleStats`), `schemaVersion` 2, stratégie destructive,
   `dart run build_runner build --delete-conflicting-outputs`. Commit seul.
3. **Records** — `solutionIndexOf` sur `SolutionSource`, écriture à la complétion en
   remplacement de `_saveCompletedLevel`, `SharedPreferences` retiré. Commit seul.
4. **Partie en cours** — écriture, effacement, `restoreGame`, observateur de cycle de vie
   dans `main.dart`. Commit seul. **C'est l'étape la plus délicate**, elle mérite d'être
   isolée.

`settings_database.g.dart` est **généré** : ne jamais l'éditer à la main, toujours
régénérer.

---

## 8. Critères de fin

```bash
grep -rn "SharedPreferences" lib/            # attendu : aucun
grep -rn "supabase" lib/ pubspec.yaml        # attendu : aucun
grep -rn "GameSession\|SolutionStat\b" lib/  # attendu : aucun (anciennes tables)
grep -n "schemaVersion" lib/database/settings_database.dart   # attendu : 2
flutter analyze                              # 0 warning
flutter test                                 # doit passer — voir CHECKLIST_APPSTORE
```

Test appareil — **sur une base existante**, pas sur une installation neuve :

- l'app démarre, les réglages sont perdus une fois (réécriture destructive) puis persistent ;
- commencer un 6×10, poser trois pièces, **tuer l'app**, la relancer : la partie reprend, le
  plateau et le temps sont ceux d'avant ;
- terminer un 6×10 : le numéro de solution est enregistré ; le refaire plus vite met à jour
  le meilleur temps sans créer de doublon ;
- terminer un puzzle 4×5 : `PuzzleStats` s'incrémente, `SolvedSolutions` ne bouge pas ;
- démarrer une partie neuve alors qu'une partie était en cours : l'ancienne est effacée, pas
  reprise au lancement suivant.

---

## Voir aussi

- `docs/CHECKLIST_APPSTORE.md` — ce qui doit être fait avant la première soumission
- `docs/FONCTIONNEMENT.md` — l'interface `SolutionSource` et ses deux implémentations
