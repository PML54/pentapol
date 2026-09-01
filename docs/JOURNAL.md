# Journal — état et passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`.
>
> **§ÉTAT est réécrite à chaque passage. §PASSATIONS ne garde que les trois dernières.**
>
> ⚠️ **§DÉCISIONS a été supprimée le 2026-08-31.** Elle comptait 69 entrées et 112 renvois
> croisés — une comptabilité devenue plus coûteuse que ce qu'elle rapportait, et le point de
> collision entre agents (trois renumérotations en deux jours). Les décisions qui **engagent
> encore** sont devenues des règles dans `CLAUDE.md` §Invariants ; les autres sont de
> l'histoire, et l'histoire est dans `git log`.

---

## §ÉTAT — au 2026-09-01

### L'application

Un seul module de jeu, **Pentoscope** : tailles `size3x5`…`size10x5` (tirage d'un masque de
pièces parmi les solubles) plus `size6x10` (rectangle complet). **Toutes** les réponses
« solution » (compte décroissant, disponibilité, guide) sont désormais adossées à des tables
pré-calculées : `subset_counts.bin` (comptes), `solutions_corpus.bin` (corpus 5×n, 3,13 Mo) et
`solutions_6x10_normalisees.bin`. **Plus aucun solveur backtracking dans l'app livrée.** Plus le
**multijoueur**, qui réutilise son provider. Démarrage direct sur `PentoscopeGameScreen`, pas
d'écran d'accueil. Plus de notion de difficulté.

### Chantiers terminés

- **Suppression du mode classique** — −3197 lignes, module, widgets, écran d'accueil.
- **Le 6×10 dans Pentoscope** — temps 1 et 2, `SolutionSource`, compteur de solutions.
- **Bilan de fin de partie** — bandeau non modal, score retiré, chronomètre corrigé.
- **Ergonomie hors plateau** — tailles ancrées sur le plateau, barre d'actions unique pour les
  deux orientations, ordre des zones aligné, écran de réglages minimal.
