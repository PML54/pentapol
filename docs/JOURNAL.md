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

Un seul module de jeu, **Pentoscope** : tailles `size3x5`…`size9x5` (pièces tirées au hasard,
solutions calculées à la volée) plus `size6x10` (rectangle complet, adossé aux 9356 solutions
pré-calculées). Plus le **multijoueur**, qui réutilise son provider. Démarrage direct sur
`PentoscopeGameScreen`, pas d'écran d'accueil. **19 608 lignes** de Dart.

### Chantiers terminés

- **Suppression du mode classique** — −3197 lignes, module, widgets, écran d'accueil.
- **Le 6×10 dans Pentoscope** — temps 1 et 2, `SolutionSource`, compteur de solutions.
- **Bilan de fin de partie** — bandeau non modal, score retiré, chronomètre corrigé.
- **Ergonomie hors plateau** — tailles ancrées sur le plateau, barre d'actions unique pour les
  deux orientations, ordre des zones aligné, écran de réglages minimal.
- **Persistance, étape 1** — Supabase, `bootstrap.dart` et `DatabaseDebugScreen` retirés.

Leurs plans ont été **supprimés** une fois appliqués et testés (`MODUS_VIVENDI` §5).

### Chantiers ouverts

| chantier | document | reste à faire |
|---|---|---|
| **Persistance** | `PLAN_PERSISTANCE.md` | étapes 2 à 4 : schéma + réécriture destructive, records, **partie en cours** |
| **Tables 5×12 et 4×15** | `PLAN_6X10_DANS_PENTOSCOPE.md` §5 | préalable strict : `PentominoSolver.maxSeconds` paramétrable **et** troncature observable |
| **Mise sur l'App Store** | `CHECKLIST_APPSTORE.md` | 7 bloquants techniques, 4 produit, 4 conformité — s'allonge au fil du travail |

**Priorité recommandée** : étape 4 de la persistance (la partie en cours n'est pas sauvegardée
— quitter l'app au milieu d'un 6×10 perd tout), puis la checklist App Store.

### Documentation

`FONCTIONNEMENT.md` est la description de référence de l'application — elle absorbe depuis
le 2026-08-31 l'ancien `PENTOSCOPE.md`, devenu un doublon partiel une fois qu'il n'est resté
qu'un module de jeu. `UI_PROPERTIES_GUIDE.md`, guide Flutter générique sans rapport avec
l'état du projet, est supprimé.

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

Poussé jusqu'à `8746b04` (regroupement des constantes). **Non poussés** : `f1f26cf` (suppression
de la difficulté) et ce commit de journal (qui joint la mise à jour de `CHECKLIST_APPSTORE`).

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-08-31 — CLI → cowork (suppression de la difficulté).** Chantier fait en un commit
(`f1f26cf`). `PentoscopeDifficulty`, `generateEasy`/`generateHard`, le `SegmentedButton` du
dialogue retirés. `generate` fait désormais **une seule passe** (`findSolutionFrom` sur plateau
vide) et stocke la solution trouvée → « afficher la solution » **marche maintenant hors 6×10**.
Boucle bornée (200) au lieu d'infinie ; pas de timeout au solveur (question « insoluble vs pas
fini » renvoyée au chantier de mesure). `solutionCount` → `int?` ; `CurrentGame.solutionCount`
nullable, `schemaVersion` 2→3 (destructif, pas de migration). `findAllSolutions` **gardée**
(outil de génération + mp). `flutter analyze` 0 error. CHECKLIST : cowork ajoute le point 17
(« afficher la solution » toujours mort sur le **6×10**) et étoffe le point 10 (futur
`ListSolutionSource`, hors périmètre). **Dû par Paul** : test sur les petites tailles (tirage,
« afficher la solution ») + réécriture destructive de la base au 1er lancement.

**2026-08-31 — CLI → cowork (fix iOS + dégraissage exécuté).** `git rm` des 7 documents fait
(`ebdf7ab`). Puis bug iOS corrigé (`3f09e1d`) : le body de `pentoscope_game_screen` n'avait
aucun `SafeArea` — en paysage (`appBar: null`) le corps passait sous l'îlot dynamique, en
portrait la barre sous l'indicateur d'accueil. Body enveloppé dans un `SafeArea` (tous bords,
pas de padding directionnel) ; le `LayoutBuilder` voit les contraintes réduites. `flutter
analyze` 0 warning. **Dû par Paul** : test iPhone, les deux sens de rotation en paysage + portrait.
Puis réglage à l'œil (`034ddff`) : barre de pièces trop grosse → `k` 0.45→0.35 et `_kSliderPad`
32→20. Puis regroupement (`af2f5e0`) des **7 valeurs de réglage visuel** en un bloc de constantes
nommées en tête de `pentoscope_game_screen.dart` (comportement inchangé ; `kPieceToBoardCellRatio`
rapatrié de `pentoscope_board.dart`, d'où un import croisé board→screen — smell léger, alternative
`config/` proposée à Paul). Idée d'un panneau de tuning on-device en discussion (phrase à cowork).

**2026-08-31 — cowork → toi (dégraissage).** Sur constat chiffré (8 676 l. de doc pour 19 608
de code). Cinq plans terminés supprimés, §DÉCISIONS supprimée, règles vivantes remontées dans
`CLAUDE.md`, routage ajouté au `MODUS_VIVENDI`. **Aucun code touché.**
