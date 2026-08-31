# Plan — les tables de solutions pré-calculées

> **Ce qui est fait, et qui n'a plus besoin d'être écrit ici :** le 6×10 existe dans
> Pentoscope comme taille `size6x10`, adossée à la table des 9356 solutions, avec compteur à
> l'écran et indice tiré d'une solution compatible au hasard. Le câblage passe par
> `SolutionSource` (`lib/pentoscope/solution_source.dart`), choisie une seule fois dans
> `startPuzzle`. Testé sur appareil. Le détail est dans `git log`.
>
> **Ce qui reste : §5, les tables 5×12 et 4×15.** Le 3×20 est écarté — 2 solutions à symétrie
> près, donc un compteur à 0 et un indice rouge en permanence ; l'objection n'est pas
> l'affichage mais le jeu.

---

## Les trois règles qui engagent la suite

1. **`puzzle.solutions` reste vide pour les rectangles complets.** La remplir dupliquerait en
   mémoire des solutions que le matcher détient déjà en BigInt, et imposerait une conversion
   par solution. *(L'argument du calcul de `minIsometries` au démarrage a disparu avec le
   retrait du score.)*
2. **Le format ne dépend pas de la forme du rectangle** : 60 cases × 6 bits = 45 octets, que
   le plateau soit 6×10 ou 3×20. Le chargeur prend l'asset en paramètre — les nouvelles tables
   ne le touchent pas.
3. **La paramétrisation de `SolutionMatcher` est additive**, dimensions par instance. Il n'y a
   plus de singleton global depuis la suppression du mode classique.

---

## 5. Les trois autres tables — 5×12, 4×15, 3×20

> Rédigé le 2026-08-29 par cowork, pendant l'attente du test appareil du temps 2. **Rien
> ici ne doit être exécuté avant que Paul ait validé le temps 2** (§4.7) — c'est ce qui
> garde le chantier réversible.

### 5.1 Le correctif préalable — rendre la troncature impossible à manquer

Il y a **deux** défauts, pas un.

1. `PentominoSolver.maxSeconds` vaut 30 et c'est un champ `final` sans paramètre de
   constructeur (`lib/services/pentomino_solver.dart` l.23) : l'outil hors-ligne ne peut
   pas le régler.
2. Même relevé, **un timeout ne se voit pas** : `findAllSolutions` fait un `return` après
   un `print` (l.470-475), et l'appelant reçoit une liste qu'il ne peut pas distinguer
   d'une liste complète.

Le second est le vrai défaut. Rendre `maxSeconds` paramétrable sans rendre la troncature
observable ne ferait que déplacer le problème d'un cran.

**La mesure qui autorise à changer la signature** : `findAllSolutions` n'a **qu'un seul
appelant** dans tout le dépôt — `tools/generate_6x10_solutions.dart` l.48. Vérifiable par
`grep -rn 'findAllSolutions' lib/ tools/ test/`.

#### Les sites, exactement

**a) Le champ et les deux constructeurs.**

```dart
final int? maxSeconds;   // null = sans limite
```

Paramètre nommé de défaut 30 sur le constructeur (l.38) **et** sur la factory
`fromIds` (l.45), pour que les trois appelants existants (`findSolution` l.11,
`hasSolution` l.17, l.68) ne changent pas d'une ligne.

**b) Les trois comparaisons** — l.111 (`backtrack`), l.472 (`findAllSolutions`), l.593
(boucle de reprise) — deviennent :

```dart
final limit = maxSeconds;
if (limit != null && DateTime.now().difference(startTime).inSeconds > limit) …
```

**c) La signature de `findAllSolutions`** — c'est le cœur du correctif :

```dart
Future<({List<List<PlacementInfo>> solutions, bool truncated})> findAllSolutions({...})
```

`truncated` vaut `true` si le timeout **ou** `maxSolutions` a coupé la recherche. Un
résultat tronqué ne peut alors plus être confondu avec un résultat exhaustif.

**d) L'outil refuse d'écrire** quoi que ce soit quand `truncated` est vrai. Une
énumération exhaustive interrompue n'est pas un résultat partiel, c'est un run raté.

#### Deux choses à savoir avant de toucher à ça

> **Le fichier livré est bon, ne pas le régénérer.** Les 8175 solutions brutes couvraient
> les **2339/2339** classes (vérifié le 2026-08-27) : `solutions_6x10_normalisees.bin` est
> complet. C'est un coup de chance qu'on ne peut pas attendre des trois autres tables — une
> troncature peut parfaitement faire manquer une classe.

