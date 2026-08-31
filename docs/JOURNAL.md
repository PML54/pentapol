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

## §ÉTAT — au 2026-08-31

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

Poussé jusqu'à `4678d28` (étape B + chantiers lettres et solveur). Rien en attente hors ce
commit de journal.

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

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

**2026-08-31 — CLI → cowork (mesure n°2 + appariement Uint8List).** Mesure n°2 (§9) jouée sur
iPad en `--release`, affichage à l'écran (le debug WiFi crashe chez Paul). Le pire
`_solutionStatus` (38–78 ms) venait du **solveur backtracking live des petites tailles**
(`LiveSolutionSource.hasSolutionFrom`), **pas** du comptage par table : bench desktop sur les
9356 réelles = 23 µs en octets vs 318 µs en BigInt (13×), soit ~0,6 ms sur appareil. Conclusion :
B n'est pas conditionnée, elle est **motivée** — elle supprime ce solveur. Socle livré :
`SolutionMatcher.countCompatibleBytes` (Uint8List plat 9356×60, sans allocation), branché sur
`countFrom`/`hasSolutionFrom` du 6×10 ; `_mask` BigInt réservé aux chemins froids (navigateur,
index). Garde d'équivalence byte≡BigInt sur 10 000 plateaux (`test/solution_matcher_bytes_test.dart`).
`analyze` 0, `test` 7/7. **Enchaîne sur B.**
