# Pentapol — Documentation fonctionnelle

> **Vérifiée contre le code le 2026-08-27.** Chaque affirmation chiffrée ou
> algorithmique de ce document a été contrôlée dans les sources. Les points que je
> n'ai pas pu vérifier sont marqués « ⚠ non vérifié ». Le récapitulatif des
> corrections apportées à la version précédente est en fin de document.

## Concept général

Pentapol est un jeu de puzzle basé sur les **pentominos** : 12 pièces géométriques
uniques composées chacune de 5 carrés. L'application propose trois modes de jeu, du
classique solitaire au multijoueur en ligne, avec une mécanique commune de placement
par drag & drop et de transformations isométriques.

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

### 1. Mode Classique

- **Plateau** : 6 × 10 = 60 cases
- **Pièces** : les 12 pentominos
- **Objectif** : remplir complètement le plateau
- **Solutions connues** : **2339 solutions canoniques** chargées depuis
  `assets/data/solutions_6x10_normalisees.bin`, étendues à **9356** en mémoire par
  les 4 isométries du rectangle (identité, rotation 180°, miroir H, miroir V)
- **Scoring** : `100 - (secondes ~/ 2)`, borné entre 0 et 100
  (`PentominoGameNotifier.calculateScore`)

### 2. Mode Pentoscope (speed puzzle)

- **Plateau** : hauteur fixe 5, largeur 3 à 10 → **3 à 10 pièces**
  (enum `PentoscopeSize`, de `size3x5` à `size10x5`)
- **Pièces** : sélection aléatoire parmi les 12
- **Génération à la demande**, avec garantie d'au moins une solution
- **Niveaux de difficulté** (constantes de `PentoscopeGenerator`) :

  | Niveau | Seuil | Méthode |
  |---|---|---|
  | Easy | ≥ **4** solutions | `generateEasy()` |
  | Random | ≥ 1 solution | `generate()` |
  | Hard | ≤ **2** solutions | `generateHard()` |

- **Hint (lampe)** : révèle le placement d'une pièce de la solution
- **Note de non-triche** : `calculateNote()` renvoie une note **sur 20**, distincte du
  score temporel du mode classique
  - 0 hint → 20/20
  - ≥ (nbPièces − 1) hints → 0/20
  - entre les deux, linéaire : `20 − (nbHints × 20 ~/ maxHints)`

