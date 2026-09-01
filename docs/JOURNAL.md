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

### Chantier « déplacement d'une pièce » — REVERT (2026-09-01)

Le chantier `PLAN_DEPLACEMENT_PIECE` (correctifs 1→5) a fait **apparaître beaucoup d'anomalies**
(déplacements aléatoires) au test de Paul. Décision de Paul : **revenir à l'état pré-chantier**.
La branche de travail a été **reset --hard sur `1efda1a`** (= tag `avant-deplacement-piece`), puis
l'ergonomie conservée (voir plus bas) **fusionnée dans `main`** (`b9bec37`, fast-forward) et
**poussée sur `origin`**. La branche `deplacement-piece`, devenue redondante, a été **supprimée**.
Tout le chantier ET l'instrumentation DRAGDIAG posée ensuite sont **écartés du tree** mais
**conservés intacts** sur `c5306b5` :

- branche **`backup/deplacement-piece-c5306b5`** — **poussée sur `origin`** (donc visible pour
  cowork sur un clone neuf ; ne PAS la fusionner, c'est une archive).
- tag **`chantier-deplacement-backup`** — **local à la machine du CLI** (non poussé).

On y retrouve : plan `PLAN_DEPLACEMENT_PIECE.md`, correctifs 1→5 (carte des sha dans le `git log`
du backup), `PLAN_DIAG_DRAG.md` et l'instrumentation `lib/common/drag_diag.dart` + points DRAGDIAG.
**Rien n'est perdu** — reprise possible par `git cherry-pick`/`checkout` depuis la branche de backup.

**Conservés par-dessus le pré-chantier** (indépendants du chantier, validés par Paul) : les deux
correctifs d'ergonomie du 2026-09-01 — (a) saisie du « I » (barre des pièces, `hitBoxSize` : toute
la boîte de la case répond au doigt ; halo de sélection collé à la pièce) et (b) sortie de l'écran
Paramètres sur iPad (bouton « Fermer » en bas + `SafeArea`, la flèche retour étant recouverte par
les commandes multitâche macOS « Designed for iPad sur Mac »). Reposés à la main sur la version
pré-chantier de `draggable_piece_widget.dart` (le fichier avait été touché par le correctif 1),
`slider`/`settings` repris tels quels. `analyze` 0 error.

### Déplacement d'une pièce — cartographie du bug intermittent (pour la reprise)

Analyse du code **actuel `main` (pré-chantier)** — le décalage horizontal intermittent au glissé
vertical **précède le chantier** et est donc toujours là. Séparé en faits / hypothèse / correctif.

**Faits — topologie.** 2 sinks `DragTarget` : le plateau (`pentoscope_board.dart:85`) et le tiroir
(`pentoscope_game_screen.dart:648`). 3 trajets réels : ① poser depuis le tiroir, ② déplacer une
pièce posée, ③ supprimer (glisser vers le tiroir).
- ③ **fait bande à part** sainement : sink tiroir, `removePlacedPiece`, aucune arithmétique de case.
- ① et ② partagent le **sink plateau**, mais le partage est trompeur — deux fourches :
  - **Fourche A, aperçu ≠ dépôt.** L'aperçu (`onMove`→`updatePreview`→`_findClosestValidPlacement`)
    **snappe** sur l'ancre valide la plus proche. Le dépôt (`onAccept`, board:162-173) **ne snappe
    pas** : il **reconstruit un faux doigt** = `previewX/Y + selectedCellInPiece`, puis
    `tryPlacePiece` **re-dérive** l'ancre via `_calculateDesiredAnchorFromDrag` et place en direct.
  - **Fourche B, mode A ≠ mode B** dans `_calculateDesiredAnchorFromDrag` (prov ~1720). Tiroir
    (mode A, `selectedPlacedPiece == null`) → branche `selectedCellInPiece`, et la reconstruction du
    dépôt (`+selectedCellInPiece`) en est **l'exact inverse** → boucle propre. Pièce posée (mode B,
    `selectedMasterAbs != null`) → branche **`masterAbs`**, formule différente ; or le dépôt ajoute
    `selectedCellInPiece`, **pas** `masterAbs` → **pas inverses**, coïncidence seulement si
    `masterAbs == sp.gridX + selectedCellInPiece` (vrai au décalage de normalisation près).
- Aggravant : `selectPlacedPiece` (prov ~563-571) cherche `selectedCellInPiece` en comparant
  `rawLocal` à des coords **non normalisées** alors que les cellules sont **normalisées** → si
  l'offset de forme ≠ 0, match raté et **fallback brut** `Point(rawLocalX, rawLocalY)`.
- **Fourche C, métrique du snap aveugle à la direction (piste de Paul, la plus probable pour le
  « ça monte »).** `_findClosestValidPlacement` retient l'ancre valide qui minimise
  `dx*dx + dy*dy` — **isotrope** (x et y pèsent pareil) et **sans plafond** sur `main` (le plafond
  ~1,5 case était le correctif 4 du chantier, reverté). Conséquence : si la case visée par le doigt
  est occupée, monter d'une ligne (`dy=1`, d²=1) **bat** continuer horizontalement de deux cases
  (`dx=2`, d²=4) → la pièce « saute vers le haut » pendant un glissé horizontal, et le saut n'est
  même pas borné. La métrique ignore **la direction du geste**.

