# Analyse — stockage des positions (encodage plateau / solutions)

> Périmètre : encodage des plateaux et des solutions 6×10 (fichiers `.bin`, `bit6`,
> `BigInt` 360 bits, `PlateauCompressor`). Hors périmètre : table statique
> `pentominos.dart`, `PlacedPiece`, persistance drift/SharedPreferences.
>
> Méthode : lecture du code, puis **vérification par exécution** sur les fichiers
> binaires réels. Les résultats chiffrés ci-dessous sont mesurés, pas déduits.

---

## 1. Vue d'ensemble : trois encodages coexistent

| # | Schéma | Largeur | Support | Fichier source | État |
|---|--------|---------|---------|----------------|------|
| A | `bit6` empaqueté | 6 bits/case | 45 octets/solution | `assets/data/solutions_6x10_normalisees.bin` | **vivant** |
| B | `bit6` en `BigInt` | 6 bits/case | `BigInt` 360 bits | mémoire (`SolutionMatcher`) | **vivant** |
| C | `id` de pièce | 4 bits/case | `List<int>` 8×int32 | `assets/solutions_canonical.bin` | ~~mort + cassé~~ **supprimé 27/08/2026** |

A et B sont le même encodage sous deux formes (fichier ↔ mémoire). C est un schéma
indépendant, incompatible, et non fonctionnel.

### Le pipeline vivant

```
solutions_6x10_normalisees.bin   105 255 o = 2339 × 45 o
        │  pentapol_solutions_loader.dart  (dépaquetage 6 bits, MSB first)
        ▼
List<BigInt>  2339 canoniques
        │  SolutionMatcher.initWithBigIntSolutions()
        │  expansion ×4 : identité, rot180, miroirH, miroirV
        ▼
List<BigInt>  9356 solutions          index = canoniqueIdx × 4 + variante
        │  countCompatibleFromBigInts(pieces, mask)
        ▼
(solution & mask) == pieces
```

Le masque de requête est construit à part, dans l'extension
`PlateauSolutionCounter._toBigIntMask()` (`lib/services/plateau_solution_counter.dart`).

---

## 2. Vérifications exécutées

Décodage indépendant des deux `.bin` (script Python, convention MSB-first, 45 o/solution) :

| Vérification | Résultat |
|---|---|
| `normalisees.bin` : nombre de solutions | **2339** (attendu : 2339) |
| `normalisees.bin` : solutions distinctes | 2339 — aucun doublon |
| `normalisees.bin` : codes `bit6` valides | 100 % dans {7,11,13,14,19,21,22,25,35,37,41,49} |
| `normalisees.bin` : répartition par solution | 12 pièces × 5 cases, sans exception |
| Expansion ×4 → solutions distinctes | **9356**, **0 collision** |
| Solutions à stabilisateur non trivial | **0** |
| `tools/solutions_6x10_brutes.bin` (avant suppression) | **8175** solutions, pas 9356 — sous-ensemble strict des 9356 |

**Conclusion factuelle : le cœur du schéma A/B est correct.** L'encodage 6 bits, le
dépaquetage, l'expansion ×4 et la formule `(solution & mask) == pieces` sont sains.
Le nombre 9356 = 4 × 2339 est exact précisément parce qu'aucune solution du 6×10
n'est symétrique — ce que la mesure confirme (stabilisateur trivial partout).

Le reste de ce document porte sur ce qui entoure ce cœur.

---

## 3. Défauts constatés

### B1 — `PlateauCompressor.rotate90()` détruisait silencieusement le plateau — ✅ CLOS (fichier supprimé le 27/08/2026)

`lib/utils/plateau_compressor.dart` :

```dart
final newX = 9 - y;   // ∈ [0,9]
final newY = x;
rotated.setCell(newX, newY, value);   // rotated fait 6 de large
```

Une rotation 90° d'un 6×10 donne un 10×6. Le code écrit dans un `Plateau.allVisible(6, 10)`,
et `setCell` **ignore silencieusement** tout ce qui sort des bornes (`isInBounds`).

Mesuré par simulation fidèle de la fonction :

- `rotate90` : **24 cases sur 60 perdues**, 36 conservées
- `rotate180` (= `rotate90 ∘ rotate90`) : **12 cases sur 60 conservées**
- `rotate270`, `findCanonical`, `areEquivalent` : faux par construction

Ce n'est pas un cas limite, c'est le chemin nominal. Aucune exception n'est levée.

### B2 — `SolutionDatabase` chargeait un asset inexistant — ✅ CLOS (fichier supprimé le 27/08/2026)

`lib/data/solution_database.dart` lit `assets/solutions_canonical.bin`. Or :