### 3. Mode Multijoueur (Pentoscope MP)

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
    PentoscopeGameScreen (écran d'accueil effectif, puzzle 5×5 pré-généré)
      ├── Pentoscope (speed) → menu taille/difficulté → jeu solo OU lobby MP
      ├── Classique → PentominoGameScreen
      │     └── GARDE : affiche un loader tant que solutionsReadyProvider
      │        n'a pas résolu ; écran d'erreur + « Réessayer » en cas d'échec
      └── Réglages
```

> Le mode classique **ne peut plus démarrer** avant que les solutions soient
> disponibles. Auparavant, un chargement en `Future.microtask` non attendu laissait
> le compteur de solutions disparaître silencieusement de l'interface.

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
avec l'orientation visuelle de l'écran (`pentomino_game_provider.dart`, commentaires
« H/V swap en paysage »).

`minIsometriesToReach(startPos, endPos)` calcule par parcours en largeur le nombre
minimal d'isométries entre deux orientations — c'est ce qui alimente le scoring
isométrique du mode duel.

---

## Gestion des solutions (mode classique)

### Encodage BigInt

Chaque solution 6×10 est encodée en un entier de **360 bits** : 60 cases × 6 bits,
chaque groupe de 6 bits portant le code unique (`bit6`) de la pièce occupant la case.

### Matching en temps réel

L'état du plateau est converti en **deux** BigInt :

```
pieces = codes bit6 des cases occupées, 0 ailleurs
mask   = 0x3F sur les cases occupées, 0 ailleurs
compatible ⟺ (solution & mask) == pieces
```

Le masque est ce qui rend le test valable sur un plateau **partiel** : il efface de la
solution toute case que le joueur n'a pas remplie.

Le nombre de solutions compatibles restantes est affiché en permanence. Exemple mesuré :
plateau vide 9356 → une pièce X posée 442 → une pièce I ajoutée 82.

### Ce que `PlateauSolutionCounter` fait — et ne fait pas

L'extension `PlateauSolutionCounter` sur `Plateau` construit les deux masques puis
**balaie linéairement les 9356 solutions**. Elle ne raisonne pas sur les pièces
restantes ni sur la forme des zones libres : elle compare des cases occupées. Un
compte de 0 signifie « aucune solution connue ne contient ce placement », donc impasse.

Méthodes : `countPossibleSolutions()`, `getCompatibleSolutionsBigInt()`,
`getCompatibleSolutionIndices()`, `findExactSolutionIndex()`.

> Limite connue : le masque ne sait pas traiter les cases masquées (`-1`). Le mode
> classique n'utilise que des plateaux entièrement visibles, donc le défaut est latent.

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

Base **drift** (`lib/database/settings_database.dart`), trois tables :

| Table | Contenu |
|---|---|
| `Settings` | couples clé/valeur textuels — réglages de l'application |
| `GameSessions` | une ligne par partie : `solutionNumber`, `elapsedSeconds`, `score`, `piecesPlaced`, `numUndos`, `isometriesCount`, `solutionsViewCount`, `playerNotes` |
| `SolutionStats` | une ligne par solution jouée : `timesPlayed`, `bestTime`, `averageTime`, `bestScore` |

`SolutionStats` permet de suivre, solution par solution parmi les 9356, combien de fois
elle a été résolue et le meilleur temps obtenu. Le pseudo multijoueur est stocké à part,
via `SharedPreferences`.

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
  classical/               jeu classique 6×10
  common/                  Pento, Plateau, PlacedPiece, mixin, API de symétrie
  config/                  dimensions UI, icônes
  data/                    documentation backend (pas de code Dart)
  database/                drift — réglages, sessions, statistiques
  debug/                   outils de mise au point
  l10n/                    localisation
  models/                  app_settings
  pentoscope/              mode Pentoscope solo
  pentoscope_multiplayer/  mode duel WebSocket
  providers/               providers Riverpod transverses
  screens/                 écrans et widgets partagés
  services/                chargeur, matcher, compteur, solveur
  utils/                   géométrie, helpers
```

### State management — Riverpod

| Provider | Rôle |
|---|---|
| `pentominoGameProvider` | état du jeu classique (`Notifier`, synchrone) |
| `pentoscopeProvider` | état du jeu Pentoscope solo |
| `pentoscopeMPProvider` | état multijoueur WebSocket |
| `settingsProvider` | réglages persistants (drift) |
| `solutionsReadyProvider` | chargement des solutions (`FutureProvider<int>`) |

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
| `home_screen.dart` | menu principal |
| `pentoscope_menu_screen.dart` | choix taille, difficulté, solo/MP |
| `pentoscope_game_screen.dart` | gameplay Pentoscope solo |
| `pentoscope_mp_lobby_screen.dart` | création/jointure de room |
| `pentoscope_mp_game_screen.dart` | gameplay multijoueur |
| `pentoscope_mp_result_screen.dart` | classement final |
| `pentomino_game_screen.dart` | garde d'initialisation + gameplay 6×10 |
| `solutions_browser_screen.dart` | parcourir les solutions compatibles |
| `settings_screen.dart` | configuration |

---

## Code présent mais inactif

Utile à savoir avant de partir sur une fausse piste :

| Fichier | Statut |
|---|---|
| `common/isometry_transforms.dart` | importé seulement par `isometry_transformation_service.dart` |
| `common/isometry_transformation_service.dart` | **importé par personne** — le couple est mort |
| `common/bigint_plateau.dart` | orphelin, mais meilleur que le code qui le remplace |
| `config/ui_layout_provider.dart` | orphelin — `uiLayoutProvider` n'est utilisé nulle part |
| `services/pentomino_solver.dart` | atteint uniquement via `utils/solution_collector.dart`, lui-même orphelin → **inactif dans l'app** ; ne sert qu'à l'outil hors-ligne `tools/generate_6x10_solutions.dart` |

`isometry_transforms.dart` implémente une rotation **opposée** à celle du chemin vivant
(`(x,y) → (−y, x)` contre le `rotateAroundPoint` inverse). C'est sans effet puisque le
fichier est mort, mais c'est une source de confusion à la lecture.

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
