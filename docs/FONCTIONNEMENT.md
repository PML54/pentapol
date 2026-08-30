# Pentapol — Documentation fonctionnelle

> **Révisée contre le code le 2026-08-30**, après la suppression du mode classique
> (`371c3d5`) et l'application du §8 de `PLAN_SUPPRESSION_CLASSICAL.md`. Chaque
> affirmation chiffrée ou algorithmique a été contrôlée dans les sources ; les points
> non vérifiables sont marqués « ⚠ non vérifié ». Récapitulatif des corrections en fin
> de document.
>
> ⚠️ **Ce que ce document ne décrit plus.** Le module `classical` — son plateau 6×10,
> son provider, son écran, son tutoriel, son écran d'accueil — **n'existe plus**. Le
> 6×10 subsiste, mais comme une **taille de Pentoscope**, pas comme un mode.

## Concept général

Pentapol est un jeu de puzzle basé sur les **pentominos** : 12 pièces géométriques
uniques composées chacune de 5 carrés. L'application repose sur **un seul module de
jeu**, Pentoscope, décliné en tailles de plateau, plus un mode multijoueur qui réutilise
son provider. La mécanique est commune : placement par drag & drop et transformations
isométriques.

---

## Les 12 pièces

| id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| lettre | X | P | T | F | Y | V | U | L | N | Z | W | I |
| orientations | 1 | 8 | 4 | 8 | 8 | 4 | 4 | 8 | 8 | 4 | 4 | 2 |

Somme des orientations = **63**, valeur canonique des pentominos fixes. Le détail de
l'encodage est dans `docs/PIECES_ENCODING.md`.

---

## Modes de jeu

### 1. Pentoscope solo — le module de jeu

Une seule mécanique, deux familles de tailles, énumérées par `PentoscopeSize` :

| famille | tailles | pièces | d'où viennent les solutions |
|---|---|---|---|
| **puzzles** | `size3x5` … `size9x5` (largeur 3 à 5, hauteur 5 à 9) | 3 à 9, **tirées au hasard** parmi les 12 | calculées à la volée par `PentoscopeSolver` |
| **rectangle complet** | `size6x10` — 6 × 10 = 60 cases | les **12**, toujours | **table pré-calculée** : 2339 solutions canoniques dans `assets/data/solutions_6x10_normalisees.bin`, étendues à **9356** en mémoire par les 4 isométries du rectangle |

Le champ `PentoscopeSize.table` (`SolutionTable?`) porte cette distinction : `null` = calcul
à la volée. Il n'est lu qu'**au démarrage du puzzle**, pour choisir la `SolutionSource` qui
répondra ensuite à tout (§ Gestion des solutions).

- **Génération à la demande**, avec garantie d'au moins une solution — **court-circuitée
  pour le 6×10**, dont le tirage est forcé (12 pièces sur 12) et les solutions déjà connues
- **Niveaux de difficulté** (constantes de `PentoscopeGenerator`) :

  | Niveau | Seuil | Méthode |
  |---|---|---|
  | Easy | ≥ **4** solutions | `generateEasy()` |
  | Random | ≥ 1 solution | `generate()` |
  | Hard | ≤ **2** solutions | `generateHard()` |

- **Nouvelle partie** : un dialogue unique porte taille, difficulté et « montrer la
  solution », puis appelle `startPuzzle`. Il a remplacé l'ancien écran de menu le
  2026-08-30 (`bd903a1`)
- **Compteur de solutions** : affiché dans l'AppBar pour les tailles adossées à une table,
  absent sinon ; réglable par `GameSettings.showSolutionCounter`
- **Hint (lampe)** : révèle le placement d'une pièce d'une solution compatible, tirée au
  hasard. Amber si une solution reste possible, **rouge** sinon
- **Note de non-triche** : `calculateNote()` renvoie une note **sur 20**
  - 0 hint → 20/20
  - ≥ (nbPièces − 1) hints → 0/20
  - entre les deux, linéaire : `20 − (nbHints × 20 ~/ maxHints)`

