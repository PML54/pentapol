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

Poussé jusqu'à `c242c88`.

---

## §PASSATIONS

> Les trois dernières seulement. Au-delà, `git log --oneline` dit la même chose en plus court.

**2026-08-31 — cowork → toi (dégraissage).** Sur constat chiffré : 8 676 lignes de
documentation pour 19 608 de code, 38 % des commits consacrés à la doc, et un protocole
appliqué uniformément — y compris à des correctifs de deux lignes. Cinq plans terminés
supprimés, §DÉCISIONS supprimée, règles vivantes remontées dans `CLAUDE.md`, règle de routage
ajoutée au `MODUS_VIVENDI`. **Aucun code touché.**
**À faire par le CLI** : `git rm` des cinq plans (liste dans la phrase de lancement).

**2026-08-30 — CLI → cowork.** Ergonomie tablette : étapes 1-4, §4d, §7, §8 et §9 appliquées
et testées. `flutter analyze` 0 warning.

**2026-08-30 — CLI → cowork.** Persistance étape 1 : ménage fait. `shared_peferences` déclaré
explicitement — il n'arrivait que transitivement par Supabase.