- le fichier n'existe pas dans `assets/` (seul `assets/data/solutions_6x10_normalisees.bin` y est) ;
- il n'est pas déclaré dans `pubspec.yaml` (une seule entrée sous `assets:`) ;
- l'outil mentionné dans le message d'erreur, `tools/generate_canonical_solutions.dart`, n'existe pas non plus.

`init()` attrape l'exception, positionne `_allSolutions = []` **et** `_isInitialized = true`.
La base est donc « initialisée » avec zéro solution, sans erreur remontée.
Son seul consommateur, `screens/solutions_viewer_screen.dart`, est un fichier orphelin
(confirmé par `tools/csv/pentapol_orphan_files.csv`).

### B3 — Course au démarrage sur le chargement des solutions — ✅ CORRIGÉ le 27/08/2026

`lib/main.dart` :

```dart
Future.microtask(() async {
  final solutionsBigInt = await loadNormalizedSolutionsAsBigInt();
  solutionMatcher.initWithBigIntSolutions(solutionsBigInt);
});
runApp(const ProviderScope(child: PentapolApp()));
```

Le chargement n'est ni attendu ni exposé comme état. `PentominoGameProvider` appelle
`countPossibleSolutions()` dès l'initialisation (l. 166 et 837). Si l'utilisateur atteint
le mode classique avant la fin du chargement, `SolutionMatcher` lève `StateError`,
`plateau_solution_counter` l'attrape, `print` en console et retourne `null` → le
compteur de solutions disparaît de l'UI sans message.

Fenêtre de risque : la durée d'`initWithBigIntSolutions` (voir §4). **Hypothèse**, pas
fait mesuré : sur mobile bas de gamme cette fenêtre est probablement de l'ordre de la
seconde. En pratique il faut au moins une navigation — donc un geste humain, > 500 ms —
pour atteindre le mode classique, ce qui rendait la course peu probable sans la rendre
impossible.

> **Correction appliquée le 27/08/2026 — garde d'initialisation.**
>
> | Fichier | Changement |
> |---|---|
> | `lib/providers/solutions_provider.dart` | **nouveau** — `solutionsReadyProvider`, un `FutureProvider<int>` qui charge le `.bin` et initialise `solutionMatcher`. Résultat mis en cache, non `autoDispose`. |
> | `lib/main.dart` | le `Future.microtask` non attendu disparaît ; le chargement est **amorcé sans attente** depuis `initState` par `ref.read(solutionsReadyProvider)`. |
> | `lib/classical/pentomino_game_screen.dart` | `PentominoGameScreen` devient une **garde** (`ConsumerWidget`) qui observe le provider ; le jeu, renommé `_PentominoGameBody`, n'est monté que sur `data`. |
>
> Pourquoi la garde est sur l'écran et non sur le provider de jeu : c'est le point
> d'entrée **unique** du mode classique (les 4 chemins de navigation y passent), et cela
> laisse `pentominoGameProvider` synchrone — ses 14 points d'appel dans 5 fichiers ne
> bougent pas. Passer le notifier en `AsyncNotifier` aurait changé son type public et
> cassé tous les `ref.watch`.
>
> La garde devait porter sur le **montage** et non sur le seul `build` : l'`initState` de
> l'écran appelle `notifier.reset()`, qui appelle `countPossibleSolutions()`. D'où le
> découpage en deux widgets — l'`initState` du corps ne s'exécute qu'une fois la garde
> franchie.
>
> Bénéfice annexe : l'échec de chargement n'est plus silencieux. Il affiche un écran
> d'erreur avec le message et un bouton **Réessayer**
> (`ref.invalidate(solutionsReadyProvider)`), là où l'ancien code se contentait d'un
> `debugPrint` invisible en production.
>
> Pentoscope n'est pas ralenti : il utilise `PentoscopeSolver` et n'attend pas ce
> chargement.
>
> **Validé le 27/08/2026** : `flutter analyze` et exécution sur appareil OK, mode classique
> fonctionnel, compteur de solutions correct.

### B4 — Le masque de requête casse sur les cases cachées

`_toBigIntMask()` traite `cellValue == 0` (vide) et 1..12 (pièce), mais `Plateau.getCell`
retourne **`-1`** pour une case cachée ou hors bornes (`Plateau.empty` initialise à `-1`).
Un `-1` tombe dans `bit6ById[-1] → null → StateError`, attrapé, retour `null`.

En pratique le mode classique n'utilise que `Plateau.allVisible`, donc le bug est
latent. Mais le contrat de `Plateau` autorise `-1` et Pentoscope repose sur des cases
masquées : toute réutilisation du compteur dans ce contexte échouera silencieusement.

### B5 — `positionIndex` retombe à 0 sans erreur

