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

## §ÉTAT — au 2026-09-02

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

**Résultat (2026-09-02, test de Paul).** La version aboutie de la branche — snap directionnel +
dépôt à l'ancre de l'aperçu (fourche A supprimée) + **ancrage de la mastercase sur la cellule
empoignée** + puce diag `c0..c4` (`d93b584`) — **fonctionne mieux** : le déplacement d'une pièce
posée se comporte correctement à l'écran. Branche **poussée sur `origin/snap-directionnel`** pour
que cowork la voie. Pas encore fusionnée dans `main`.

**Instrumentation retirée (2026-09-02).** Le diagnostic ayant rempli son office, `kDragDiag`,
`dragDiag()` et tous les points DRAGDIAG ont été supprimés : fichier `lib/common/drag_diag.dart`
(`git rm`), blocs `event=grab`/`event=snap`/`event=drop`, helper `_diagCandidates`, et la puce
`c0..c4` de la barre d'isométrie (`_mastercaseLabel` + `_buildMastercaseChip`). **La logique du
correctif A est intacte** — `setDragMastercase`, `_gestureAxis`, snap directionnel, dépôt à l'ancre
de l'aperçu. `analyze` 0 erreur. La branche est **prête à fusionner dans `main`** sous réserve d'un
dernier tour de test de Paul. (L'archive DRAGDIAG reste disponible sur `backup/deplacement-piece-c5306b5`.)

### Revue UI (2026-09-02) — #6 (répartition verticale) et #3 (cul-de-sac réversible)

Revue d'UI menée sur **simulateur** (captures `simctl` ; le ressenti du geste n'est **pas** jugé —
réservé au test device de Paul). Deux corrections retenues par Paul, appliquées sur `main`.

- **#6 — plateau ancré bas en portrait.** Sur un plateau quasi-carré (5×5) la hauteur excède la
  largeur : le plateau « flottait », centré entre deux marges. `pentoscope_board.dart` : portrait
  `Alignment.center` → `Alignment.bottomCenter` (paysage inchangé, `topCenter`). **Piège rattrapé au
  contrôle visuel** : le positionnement visuel (`Align`) et le hit-test du drag
  (`offsetY = (maxHeight − gridHeight)/2`, centré en dur, l.90) étaient **découplés** ; déplacer le
  seul visuel aurait fait tomber les dépôts sur les mauvaises cases. `offsetY` est désormais **couplé
  à l'alignement** (portrait = bas, paysage = haut) — ce qui corrige au passage une incohérence
  latente du paysage (offset centré alors que l'Align est `topCenter`, sans effet tant que le paysage
  n'a pas de rab vertical). Vérifié à l'écran : haut du plateau 26 % → 39 %.

- **#3 — cul-de-sac réversible par l'ampoule.** Choix de Paul : **laisser poser** même quand le
  compteur est à 0 (le joueur peut croire, à tort ou à raison, que c'est jouable), et faire du
  **voyant rouge le bouton de retour**. `pentoscope_game_screen.dart` : la branche `else` (ampoule
  rouge, `!hasPossibleSolution`, jusqu'ici sans effet) appelle `removePlacedPiece(placedPieces.last)`
  — **un appui = un coup en arrière, répétable** ; `removePlacedPiece` recalcule `hasPossibleSolution`,
  donc le rouge s'éteint dès que le plateau redevient soluble. Icône inchangée (ampoule jaune =
  indice, rouge = retour). `deleteCount` s'incrémente mais **n'entre pas** dans `calculateNote`
  (basée sur `hintCount`) → aucune pénalité. **Non encore validé au test device** (comportement gestuel).

`analyze` 0 erreur / 0 warning sur les deux fichiers. **Autres constats de la revue non traités** (à
arbitrer) : barre d'icônes principale hétérogène, rouge sémantiquement surchargé (alerte / suppression
/ mastercase), hiérarchie de boutons ambiguë à l'entrée multijoueur, titre « Multiplayer » en anglais.

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

**2026-09-02 — CLI → cowork (revue UI : #6 plateau ancré bas, #3 cul-de-sac réversible).** Revue
d'UI sur simulateur ; deux corrections validées par Paul et commitées sur `main`. **#6** : portrait
`Alignment.bottomCenter` pour le plateau **+ couplage `offsetY` du hit-test drag** (sinon dépôts
décalés — rattrapé au contrôle visuel, pas à la compilation). **#3** : le voyant rouge (cul-de-sac)
devient un retour arrière — un appui retire la dernière pièce (`removePlacedPiece`), la pose restant
autorisée en rouge. `analyze` 0. **#3 reste à valider au test device de Paul** (geste). Détail en
§ÉTAT « Revue UI ». Autres constats de la revue (barre d'icônes hétérogène, rouge surchargé,
hiérarchie de boutons multijoueur, i18n « Multiplayer ») **non traités**.

**2026-09-02 — CLI → cowork (snap directionnel : test de Paul concluant).** La branche
`snap-directionnel` (correctif A + dépôt à l'ancre de l'aperçu + ancrage mastercase sur la cellule
empoignée + puce diag `c0..c4`, `d93b584`) **fonctionne mieux à l'écran** selon Paul — le
déplacement d'une pièce posée est correct. Branche **poussée sur `origin/snap-directionnel`**, hors
`main`. À faire avant fusion : retirer la puce diag `c0..c4` (`kDragDiag`) et l'instrumentation
DRAGDIAG. Détail en §ÉTAT « snap-directionnel ».

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