### 2. Mode Multijoueur (Pentoscope MP)

- **Mécanisme** : tous les joueurs reçoivent le même puzzle — même *seed*
  (`DateTime.now().millisecondsSinceEpoch`), mêmes pièces
- **Room** : créée par HTTP POST, rejointe par un code (normalisé en majuscules)
- **Synchronisation** : chaque joueur progresse indépendamment, la progression des
  adversaires est visible en mini-plateau
- **Fin de partie** : déclenchée quand le premier joueur complète le puzzle
- ⚠ non vérifié : le nombre maximum de joueurs par room (aucune constante `maxPlayers`
  trouvée côté client — la limite est probablement côté serveur Cloudflare)

---

## Flux utilisateur

```
Démarrage
  └── main() lance runApp immédiatement
        └── _PentapolAppState.initState amorce solutionsReadyProvider (sans await)
              → chargement des 2339 solutions + expansion ×4 en tâche de fond
        ↓
    PentoscopeGameScreen — écran unique, puzzle 5×5 pré-généré
      ├── ⚙️  Réglages         → SettingsScreen
      ├── ➕  Nouvelle partie   → dialogue taille / difficulté / montrer la solution
      ├── 👥  Multijoueur       → lobby MP
      └── 🔎  Solutions         → navigateur (tailles adossées à une table seulement)
```

> **Il n'y a plus d'écran d'accueil ni de route nommée.** `HomeScreen` a été supprimé le
> 2026-08-30 (`971e8cc`) ; `main.dart` monte `PentoscopeGameScreen` directement. Les
> Réglages, qui n'étaient plus atteignables depuis la suppression du mode classique, le
> sont de nouveau par l'AppBar.

> Le chargement d'une table de solutions est **paresseux et attendu par `startPuzzle`**
> (`pentoscopeSolutionsProvider`, une entrée par `SolutionTable`). Il n'y a pas de garde
> de montage d'écran : la latence au premier démarrage s'est révélée imperceptible au
> test appareil.

### Lobby multijoueur

1. Saisir un pseudo (sauvegardé localement)
2. **Créer** une room → recevoir un code, **ou Rejoindre** avec le code d'un autre joueur
3. Attendre que tous soient prêts
4. Countdown → partie commune

---

## Mécanique de placement

### Drag & drop

1. Toucher une pièce dans le slider
2. Faire glisser vers le plateau
3. Relâcher sur une case valide → la pièce se pose
4. Toucher une pièce déjà posée → elle revient dans le slider

### Mastercase (point d'ancrage)

Chaque pièce a un **point d'ancrage** appelé mastercase :

- pièce du slider : coin supérieur gauche normalisé par défaut
- pièce déjà posée : la cellule cliquée par l'utilisateur

La mastercase détermine comment la pièce suit le doigt pendant le drag. Lors d'une
transformation isométrique elle est **remappée** pour rester cohérente avec la
nouvelle orientation. C'est la raison d'être du champ `orientations` de `Pento`, qui
préserve l'identité des cellules A→E entre orientations.

### Snapping magnétique

Pendant le drag, l'application recalcule en continu les **positions valides** de la
pièce sélectionnée. À proximité d'une position valide, la pièce s'aimante dessus
(preview vert) ; sinon le preview est rouge.

### Validation d'un placement

Un placement est accepté si toutes les cases de la pièce sont dans les limites du
plateau et qu'aucune n'est déjà occupée.

---

## Transformations isométriques

Quatre opérations, appliquées par **table de correspondance** : les orientations
distinctes de chaque pièce sont pré-calculées, jamais recalculées à l'exécution.

| Bouton | Méthode `Pento` | Effet sur (x, y) — repère écran, y vers le bas |
|---|---|---|
| CW | `rotationCW` | `(x, y) → (−y, x)` |
| TW | `rotationTW` | `(x, y) → (y, −x)` |
| H | `symmetryH` | axe **horizontal**, haut ↔ bas : `y → −y` |
| V | `symmetryV` | axe **vertical**, gauche ↔ droite : `x → −x` |