`SolutionMatcher.solutionToPlacedPieces()` initialise `int positionIndex = 0` puis
cherche l'orientation correspondante dans `cartesianCoords`. Si aucune ne correspond,
la pièce est reconstruite avec l'orientation 0 — c'est-à-dire une **forme différente**
de celle de la solution. Un `throw` ou un retour `null` serait préférable à une pièce
silencieusement fausse.

---

## 4. Dette structurelle

### D1 — Trois représentations, dont une réimplémentation redondante

`lib/common/bigint_plateau.dart` définit `BigIntPlateau { BigInt pieces; BigInt mask; }`
avec `placePiece`, `clearCells`, `getCell` — c'est exactement l'abstraction dont le
compteur a besoin. **Ce fichier est orphelin** : aucun import dans tout `lib/`.

`plateau_solution_counter.dart` en refait une version dégradée (`_PlateauBigIntMask`,
privée, reconstruite intégralement à chaque appel en repartant de la grille `List<List<int>>`).

Résultat : la même paire (pieces, mask) est décrite à deux endroits, l'un mort, l'autre
utilisé, avec des conventions à re-vérifier à la main de chaque côté.

### D2 — Les tables de lettres sont fausses dans les *deux* documents

`docs/PIECES_ENCODING.md` et l'en-tête de `lib/services/solution_matcher.dart` donnent
deux correspondances `id → lettre` **différentes**, et **aucune des deux n'est correcte**.

Table reconstruite depuis les `baseShape` réels de `pentominos.dart`, contrôlée par le
nombre d'orientations fixes (la somme fait 63, valeur canonique pour les 12 pentominos) :

| id | `bit6` | Forme (depuis `baseShape`) | Lettre réelle | `numOrientations` | `PIECES_ENCODING.md` | `solution_matcher.dart` |
|----|--------|---------------------------|---------------|-------------------|----------------------|-------------------------|
| 1  | 7  | `.# / ### / .#`      | **X** | 1 | X ✅ | X ✅ |
| 2  | 11 | `## / ## / .#`       | **P** | 8 | F ❌ | F ❌ |
| 3  | 19 | `..# / ### / ..#`    | **T** | 4 | T ✅ | T ✅ |
| 4  | 35 | `.## / ##. / .#.`    | **F** | 8 | Y ❌ | W ❌ |
| 5  | 13 | `.# / .# / ## / .#`  | **Y** | 8 | V ❌ | Z ❌ |
| 6  | 21 | `..# / ..# / ###`    | **V** | 4 | U ❌ | U ❌ |
| 7  | 37 | `#.# / ###`          | **U** | 4 | Z ❌ | V ❌ |
| 8  | 25 | `...# / ####`        | **L** | 8 | L ✅ | Y ❌ |
| 9  | 41 | `..## / ###.`        | **N** | 8 | N ✅ | N ✅ |
| 10 | 49 | `..# / ### / #..`    | **Z** | 4 | W ❌ | P ❌ |
| 11 | 14 | `..# / .## / ##.`    | **W** | 4 | S/Z2 ❌ | L ❌ |
| 12 | 22 | `# / # / # / # / #`  | **I** | 2 | I ✅ | I ✅ |

Somme des orientations : 1+8+4+8+8+4+4+8+8+4+4+2 = **63** ✅ (les 12 pentominos libres
donnent bien 63 pentominos fixes — la table est donc cohérente).

Aucun impact fonctionnel : le code ne manipule que des `id` et des `bit6`. Impact réel
sur la relecture humaine, le débogage et toute discussion sur le jeu.

Indice révélateur : le jeu des 12 lettres de `PIECES_ENCODING.md` n'était **pas** un jeu
valide de pentominos — il omettait **P** et comptait deux fois la même pièce sous deux
noms (`Z` et `S/Z2`). Celui de `solution_matcher.dart` est un jeu valide, mais mal
affecté aux `id`.

> **Statut :** corrigé le 27/08/2026 dans `docs/PIECES_ENCODING.md` **et** dans l'en-tête
> de `lib/services/solution_matcher.dart` (commentaires uniquement, aucun code touché).
> Les deux tables concordent désormais et forment un jeu valide des 12 pentominos.

### D3 — `tools/solutions_6x10_brutes.bin` était un artefact périmé — **supprimé**

8175 solutions au lieu de 9356 (mesuré). `normalisees.bin` date du 14/11/2025, `brutes.bin`
du 13/12/2025 : le second est **postérieur** au premier, ce ne sont donc pas deux sorties
du même `main()`.

Vérification faite avant suppression — les 8175 comparés aux 9356 reconstruits depuis
`normalisees.bin` :

| Contrôle | Résultat |
|---|---|
| Solutions de `brutes.bin` présentes dans les 9356 | **8175 / 8175** |
| Solutions absentes des 9356 | **0** |
| Classes canoniques couvertes | **2339 / 2339** |
| Solutions des 9356 manquantes dans `brutes.bin` | 1181 |