> **L'avertissement « Cela va prendre plusieurs heures » (outil l.39) est faux.** 8175
> solutions en 30 s au plus, c'est ~270/s : les 9356 sortent en une quarantaine de
> secondes. Hypothèse simple, vérifiable au premier run ; corriger l'en-tête de l'outil
> dans le même commit.

#### Critères de fin

```bash
S=lib/services/pentomino_solver.dart
grep -c 'maxSeconds' $S                       # 1 champ + 2 params + 3 tests
grep -rn 'findAllSolutions' lib/ tools/ test/ # 1 déclaration + 1 appel
```

`flutter analyze` : **0 warning**. Et un run de non-régression sur le 6×10 :
**9356 brutes, 2339 normalisées, `truncated == false`**. Si le compte diffère, ne rien
écrire et revenir ici.

### 5.2 Généraliser l'outil de génération

`_boardWidth` / `_boardHeight` sont des `const` en tête de fichier (l.14-15) et les noms de
fichiers sont écrits en dur à six endroits. Passer les dimensions en arguments de ligne de
commande et dériver les noms (`solutions_${w}x${h}_brutes.bin`,
`solutions_${w}x${h}_normalisees.bin`).

`pieceOrder` (l.32) est une heuristique d'ordre de placement : valable pour toute forme,
la garder telle quelle.

### 5.3 Le format ne bouge pas

60 cases × 6 bits = 45 octets par solution, quelle que soit la forme du rectangle. Volumes
attendus :

| table | canoniques | ×4 | fichier |
|---|---|---|---|
| 6×10 | 2339 | 9356 | 105 255 o *(constaté)* |
| 5×12 | 1010 | 4040 | 45 450 o |
| 4×15 | 368 | 1472 | 16 560 o |
| 3×20 | 2 | 8 | 90 o |

Négligeable. Déclarer les trois nouveaux assets dans `pubspec.yaml`.

### 5.4 Le critère d'acceptation est gratuit et décisif

Les comptes canoniques des pavages de rectangles par les 12 pentominos sont connus :
**2339 / 1010 / 368 / 2**. Générer, normaliser, compter, comparer.

Trois vérifications, **dans l'outil** et pas dans un carnet — il refuse d'écrire si l'une
échoue :

1. compte canonique == valeur attendue pour ces dimensions ;
2. **aucune solution invariante** par rot180, miroirH ou miroirV — sinon l'expansion ×4 de
   `SolutionMatcher` produit des doublons et `totalCount` ment ;
3. expansion ×4 → 0 collision, compte == 4 × canoniques.

C'est exactement ce qui aurait attrapé le 8175.

### 5.5 Décision d'interface — le sélecteur de taille

**Le problème n'est pas seulement la place.** `pentoscope_menu_screen.dart` l.127-131 est un
`Row` d'`Expanded`, un par `PentoscopeSize.values` : 8 aujourd'hui, 12 demain, soit une
trentaine de pixels chacun sur un téléphone. Mais surtout, les deux familles n'ont rien à
faire dans la même rangée indifférenciée :

| | puzzles | rectangles complets |
|---|---|---|
| pièces | 3 à 10, **tirées au hasard** | les 12, toujours les mêmes |
| configuration | une par tirage | une seule, à jamais |
| solutions | calculées à la volée | table pré-calculée |
| `label` actuel | `numPieces` (`'3'`…`'10'`) | vaudrait `'12'` **quatre fois** |

**Décision retenue : deux groupes, chacun sa rangée, chacun son intitulé.** Les 8 puzzles
gardent la rangée et les labels d'aujourd'hui — aucune régression, c'est l'état que Paul a
validé. Les 4 rectangles forment une seconde rangée de 4 `Expanded`, plus large que
l'existante, avec des labels `'6×10'`, `'5×12'`, `'4×15'`, `'3×20'`.

Le changement se limite à `_buildSizeSelector` : une `Column` de deux `Row`, chacune filtrée
sur `size.table == null` ou non. Le champ qui distingue les deux familles existe déjà — c'est
celui de §4.1, et c'est un argument de plus en sa faveur.

**Écartés, et pourquoi** : le défilement horizontal cache des options alors qu'il n'y en a
que 12 et qu'on veut les voir toutes ; un menu déroulant ajoute un geste au choix principal
de l'écran.

**Le second sélecteur ne bouge pas.** `pentoscope_game_screen.dart` l.952 est une liste de
`RadioListTile` — elle absorbe 12 entrées sans rien changer. Son titre affiche déjà
`'${size.label} (${size.width}x${size.height})'`, qui reste correct.