> ⚠️ **Piège de nommage, à connaître avant de toucher à ce code.** Dans
> `pentominos.dart`, les méthodes publiques appellent des helpers privés au nom
> **inversé** :
> ```dart
> int rotationCW(...) => _applyIso(..., _rotate90TWCoords); // (-y, x)
> int rotationTW(...) => _applyIso(..., _rotate90CWCoords); // (y, -x)
> int symmetryH(...)  => _applyIso(..., _flipVCoords);
> int symmetryV(...)  => _applyIso(..., _flipHCoords);
> ```
> L'inversion est délibérée — elle compense le repère écran — mais elle a déjà produit
> des tables de documentation fausses. **Se fier aux noms publics, jamais aux privés.**

En mode **paysage**, les interprétations H et V sont échangées pour rester cohérentes
avec l'orientation visuelle de l'écran. Cette compensation vit **dans le provider**
(`pentoscope_provider.dart`, `applyIsometrySymmetryH/V`, sur `state.viewOrientation`
alimenté par `pentoscope_board`) — et non dans le widget, comme c'était le cas du côté
classique supprimé.

`minIsometriesToReach(startPos, endPos)` calcule par parcours en largeur le nombre
minimal d'isométries entre deux orientations — c'est ce qui alimente le scoring
isométrique du mode duel.

---

## Gestion des solutions — les deux sources

Depuis le 2026-08-29, les réponses « solution » passent toutes par une même interface,
`SolutionSource` (`lib/pentoscope/solution_source.dart`), choisie **une seule fois** dans
`startPuzzle` selon `PentoscopeSize.table` :

| | `TableSolutionSource` | `LiveSolutionSource` |
|---|---|---|
| tailles | rectangle complet (6×10) | puzzles à pièces tirées |
| adossée à | `SolutionMatcher` + le `.bin` | `PentoscopeSolver` |
| `hasSolutionFrom` | compte > 0 | backtracking `canSolveFrom` |
| `countFrom` | le nombre exact | **`null`** — le solveur ne sait pas compter |
| `hintFrom` | une solution compatible **au hasard** | la première solution trouvée |
| `compatibleSolutions` | la liste, pour le navigateur | `const []` |

`countFrom` nullable est ce qui évite un test de taille à chaque site d'appel : l'écran
affiche le compteur quand il y en a un, rien sinon.

### Encodage BigInt

Chaque solution 6×10 est encodée en un entier de **360 bits** : 60 cases × 6 bits,
chaque groupe de 6 bits portant le code unique (`bit6`) de la pièce occupant la case.

Le format ne dépend **pas** de la forme du rectangle — 60 cases × 6 bits = 45 octets,
que le plateau soit 6×10 ou 3×20. C'est ce qui rendra les tables 5×12 et 4×15 possibles
sans toucher au chargeur (`docs/PLAN_6X10_DANS_PENTOSCOPE.md` §5).

### Matching en temps réel

L'état du plateau est converti en **deux** BigInt :

```
pieces = codes bit6 des cases occupées, 0 ailleurs
mask   = 0x3F sur les cases occupées, 0 ailleurs
compatible ⟺ (solution & mask) == pieces
```

Le masque est ce qui rend le test valable sur un plateau **partiel** : il efface de la
solution toute case que le joueur n'a pas remplie.

`TableSolutionSource` **balaie linéairement les 9356 solutions**. Elle ne raisonne pas sur
les pièces restantes ni sur la forme des zones libres : elle compare des cases occupées.
Un compte de 0 signifie « aucune solution connue ne contient ce placement », donc impasse.
Exemple mesuré : plateau vide 9356 → une pièce X posée 442 → une pièce I ajoutée 82.