- **Persistance, étape 1** — Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.
- **Suppression de la difficulté puis tirages précalculés (étape A)** — `subset_counts.bin`
  (4096 × uint16, 8 Ko) donne le nombre de solutions de tout tirage 5×n ; le générateur tire un
  masque parmi les solubles (plus d'appel-boucle au solveur, plus de difficulté), le compte est
  affiché au dialogue avec « autre tirage ». Table validée contre `REFERENCE_TIRAGES.md` §2.
- **Tirages précalculés (étape B)** — corpus complet `solutions_corpus.bin` (3,13 Mo, octet/case,
  73 876 solutions 5×n) ; `CorpusSolutionSource` adosse **toutes** les tailles à une table,
  appariement d'octets sans allocation (`common/byte_matching.dart`), compteur décroissant partout,
  et **`PentoscopeSolver` supprimé du dépôt** (les outils réimplémentent l'énumération Flutter-free
  — inutile de le garder dans `tools/`). Motivé par la mesure n°2 : le pire `_solutionStatus`
  (38–78 ms) venait du solveur live, pas du comptage par table (~0,6 ms). Choix : **2 sources
  table-backed** (6×10 via `SolutionMatcher`/BigInt pour son navigateur ; 5×n via corpus/bytes).

Leurs plans ont été **supprimés** une fois appliqués et testés (`MODUS_VIVENDI` §5).

### Chantiers ouverts

| chantier | document | reste à faire |
|---|---|---|
| **Persistance** | `PLAN_PERSISTANCE.md` | étapes 2 à 4 : schéma + réécriture destructive, records, **partie en cours** |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | bloquants technique/produit/conformité — s'allonge au fil du travail |

**Priorité recommandée** : étape 4 de la persistance (la partie en cours n'est pas sauvegardée
— quitter l'app au milieu d'un 6×10 perd tout).

**En validation (branche `deplacement-piece`, non fusionnée)** : le chantier « déplacement d'une
pièce sur le plateau » (`PLAN_DEPLACEMENT_PIECE.md`) — correctifs 1→5 posés, un par commit,
plus l'instrumentation kDebugMode du commit 0 **encore en place**. En attente du test à l'écran
par Paul (§7 du plan). La carte des sha et la règle de revert sont dans la passation ci-dessous.
Le correctif 6 (coordonnées fractionnaires, hystérésis) n'est pas dans ce lot.

### Documentation

`FONCTIONNEMENT.md` est la description de référence de l'application — elle absorbe depuis
le 2026-08-31 l'ancien `PENTOSCOPE.md`, devenu un doublon partiel une fois qu'il n'est resté
qu'un module de jeu. `UI_PROPERTIES_GUIDE.md`, guide Flutter générique sans rapport avec
l'état du projet, est supprimé. `REFERENCE_TIRAGES.md` est le **test d'acceptation** du
générateur de tirages (`tools/generate_subset_counts.dart`) : sa sortie doit reproduire les
nombres du §2 (ce que le générateur vérifie, exit 1 sinon).

### Test

Paul, iPhone et iPad simulé, en release :

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` est supprimé : tout critère formulé sur la console doit être
> reformulé en observation à l'écran.
> ⚠️ La réécriture destructive de la base ne se teste que **sur une base existante** — une
> installation neuve ne l'exécute jamais.

### Git

Poussé jusqu'à `4678d28` (étape B + chantiers lettres et solveur). La branche
`deplacement-piece` (chantier de déplacement, 7 commits) n'est **ni fusionnée ni poussée** :
elle attend la validation à l'écran. Tag `avant-deplacement-piece` posé sur `1efda1a` (état
pré-chantier) — `git reset --hard avant-deplacement-piece` annule tout le lot.

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-09-01 — CLI → cowork (déplacement d'une pièce : correctifs 1→5 posés, en attente de test).**
Chantier `PLAN_DEPLACEMENT_PIECE.md`, branche `deplacement-piece`, réversible commit par commit
(§7). Tag `avant-deplacement-piece` sur `1efda1a`. **Carte des sha** (un correctif = un commit) :

```
doc plan               7409c58
0  instrumentation      aab2b2b   (kDebugMode, reste jusqu'après validation)
1  pointerDragAnchor…    1c43096   (board + DraggablePieceWidget)
2  setDragMastercase     0a37223   (ancre sur la case saisie)
3  tryPlaceAtAnchor      b24471f   (dépôt à l'aperçu, sans faux doigt)
4  plafond aimantation   6759995   (~1,5 case ; DÉPEND de 1 et 2)
5  nettoyage             19e858b   (boucle morte 3.4, onLeave 3.5, debugPrint/margin/pièce 12)
```

**Règle de revert** : `git revert <sha>` isole un correctif. **Le 4 ne tient pas sans 1 et 2** :
annuler 1 ou 2 impose d'annuler 4 (sinon presque tout placement est refusé → fausse régression).
**L'instrumentation (commit 0) n'est PAS retirée** : elle journalise `caseSaisie / masterAbs /
dragStartPoint / cellSize` à chaque `onDragStarted` sous `kDebugMode`, et ne sera supprimée qu'au
commit final, une fois le geste validé à l'écran. **Test attendu de Paul** : reprendre une pièce
posée par une case ≠ celle tapée et la pousser latéralement d'une case — elle doit suivre le doigt
sans saut vertical, où que le doigt se pose dans la case ; idem au glissé depuis le tiroir.
`analyze` 0 error / 0 warning à chaque commit. **Non embarqué** (bruit Xcode) : `.metadata`,
`ios/`, `macos/`, `Podfile`. Correctif 6 (fractionnaire/hystérésis) hors lot, à juger à l'écran.

**2026-08-31 — CLI → cowork (deux chantiers courts : lettres, solveur).** Suite au Message CLI de
cowork. **Chantier 1 — table de lettres unique** (`3e3beaf`) : les deux tables périmées
(`_pieceNames` du générateur, 10/11 intervertis ; `pieceNames` de `piece_utils`, entièrement fausse,
lue par `custom_colors_screen` → l'utilisateur voyait des lettres fausses) remplacées par
`pentominoLetters` (unique, dans `common/pentominos.dart`, adossée à la géométrie). Gardée par
`test/pentomino_letters_test.dart`, qui reconstruit la lettre depuis `cartesianCoords` (clé
canonique/8 orientations) contre les 12 formes standard — il confirme Z=10, W=11 par une seconde
dérivation. **Chantier 2 — retrait du solveur par substitution** : `generate_solutions_corpus.dart`
étendu (`_verify6x10`) énumère le 6×10 et vérifie `solutions_6x10_normalisees.bin` par **égalité
d'ensembles** (9356 = énumération = asset expansé ×4, 16 s) ; **seulement alors** `git rm` de
`pentomino_solver.dart`, `tools/generate_6x10_solutions.dart`, `solution_collector.dart`. Plus aucun
solveur backtracking dans le dépôt. `analyze` 0, `test` 15/15. **Checklist mise à jour** : points 17
(afficher-solution 6×10, réglé par l'étape B) et 18 (lettres) retirés, §4 corrigé.
**À reconsidérer par cowork** : le **point 10** (« compteur/navigateur seulement sur 6×10 ») est en
partie réglé — le compteur décroissant est désormais sur toutes les tailles ; reste le navigateur de
solutions, laissé au 6×10 (décision 2 sources). La glose « ListSolutionSource » du point 10 est
caduque : c'est `CorpusSolutionSource` qui l'a fait.

**2026-08-31 — CLI → cowork (tirages étape B, terminée).** Corpus complet + source unifiée +
retrait du solveur, en 4 commits, testés sur iPad. **`86dcea6`** : `tools/generate_solutions_corpus.dart`
+ `assets/data/solutions_corpus.bin` (3,13 Mo, octet/case, 73 876 solutions 5×n) + test structurel ;
compte par masque identique à `subset_counts.bin`. **`8ce7a56`** : `common/byte_matching.dart`
(appariement d'octets partagé), `corpus_provider.dart` (découpe par masque), `LiveSolutionSource`
→ `CorpusSolutionSource` ; `SolutionMatcher.countCompatibleBytes` délègue au partagé. **`3cd14a2`** :
compteur décroissant actif sur toutes les tailles (gratuit — `solutionsCount` non-nul), bouton
« solutions compatibles » regaté au 6×10. **retrait solveur** : `PentoscopeSolver` **supprimé du
dépôt** (outils Flutter-free autonomes), `puzzleFromMask`/`generateFromSeed` ne l'appellent plus
(compte via `subset_counts.bin`, exact, sans troncature `maxSeconds=30`), `PentoscopePuzzle.solutions`
supprimé, `currentSolution` typé `List<PlacedPiece>?` servi par `hintFrom`. **Décision : 2 sources
table-backed** (6×10/BigInt, 5×n/bytes), appariement unifié. `analyze` 0, `test` 12/12. **À noter
pour cowork** : le §7 de `REFERENCE_TIRAGES` dit « max 5×10 écarte X et W », mais ce masque donne
2612, pas 4664 — lettre ou exemple à corriger (sans incidence code, le §2 est respecté).