### 5.6 Décision d'interface — le 3×20

> **Tranché par Paul, 2026-08-29 : le 3×20 est abandonné pour l'instant** — ni généré, ni
> ouvert au joueur. Les tables à produire sont donc **5×12 et 4×15**, deux et non trois.
>
> ⚠️ **Le motif importe.** Paul l'a écarté « pour problèmes d'affichage ». Ce n'est pas la
> bonne raison, et s'en tenir à celle-là ferait rouvrir la question le jour où l'affichage
> sera amélioré. L'objection d'affichage est **faible** (voir l'arithmétique ci-dessous :
> des cases à 50 % de celles du 6×10, pas illisibles). L'objection dirimante est de **jeu** :
> 2 solutions à symétrie près sur 60 cases, donc un compteur à 0 après très peu de pièces et
> un indice rouge en permanence. Aucune amélioration d'affichage ne changera ça.
>
> Coût de la table elle-même, pour mémoire si la question revient : **90 octets, 8
> solutions** — la seule vérifiable à la main, ce qui en aurait fait une bonne fixture de
> validation de la chaîne de génération. Écartée avec le reste ; à rouvrir seulement si un
> mode « expert » est décidé.


**Correction d'une mesure de la version précédente de ce document**, qui annonçait des cases
« illisibles » sur les plateaux hauts. L'arithmétique dit autre chose. `cellSize` vaut
`min(W/colonnes, H/lignes)` (`pentoscope_board.dart` l.65-67) ; en portrait ce sont les
lignes qui contraignent. Rapporté au 6×10 que Paul vient de valider, à surface d'affichage
égale :

| taille | lignes | case relative au 6×10 |
|---|---|---|
| 5×12 | 12 | **83 %** |
| 4×15 | 15 | **67 %** |
| 3×20 | 20 | **50 %** |

Moitié, pas « minuscule ». L'objection de lisibilité ne tient donc pas pour le 5×12 ni le
4×15 ; elle reste à regarder sur l'appareil pour le 3×20, et le mode paysage y échange les
axes (`visualCols = boardHeight`), ce qui change complètement le calcul — **à observer, pas
à déduire.**

**La vraie objection est ailleurs, et elle est de jeu.** Le 3×20 a **2 solutions à symétrie
près, 8 en tout, sur 60 cases**. Conséquence directe sur les deux fonctions qu'on vient de
brancher : le compteur tombe à 0 après très peu de pièces, et l'indice passe au rouge
presque tout le temps. Ce n'est pas un défaut d'implémentation, c'est la nature du plateau —
mais un niveau où l'assistance dit « impasse » en permanence n'est pas un niveau.

**Décision retenue : le 3×20 est généré et vérifié, mais n'entre pas dans le sélecteur.**
Il sert de **fixture de validation de la chaîne** — c'est la seule table assez petite (8
solutions) pour être vérifiée exhaustivement à la main. Son ouverture au joueur est une
décision de jeu séparée, à prendre après avoir vu le comportement du compteur sur le 4×15.

> Ce point est une recommandation de cowork, pas un arbitrage de Paul. S'il veut un mode
> « expert », le 3×20 est le candidat évident et rien dans le code ne s'y oppose — il suffit
> de lui donner sa `SolutionTable`.

### 5.7 Ordre d'exécution

1. **Correctif du solveur** (§5.1), commit seul, avec le run de non-régression 6×10.
2. **Généralisation de l'outil** (§5.2), commit seul.
3. **Génération et vérification** des trois tables (§5.4), ajout aux assets et à
   `pubspec.yaml`.
4. **Sélecteur de taille** (§5.5) — **avant** l'étape 5, jamais après : ajouter les valeurs
   d'enum d'abord ferait passer le `Row` à 12 entrées et afficherait quatre « 12 ».
5. Les valeurs `SolutionTable` et les tailles `PentoscopeSize` correspondantes — **deux**,
   5×12 et 4×15 ; le 3×20 est écarté (§5.6).
6. Test appareil.

L'inversion des étapes 4 et 5 est la seule erreur d'ordre qui produirait une régression
visible.

---

## 6. Voir aussi

- `CLAUDE.md` §Invariants — les deux pièges qui commandent ce chantier : ce que la table sait
  répondre, et le timeout invisible du solveur hors-ligne
- `docs/ANALYSE_STOCKAGE_POSITIONS.md` — l'encodage `bit6`, §7 le fondement combinatoire