> **Pourquoi « compte > 0 » suffit à répondre « une solution est-elle encore
> possible ? »** — parce que sur un rectangle complet, **chacune des 9356 solutions emploie
> les 12 pièces**. L'équivalence ne vaut que là : sur un puzzle à pièces tirées, la table
> ne dit rien, d'où `LiveSolutionSource`.

> **Deux invariants** sans lesquels la table répondrait faux en silence : aucune case
> masquée (`-1`), et les 12 pièces toutes présentes.

---

## Gestion des solutions (mode Pentoscope)

`PentoscopeSolver` — backtracking optimisé par trois heuristiques :

1. **Smallest Free Cell First** — cible toujours la case libre d'index le plus petit
2. **Isolated Region Pruning** — coupe les branches menant à une zone impossible à remplir
3. **Piece Ordering** — essaie d'abord les pièces au plus petit nombre d'orientations

Deux modes d'appel :

- `findFirstSolution()` — s'arrête à la première solution
- `findAllSolutions(timeout: 2 s)` — collecte jusqu'au **timeout de 2 secondes**,
  valeur utilisée par les quatre points d'appel du générateur

---

## Persistance

Base **drift** (`lib/database/settings_database.dart`), trois tables — dont **deux sont
mortes** :

> ⚠️ Depuis la suppression du mode classique, **plus aucun code n'écrit dans
> `GameSessions` ni `SolutionStats`** : l'écriture vivait dans `onPuzzleCompleted` du
> provider classique. Leur suppression est décidée (décision 32, plan §9) et non encore
> appliquée. Seule `Settings` est vivante.

| Table | Contenu |
|---|---|
| `Settings` | couples clé/valeur textuels — réglages de l'application |
| `GameSessions` | une ligne par partie : `solutionNumber`, `elapsedSeconds`, `score`, `piecesPlaced`, `numUndos`, `isometriesCount`, `solutionsViewCount`, `playerNotes` |
| `SolutionStats` | une ligne par solution jouée : `timesPlayed`, `bestTime`, `averageTime`, `bestScore` |

`SolutionStats` permettait de suivre, solution par solution parmi les 9356, combien de fois
elle avait été résolue et le meilleur temps obtenu. Le pseudo multijoueur est stocké à part,
via `SharedPreferences`.

> ⚠️ **Correction du 2026-08-30** — cette dernière phrase était fausse, et elle l'était déjà
> dans la version précédente de ce document. Le pseudo multijoueur n'est **pas** dans
> `SharedPreferences` : il vit dans `DuelSettings.playerName`, donc dans le JSON `app_settings`
> de la table `Settings`, comme le reste des réglages.
>
> Le **seul** usage de `SharedPreferences` dans tout `lib/` est
> `pentoscope_last_completed`, écrit par `_saveCompletedLevel` (`pentoscope_provider.dart`
> l.680-690) — et **jamais relu** : aucun `getString` nulle part. C'est une donnée en
> écriture seule.

> Le projet n'a **jamais migré** : `schemaVersion => 1`, aucune `MigrationStrategy`. La
> suppression des deux tables sera sa première migration.

---

## Modèles de données principaux

### `Pento`

```
id              : 1–12
numOrientations : 1–8 selon la symétrie propre de la pièce
baseShape       : 5 numéros de cases sur la grille de référence 5×5
orientations    : liste des formes, ordre des cellules stable (tracking mastercase)
cartesianCoords : coordonnées (x, y) normalisées de chaque orientation
bit6            : code 6 bits unique, pour l'encodage BigInt
```

### `Plateau`

```
width, height : dimensions
grid          : tableau 2D
                -1 = case masquée (non jouable) — également renvoyé hors limites
                 0 = case libre
              1–12 = id de la pièce occupante
```

### `PlacedPiece`

```
piece           : référence Pento
positionIndex   : index d'orientation (0..numOrientations-1)
gridX, gridY    : ancre sur le plateau
isometriesUsed  : nombre d'isométries appliquées (scoring du mode duel)
absoluteCells   : cases absolues occupées (calculées à la demande)
```