Conclusion : `brutes.bin` était un **sous-ensemble strict** du référentiel, sans aucune
solution étrangère. Le fichier vivant `normalisees.bin` est bien la référence complète —
ce contrôle le confirme dans les deux sens.

Le fichier était par ailleurs **redondant** : les 9356 se dérivent des 2339 canoniques par
une expansion déterministe de quelques millisecondes (`initWithBigIntSolutions`). Aucune
raison de stocker 367 Ko pour un ensemble incomplet et recalculable.

> **Statut : supprimé le 27/08/2026** (`git rm`). Le fichier reste dans l'historique git
> (commit initial `3b1c917`) — restaurable par
> `git checkout 3b1c917 -- tools/solutions_6x10_brutes.bin`.

**Piste ouverte, non résolue.** On ignore pourquoi ce fichier ne contenait que 87 % des
solutions. Deux hypothèses non départagées : run interrompu, ou défaut de complétude de
`PentominoSolver.findAllSolutions` (`lib/services/pentomino_solver.dart`). Enjeu limité :
ce solveur n'est utilisé que par l'outil hors-ligne `tools/generate_6x10_solutions.dart`.
Pentoscope utilise une classe distincte, `PentoscopeSolver`
(`lib/pentoscope/pentoscope_solver.dart`), non concernée. À vérifier si l'on doit un jour
régénérer les solutions.

### D4 — Conventions d'axes contradictoires dans la documentation

`docs/PIECES_ENCODING.md` décrit la grille 5×5 comme numérotée **depuis le bas gauche**
(« case 1 en bas à gauche »), puis, plus loin, le plateau 6×10 comme
`index = y*6 + x` avec « case index 0 (x=0, y=0, **haut gauche**) ».

Le code utilise partout la convention écran (y vers le bas) : `PlacedPiece.absoluteCells`
calcule `localY = (cellNum - 1) ~/ 5` et l'ajoute à `gridY`. Donc les cases 1–5 sont la
ligne du **haut**, pas du bas. Le premier paragraphe du document était faux.

Vérification mécanique sur les 63 orientations de `pentominos.dart` — on convertit chaque
`orientations[i]` en (x, y) et on compare aux `cartesianCoords[i]` correspondants :