**Hypothèse (à PROUVER par mesure, pas à affirmer).** Le décalage vit dans le **trajet ②** :
aperçu (snap) et dépôt (reconstruction + re-dérivation `masterAbs`) divergent, et
`selectedCellInPiece` bascule parfois sur son fallback brut selon **forme / orientation / case
saisie** → non systématique, biaisé d'une case dans un sens. Le **trajet ① (tiroir) boucle
proprement** → il devrait être nettement plus stable. **L'asymétrie ① vs ② est testable** — c'est
ce que DRAGDIAG (dans le backup) mesure : `fcol` aperçu vs `finalX` dépôt, `grabx/graby` A vs B.

**Correctif minimal proposé (isolé, mesurable, un seul changement de comportement).**
**Déposer directement à `previewX/previewY`** dans `onAccept` — l'aperçu contient déjà une ancre
snappée et validée — **au lieu** de reconstruire un faux doigt puis de re-dériver. Supprime la
fourche A d'un coup. Corriger en parallèle le raw-vs-normalisé de `selectPlacedPiece` (fourche B /
fallback). Ne PAS ré-empaqueter avec d'autres retouches (c'est ce qui a coulé le chantier) ; un
correctif = un commit, testé à l'écran par Paul, l'asymétrie ①/② servant d'oracle avant/après.

**Correctif A — snap conscient de l'axe du geste (en préparation, 2026-09-01).** Vise la fourche C.
**Objection posée puis intégrée** : le « A naïf » (ne garder que les candidats de même ligne)
créerait le **bug miroir** pour un glissé vertical (saut latéral) ; aucune métrique *statique* ne
distingue horizontal de vertical quand la géométrie est symétrique. Il faut donc **la direction
réelle du geste**. Implémentation retenue : suivre l'axe dominant du mouvement (case doigt
précédente → courante, dans `updatePreview`, via un champ transitoire `_dragAxis` remis à zéro à
chaque sélection/pose), puis dans `_findClosestValidPlacement` **départager lexicographiquement** —
axe horizontal : minimiser d'abord `|Δligne|` puis `|Δcolonne|` ; axe vertical : l'inverse ; axe
inconnu : isotrope (comportement d'avant). Pas de plafond réintroduit (hors périmètre). Livré sur la
branche **`snap-directionnel`** (hors `main` tant que non testé), en **2 commits** : (1)
instrumentation DRAGDIAG rebranchée (oracle avant/après, `drag_diag.dart` du backup + log
`event=snap` avec `axis`, snap encore isotrope) ; (2) le changement de métrique.
Oracle : `event=snap` doit montrer, après (2), un `chosen` qui **reste sur la ligne du doigt** en
glissé horizontal. Test à l'écran par Paul.

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

`origin/main` = **`b9bec37`** (pré-chantier `1efda1a` + le commit d'ergonomie « I »/Paramètres),
poussé. La branche `deplacement-piece` a été **supprimée** (fusionnée dans `main`). Sauvegarde du
chantier écarté : branche **`backup/deplacement-piece-c5306b5`** (sur `origin` **et** locale) et tag
`chantier-deplacement-backup` (local seul), tous deux sur `c5306b5` — **ne pas supprimer** tant que
la question du déplacement d'une pièce n'est pas retranchée. Détail dans §ÉTAT « REVERT ».

> ⚠️ `settings_database.g.dart` (généré) est gitignoré : après un `pull`, régénérer par
> `dart run build_runner build --delete-conflicting-outputs`. `subset_counts.bin` **est** suivi.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-09-01 — CLI → cowork (REVERT du chantier « déplacement d'une pièce »).** Au test de Paul, le
chantier `PLAN_DEPLACEMENT_PIECE` (correctifs 1→5) a produit **beaucoup d'anomalies — déplacements
aléatoires**. La démarche d'instrumentation `PLAN_DIAG_DRAG` (logger DRAGDIAG derrière `kDragDiag`)
avait été posée juste avant, mais Paul a tranché : **retour à l'état pré-chantier** plutôt que
poursuite du diagnostic sur place. Branche `deplacement-piece` **reset --hard sur `1efda1a`**
(= `main` = tag `avant-deplacement-piece`). Chantier + instrumentation **sauvegardés** sur `c5306b5`
(tag `chantier-deplacement-backup`, branche `backup/deplacement-piece-c5306b5`) — rien perdu, reprise
par cherry-pick. **Conservés** par-dessus : les deux correctifs d'ergonomie du jour (saisie du « I »,
sortie Paramètres iPad), reposés à la main sur la base pré-chantier. `analyze` 0 error. **Pour cowork** :
si le déplacement d'une pièce est repris, repartir du backup pour lire les logs DRAGDIAG, ou d'une
approche neuve — l'ancienne a été jugée trop instable pour rester sur la branche de travail.
**Cartographie du bug intermittent + correctif minimal proposé : voir §ÉTAT « Déplacement d'une
pièce — cartographie du bug intermittent ».**

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