> Terminologie : `positionIndex` désigne une **orientation**, pas une position. La
> position est `(gridX, gridY)`. Les deux sens cohabitent dans le même objet.

---

## Architecture technique

```
lib/
  common/                  Pento, Plateau, PlacedPiece, mixins, API de symétrie,
                           widgets partagés (PieceRenderer, DraggablePieceWidget…)
  config/                  dimensions UI, icônes
  data/                    documentation backend (pas de code Dart)
  database/                drift — réglages (+ 2 tables mortes, cf. Persistance)
  debug/                   database_debug_screen — orphelin depuis la suppression
                           de l'écran d'accueil
  l10n/                    localisation
  models/                  app_settings
  pentoscope/              LE module de jeu : provider, plateau, barre, écrans,
                           générateur, solveur, SolutionSource
  pentoscope_multiplayer/  mode duel WebSocket
  providers/               providers Riverpod transverses (réglages)
  screens/                 settings_screen, custom_colors_screen
  services/                chargeur .bin, matcher de solutions, solveur hors-ligne
  utils/                   géométrie, helpers, export
```

**19 415 lignes de Dart** au 2026-08-30, contre 23 036 avant la suppression du mode
classique.

### State management — Riverpod

| Provider | Rôle |
|---|---|
| `pentoscopeProvider` | état du jeu — **le seul provider de jeu** |
| `pentoscopeMPProvider` | état multijoueur WebSocket |
| `settingsProvider` | réglages persistants (drift) |
| `settingsDatabaseProvider` | instance drift |
| `pentoscopeSolutionsProvider` | `FutureProvider.family<SolutionMatcher, SolutionTable>` — chargement paresseux d'une table, une entrée par table |

> `solutionsReadyProvider` et le singleton global `solutionMatcher` ont été **supprimés**
> avec le mode classique : chaque table a désormais son instance, dimensionnée par elle.

### Backend multijoueur

- **Serveur** : Cloudflare Workers + Durable Objects
- **Protocole** : WebSocket, messages JSON typés
- **Heartbeat** : ping toutes les **30 secondes** (`Timer.periodic`)
- **Timeout d'établissement** : **10 secondes** sur `_channel.ready`
- **Rooms** : création HTTP POST, jointure par code, diffusion par WebSocket

---

## Écrans

| Écran | Rôle |
|---|---|
| `pentoscope/screens/pentoscope_game_screen.dart` | **l'écran unique** : gameplay, AppBar, dialogue « Nouvelle partie », bilan |
| `pentoscope/screens/solutions_browser_screen.dart` | parcourir les solutions compatibles (tailles à table) |
| `pentoscope_multiplayer/screens/pentoscope_mp_lobby_screen.dart` | création/jointure de room |
| `pentoscope_multiplayer/screens/pentoscope_mp_game_screen.dart` | gameplay multijoueur |
| `pentoscope_multiplayer/screens/pentoscope_mp_result_screen.dart` | classement final |
| `screens/settings_screen.dart` | configuration |
| `screens/custom_colors_screen.dart` | couleurs des pièces (depuis les Réglages) |
| `debug/database_debug_screen.dart` | **orphelin** — plus aucun écran n'y mène |

> Supprimés le 2026-08-29/30 : `home_screen.dart`, `pentoscope_menu_screen.dart`,
> `pentomino_game_screen.dart` et tout `lib/screens/pentomino_game/`.

---

## Code présent mais inactif

Utile à savoir avant de partir sur une fausse piste :

Vérifié au `grep` le 2026-08-30 — aucun de ces fichiers n'est importé hors de lui-même :