| Hypothèse | Conversion | Orientations reproduites |
|---|---|---|
| Case 1 en **haut** à gauche | `y = (c−1) ~/ 5` | **63 / 63** |
| Case 1 en bas à gauche (doc d'origine) | `y = 4 − (c−1) ~/ 5` | **1 / 63** |

Le seul cas compatible avec les deux est la pièce X, symétrique. Le verdict est sans
ambiguïté.

> **Statut :** corrigé le 27/08/2026 dans `docs/PIECES_ENCODING.md` — schéma de la grille
> 5×5, phrase de convention, commentaires d'orientation de la pièce I et son schéma
> horizontal (qui était retourné).

### D5 — L'expansion ×4 en mémoire n'est pas nécessaire

`initWithBigIntSolutions` matérialise 9356 `BigInt` à partir de 2339. Les 3 variantes
sont des permutations déterministes des 60 cases. On peut à la place **transformer la
requête** (`pieces`, `mask`) selon les 4 isométries et comparer contre les 2339
canoniques : même nombre de comparaisons, mémoire divisée par 4, et l'index absolu
`canonique × 4 + variante` reste calculable à l'identique.

---

## 5. Coût du schéma actuel

**Faits** (comptage d'opérations, pas de mesure de temps) :

| Phase | Opérations `BigInt` |
|---|---|
| Décodage des 2339 canoniques | 2339 × 60 ≈ 140 000 |
| Expansion ×4 (1 décodage + 4 encodages / canonique) | 2339 × 300 ≈ 700 000 |
| **Total démarrage** | **≈ 840 000 allocations** |
| Un appel `countPossibleSolutions()` | 9356 `&` + 9356 `==` → **9356 allocations** |

Chaque `<<`, `|` et `&` sur `BigInt` alloue un nouvel objet en Dart : ce sont des
allocations réelles, pas des opérations registre.

Nombre de sites d'appel de `countPossibleSolutions()` dans `pentomino_game_provider.dart` :
**14** (dont `_computeSolutionsWithTransformedPiece`, appelé sur chaque rotation,
symétrie et cycle de position). Un coup de jeu = un balayage complet des 9356.

**Hypothèses** (à mesurer, non vérifiées ici) :

- empreinte mémoire résidente des 9356 `BigInt` : de l'ordre de 0,8–1 Mo, contre
  105 Ko pour le fichier source ;
- déchets produits par appel : de l'ordre de 0,5–1 Mo, à chaque coup ;
- le temps de démarrage est **déjà instrumenté** : `initWithBigIntSolutions` logue sa
  durée (`[SOLUTION_MATCHER] ✓ … en Xms`). Lire cette valeur sur un appareil réel avant
  toute décision d'optimisation.

Point important pour ne pas se tromper de cible : 9356 opérations sur 12 mots, c'est
~112 000 opérations mot — négligeable en ALU. **Le coût est l'allocation, pas le calcul.**

### Constat terrain (27/08/2026) — aucun problème de performance

Retour de Paul en usage réel sur 6×10 : **aucun problème de temps de réponse**, ni au
démarrage ni pendant la partie.

Cette observation prime sur les comptages ci-dessus, qui ne sont que des volumes
d'opérations et n'ont jamais été convertis en millisecondes. Les chiffres restent exacts ;
ils décrivent simplement un coût que le matériel absorbe sans que l'utilisateur le voie.

Argument supplémentaire de sérénité : **le 6×10 est le pire cas** des rectangles de
pentominos. Nombre de solutions à symétrie près — 6×10 : **2339**, 5×12 : 1010,
4×15 : 368, 3×20 : 2. Tout autre format serait moins coûteux, pas plus. Il n'y a donc pas
de mur de passage à l'échelle à anticiper dans le périmètre du jeu.

Ce qui **rouvrirait** le dossier, et rien d'autre :

- un appareil nettement plus lent que ceux testés ;
- un appel au comptage depuis un `build()` (donc à chaque frame) au lieu d'une fois par
  action du joueur — ce n'est pas le cas aujourd'hui ;
- un changement de jeu de pièces (hexominos ou plus), qui ferait exploser le nombre de
  solutions.

**Conséquence : P0, P2 et P3 (§6) sont classées sans suite.** Optimiser ici serait de
l'ingénierie sans problème à résoudre. Les défauts §3 et §4 restent valides — ce sont des
questions de correction et de lisibilité, indépendantes de la performance.

---

## 6. Pistes, par rapport gain / risque

### P0 — Comptage incrémental — ⏸️ CLASSÉE SANS SUITE (voir §5, constat terrain)

L'ensemble des solutions compatibles est **monotone décroissant** quand on pose une
pièce. Filtrer la liste précédente au lieu de rebalayer les 9356 : après 3 ou 4 pièces
posées il en reste typiquement quelques centaines. Le coût s'effondre naturellement au
fil de la partie.

Objection sérieuse : il faut une pile d'états pour le retrait de pièce et l'annulation,
sinon on doit rebalayer. C'est un changement d'architecture du provider, pas une
micro-optimisation. À ne faire que si une mesure montre que le comptage est bien le
poste dominant.

### P1 — Supprimer le code mort — ✅ FAIT le 27/08/2026

Trois fichiers supprimés (`git rm`), **555 lignes** :

| Fichier | Lignes | Portait |
|---|---|---|
| `lib/utils/plateau_compressor.dart` | 198 | défaut **B1** (rotate90 destructeur) |
| `lib/data/solution_database.dart` | 153 | défaut **B2** (asset inexistant) |
| `lib/screens/solutions_viewer_screen.dart` | 204 | écran orphelin, seul consommateur des deux autres |

Ces trois fichiers formaient un **cluster fermé** : le screen importait les deux autres,
`solution_database` importait `plateau_compressor`, et rien à l'extérieur n'atteignait
l'ensemble. Vérifié avant suppression sur `lib/`, `test/` et `tools/` — par nom de fichier
**et** par nom de classe (`PlateauCompressor`, `SolutionDatabase`, `SolutionsViewerScreen`) :
zéro référence externe.

Après suppression : **66 fichiers `.dart`** dans `lib/`, **0 import `package:pentapol/`
cassé** (contrôle exhaustif de tous les imports contre la liste des fichiers existants).

> ⚠️ Ne pas confondre avec `lib/screens/solutions_browser_screen.dart`, qui est **vivant**
> (importé par `classical/pentomino_game_screen.dart` et par `action_slider.dart`) et n'a
> pas été touché. Les deux noms ne diffèrent que par *viewer* / *browser*.

Les défauts **B1 et B2 sont donc clos** : le code qui les portait n'existe plus.

**`bigint_plateau.dart` n'a délibérément pas été supprimé.** C'est le cas inverse :
orphelin, mais **meilleur** que ce qui est utilisé. Le faire adopter par
`plateau_solution_counter` à la place de `_PlateauBigIntMask` supprimerait D1 — c'est un
travail d'adoption, pas de suppression.

### P2 — `Uint32List` plat au lieu de `List<BigInt>` — ⏸️ CLASSÉE SANS SUITE

2339 solutions × 12 mots de 32 bits = 112 272 octets, **une seule allocation**,
comparaison par boucle de mots avec sortie anticipée (le premier mot discrimine dans la
quasi-totalité des cas), zéro déchet par appel.

Objections : (a) 360 bits ne tiennent pas dans 11 mots (352), il faut 12 mots et
accepter 24 bits inutilisés ; (b) le gain réel dépend du JIT/AOT Dart et n'est **pas
mesuré ici**. Ne pas engager cette réécriture sans un chiffre de départ.

### P3 — Index inversé (case, pièce) → bitsets — ⏸️ CLASSÉE SANS SUITE

720 bitsets (60 cases × 12 pièces) de 2339 bits ≈ 211 Ko. Le comptage devient une
intersection de k bitsets + popcount, sans matérialiser la liste des solutions.

À ne considérer que si P0 est écarté et que P2 ne suffit pas. Complexité nettement
supérieure pour un gain qui recouvre largement celui de P0.

### P4 — Corriger la course au démarrage — ✅ FAIT le 27/08/2026

Voir §B3 pour le détail de la correction appliquée.

### P5 — Corriger la documentation

- ✅ Table des lettres de `PIECES_ENCODING.md` (§D2) — fait le 27/08/2026
- ✅ Table de minimalité « pourquoi 6 bits » de `PIECES_ENCODING.md` (§7.5) — fait
- ✅ Table des lettres dans l'en-tête de `solution_matcher.dart` (§D2) — fait
- ✅ Convention d'axes de la grille 5×5 dans `PIECES_ENCODING.md` (§D4) — fait
- ✅ Retirer `solutions_6x10_brutes.bin` (§D3) — supprimé le 27/08/2026

### P6 — Test de non-régression

Les vérifications du §2 sont mécanisables en un test Dart d'une trentaine de lignes :
nombre de solutions, unicité, validité des codes, 12×5 cases par solution, expansion
sans collision. Aujourd'hui rien ne protège le format binaire d'une régression.

---

## 7. Fondement combinatoire du code `bit6`

Cette section nomme et complète le raisonnement de `docs/PIECES_ENCODING.md`. Le
raisonnement du document original est juste ; il lui manquait le nom de l'objet et
l'argument de minimalité.

### 7.1 Le cadre

Prenez `[n] = {1,…,n}` et l'ensemble de ses parties, **ordonné par inclusion**. C'est un
ensemble partiellement ordonné (*poset*), le treillis booléen `B_n`. Partiel : `{1,2}` et
`{2,3}` ne sont comparables dans aucun sens.

Le pont avec le code est direct — **un mot de 6 bits est un sous-ensemble de {1,…,6}**
(les positions des bits à 1) :

| Bits | Ensembles |
|---|---|
| `P & Q` | `P ∩ Q` |
| `P \| Q` | `P ∪ Q` |
| `P & Q == Q` | `Q ⊆ P` |
| poids de Hamming | cardinal |

Le test `S & P == P` de `PIECES_ENCODING.md` **est** le test d'inclusion `P ⊆ S`.

### 7.2 Antichaîne

Une famille `F` est une **antichaîne** (*antichain*, aussi *famille de Sperner*) si deux
membres distincts ne sont jamais comparables : `∀ A ≠ B ∈ F, A ⊄ B et B ⊄ A`.

C'est exactement la propriété que `PIECES_ENCODING.md` démontre, et sa preuve (deux
ensembles distincts de même cardinal ne peuvent s'inclure) est correcte. Vérifié sur les
12 codes du projet : **aucune paire `(P,Q)` avec `Q ⊆ P`**.

### 7.3 Couches et couche médiane

`B_n` est **gradué** : le rang d'un élément est son cardinal (= son poids de Hamming).
Cela découpe `B₆` en 7 **couches**, de tailles `C(6,k)` :

```
rang k    taille
  6         1   █
  5         6   ██████
  4        15   ███████████████
  3        20   ████████████████████   ← couche médiane
  2        15   ███████████████
  1         6   ██████
  0         1   █
                64 = 2⁶
```

Trois faits qui s'enchaînent :

1. **Chaque couche est une antichaîne** — gratuit, cardinaux égaux.
2. **La couche médiane est la plus grosse** — `C(n,k+1)/C(n,k) = (n−k)/(k+1)`, rapport
   `> 1` tant que `k < (n−1)/2` puis `< 1`. Pour n=6 : `6 → 2,5 → 1,33 → 0,75`. Pic en k=3.
3. **Aucune antichaîne, même mixte, ne dépasse la couche médiane** — c'est le théorème,
   et c'est le seul des trois points qui n'est pas du simple calcul.

Les 20 codes de poids 3 du projet sont exactement cette couche médiane de `B₆`.

### 7.4 Théorème de Sperner (1928)

> Dans `B_n`, toute antichaîne a au plus `C(n, ⌊n/2⌋)` éléments. Pour `n` pair, ce maximum
> est atteint **uniquement** par la couche médiane.

`n = 6` étant pair, la couche des triplets est l'unique antichaîne maximum de `B₆`.

**Preuve (inégalité LYM — Lubell/Yamamoto/Meshalkin).** Une *chaîne maximale* est une
suite `∅ ⊂ A₁ ⊂ … ⊂ A_n = [n]` ajoutant un élément à chaque étape : elle est en bijection
avec une permutation de `[n]`, il y en a `n!`. Un ensemble `A` de taille `k` appartient à
exactement `k!·(n−k)!` d'entre elles. Une antichaîne rencontre chaque chaîne au plus une
fois (deux membres d'une même chaîne seraient comparables). En comptant les couples
(chaîne, membre de `F` dessus) :

```
Σ_{A ∈ F} |A|!·(n−|A|)!  ≤  n!     ⟺     Σ_{A ∈ F} 1 / C(n,|A|)  ≤  1
```

Comme `C(n,|A|) ≤ C(n,⌊n/2⌋)`, chaque terme vaut au moins `1/C(n,⌊n/2⌋)`, d'où
`|F| ≤ C(n,⌊n/2⌋)`. ∎

### 7.5 Ce que le théorème prouve réellement ici

Le tableau de `PIECES_ENCODING.md` justifiait « 6 bits minimum » par `C(n,3) ≥ 12`. Cet
argument **présuppose** le poids constant et ne dit rien des familles mixtes. Sperner
comble le trou :

| n bits | `C(n,3)` | Borne de Sperner (**toute** antichaîne) | 12 codes ? |
|---|---|---|---|
| 4 | 4 | **6** | non |
| 5 | 10 | **10** | non |
| 6 | 20 | **20** | oui |

La conclusion du document original était bonne ; sa preuve ne l'établissait qu'à moitié.
(À n=4 la table sous-estimait même le vrai maximum : 4 au lieu de 6.)

### 7.6 Poids 3 ou poids 4 : les deux fonctionnent

Point souvent mal compris, vérifié par calcul :

| poids | nb de codes | antichaîne ? | ≥ 12 pièces ? |
|---|---|---|---|
| 2 | 15 | oui | **oui** |
| 3 | **20** | oui | **oui** |
| 4 | 15 | oui | **oui** |

Une famille entièrement en poids 4 marcherait aussi bien. Le seul avantage du poids 3
est la **marge** : 8 codes libres au lieu de 3. Aucune propriété algébrique
supplémentaire, aucun test plus rapide.

Ce qui casse la propriété, c'est de **mélanger** les poids :
`0b001111 & 0b000111 == 0b000111` — le test « la pièce `0b000111` est ici » répond vrai
sur une case occupée par une autre pièce.

Nuance : le poids constant est **suffisant, pas nécessaire**. Une antichaîne mixte est
possible (vérifié : `{1,2}` plus les 16 triplets qui ne le contiennent pas forment une
antichaîne de 17 codes). Sans intérêt en pratique — à poids constant, valider un code se
réduit à `popcount(code) == 3` ; une famille mixte impose une table explicite.

### 7.7 Les 8 codes libres

20 codes disponibles, 12 utilisés :

```
26 = 0b011010 = {2,4,5}     42 = 0b101010 = {2,4,6}
28 = 0b011100 = {3,4,5}     44 = 0b101100 = {3,4,6}
38 = 0b100110 = {2,3,6}     50 = 0b110010 = {2,5,6}
                            52 = 0b110100 = {3,5,6}
                            56 = 0b111000 = {4,5,6}
```

Utilisables pour jusqu'à 8 états supplémentaires par case (case cachée, case bloquée,
pièce fantôme, pièce adverse en multijoueur) **en conservant** la propriété d'antichaîne.
C'est directement pertinent : le schéma 4 bits mort avait dû inventer la valeur `13`
pour « cellule cachée », sans aucune garantie de ce type.

Deux garde-fous :

- **Ne jamais sortir de la couche 3.** Un code de poids 2 ou 4 ajouté aux 12 existants
  casse l'antichaîne.
- `0` (= `∅`) est inclus dans tout : il n'appartient pas à l'antichaîne. Sans danger tant
  qu'il reste réservé à « case vide » — ce que `PIECES_ENCODING.md` précise correctement.

### 7.8 Objection : la propriété n'est pas utilisée

Relevé de **tous** les `&` du chemin vivant. Sans exception, ils opèrent avec un masque
**pleine largeur** `0x3F` :

- `solution_matcher.dart:502` — `(solution & maskBits) == piecesBits`, `maskBits` portant
  `0x3F` sur chaque case occupée
- `solution_matcher.dart:398`, `bigint_plateau.dart:96–105`,
  `solutions_browser_screen.dart:354` — extraction par `& 0x3F` puis égalité exacte

Le test `S & P == P` avec `P` un code de pièce — celui que l'antichaîne rend non ambigu —
**n'apparaît nulle part** dans `lib/`. Avec un masque pleine largeur, `solution & 0x3F`
extrait le code entier et la comparaison est une égalité stricte : **n'importe quelle
numérotation injective ferait l'affaire**, y compris `1..12` sur 4 bits.

Coût de ce qui n'est pas utilisé : 2 bits × 60 cases = 15 octets par solution, soit
~35 Ko sur les 105 Ko du fichier, et 360 bits au lieu de 240 par `BigInt`.

Ce n'est **pas** une recommandation de repasser à 4 bits. Deux arguments contre :

- 35 Ko et un tiers d'empreinte sont marginaux au regard du §5 — le poste dominant reste
  l'allocation `BigInt`, pas la largeur du champ ;
- 6 bits garde la porte ouverte : les 8 codes libres et le test d'inclusion sont un vrai
  levier si des états de case ou des pièces adverses apparaissent.

Le fait, lui, est net : la propriété est aujourd'hui payée et non exercée. Soit on
l'exerce, soit c'est une décision d'extensibilité à assumer explicitement — pas une
justification technique du code présent.

### 7.9 Références

- E. Sperner, *Ein Satz über Untermengen einer endlichen Menge*, Math. Z. 27 (1928)
- D. Lubell, *A short proof of Sperner's lemma*, JCT 1 (1966) — la preuve du §7.4
- R. P. Dilworth (1950) — voie alternative, par décomposition en chaînes symétriques

---

## 8. Note de terminologie

| Employé dans le projet | Terme correct | Remarque |
|---|---|---|
| `positionIndex`, « position » | **orientation** (fr) / *fixed orientation* (en) | « position » = emplacement (`gridX`, `gridY`). Les deux sens cohabitent dans le même objet `PlacedPiece`. |
| `PlateauCompressor` | **encodeur** (fr) / *encoder*, *packer* (en) | Largeur fixe, taille constante : c'est de l'empaquetage, pas de la compression. |
| `normalisees` / `canonical` | **forme canonique** d'une *classe d'équivalence* (fr) / *canonical form* d'une *orbit* (en) | Les deux mots désignent la même chose dans le projet et nomment deux fichiers différents. En choisir un. |
| `bit6` | **code sur 6 bits** — `code6` | Ce n'est pas un bit. |
| « poids de Hamming constant » (doc) | correct — *constant-weight code* (en) | La propriété exploitée (aucun code n'est inclus dans un autre) s'appelle une **antichaîne** ; ici l'antichaîne de Sperner des sous-ensembles de taille 3 de {1..6}. Vaut la peine d'être nommée : le raisonnement de `PIECES_ENCODING.md` est juste, il lui manque le nom. |
| `isométrie` | correct en français | En anglais : *isometry*, ou plus courant dans ce domaine *symmetry operation* / *dihedral transformation*. |

---

## 9. Résumé

Ce qui marche : l'encodage `bit6` / `BigInt` 360 bits, le fichier `normalisees.bin`,
l'expansion ×4 et le test de compatibilité. Vérifié par exécution, sans écart.

Ce qui ne marchait pas : tout le schéma 4 bits (`PlateauCompressor`, `SolutionDatabase`)
— cassé, mort, pointant vers un asset inexistant. **Supprimé le 27/08/2026** (555 lignes,
3 fichiers). Il ne reste qu'un seul schéma d'encodage dans le projet.

Ce qui reste fragile : le masque de requête face aux cases cachées (B4) et la
reconstruction d'orientation qui retombe silencieusement sur 0 (B5). La course au
démarrage (B3) est corrigée.

Ce qui était faux dans la doc : les trois tables de lettres (deux documents + l'en-tête du
`.dart`) et la convention d'axes de la grille 5×5. **Tout est corrigé** au 27/08/2026, et
`solutions_6x10_brutes.bin` est supprimé (§D3).

Ce qui est bien fondé mais inutilisé : la propriété d'antichaîne du code `bit6` (§7) —
mathématiquement correcte, optimale, et jamais exercée par le code.

P1, P4 et P5 sont faits et **validés en exécution le 27/08/2026**. **Reste** l'adoption de
`bigint_plateau.dart` (D1), et les deux défauts latents B4 (cases cachées) et B5
(`positionIndex` retombant à 0) — aucun n'est urgent.

P0, P2 et P3 sont **classées sans suite** : le constat terrain du 27/08/2026 (§5) établit
qu'il n'y a pas de problème de performance à résoudre sur 6×10, qui est par ailleurs le
pire cas des rectangles de pentominos. Les conserver ici comme documentation de l'analyse,
pas comme travail à faire.