| Fichier | Statut |
|---|---|
| `common/bigint_plateau.dart` | orphelin, **et la meilleure des implémentations** du couple (pieces, mask). À faire adopter, pas à supprimer |
| `common/shape_recognizer.dart` | orphelin |
| `config/ui_layout_provider.dart` | orphelin — ses **9** providers (`uiLayoutProvider`, `isLandscapeProvider`, `boardDimensionsProvider`…) ne sont utilisés nulle part |
| `utils/solution_collector.dart` | orphelin |
| `services/pentomino_solver.dart` | atteint uniquement via `solution_collector`, lui-même orphelin → **inactif dans l'app** ; ne sert qu'à l'outil hors-ligne `tools/generate_6x10_solutions.dart` |

> `common/isometry_transforms.dart` et `common/isometry_transformation_service.dart`,
> listés ici dans la version précédente, ont depuis été **supprimés**.

> ⚠️ `services/pentomino_solver.dart` porte un défaut à corriger avant toute génération de
> nouvelle table : `maxSeconds = 30` n'est pas paramétrable et une troncature par timeout
> est **invisible** pour l'appelant. C'est ce qui a produit un fichier de solutions brutes
> incomplet (8175 sur 9356) sans que rien ne le signale.
> → `docs/PLAN_6X10_DANS_PENTOSCOPE.md` §5.1.

---

## Corrections apportées le 2026-08-30

| Point | Version précédente | Réalité du code |
|---|---|---|
| **Modes de jeu** | trois modes, dont « Mode Classique » | **deux** : Pentoscope solo (toutes tailles) et multijoueur. Le module `classical` est supprimé ; le 6×10 est une **taille**, pas un mode |
| Flux utilisateur | `HomeScreen` → Classique / Pentoscope / Réglages | plus d'écran d'accueil : `main.dart` monte `PentoscopeGameScreen` ; Réglages dans l'AppBar |
| Gestion des solutions | deux sections séparées, « mode classique » et « mode Pentoscope » | **une** interface `SolutionSource`, deux implémentations, choisie une fois dans `startPuzzle` |
| `PlateauSolutionCounter` | décrit comme le compteur | **fichier supprimé** ; le masque est construit par `TableSolutionSource._mask` |
| `solutionsReadyProvider`, singleton `solutionMatcher` | providers actifs | **supprimés** ; remplacés par `pentoscopeSolutionsProvider`, famille indexée par table |
| Persistance | trois tables actives | `GameSessions` et `SolutionStats` n'ont **plus aucun écrivain** ; suppression décidée (plan §9) |
| Scoring | `calculateScore` du mode classique | supprimé avec lui ; seule `calculateNote()` (sur 20) subsiste |
| Compensation paysage H/V | située dans `pentomino_game_provider.dart` | dans `pentoscope_provider.dart`, sur `state.viewOrientation` |
| Code inactif | 5 fichiers, dont 2 depuis supprimés | 5 fichiers, liste re-vérifiée au `grep` |
| Écrans | 9, dont 3 supprimés depuis | 8, chemins complets |

---

## Corrections apportées le 2026-08-27

| Point | Version précédente | Réalité du code |
|---|---|---|
| **Table des isométries** | les 4 lignes fausses, CW↔TW et H↔V inversés | corrigée et vérifiée ci-dessus |
| Chargement au démarrage | « pré-chargement en arrière-plan » | `solutionsReadyProvider` + garde sur l'écran classique |
| Solutions | « 9356 pré-calculées chargées » | 2339 canoniques dans le `.bin`, étendues à 9356 en mémoire |
| `PlateauSolutionCounter` | « tient compte des pièces restantes et des cases libres » | balayage linéaire par masque binaire, rien d'autre |
| `uiLayoutProvider` | listé comme provider actif | fichier orphelin, jamais utilisé |
| Note de non-triche | absente | `calculateNote()`, 0–20 selon le nombre de hints |
| Persistance | absente | 3 tables drift, dont les statistiques par solution |
| `Plateau` `-1` | « case invalide (hors limites) » | case **masquée**, et valeur renvoyée hors limites |
| Code inactif | absent | 5 fichiers listés ci-dessus |
