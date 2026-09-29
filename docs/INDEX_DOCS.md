# Index de la documentation

> Actualisé le 2026-09-29 : ajout d'une colonne **Dernière révision**, référencement de
> `CLICLOUD.md`, `ENV_CLOUD.md` et `arch-pentapol-claude.md` ; passe d'audit du référencement.
> L'état courant et les passations sont dans [JOURNAL.md](JOURNAL.md).
> Cet index oriente la lecture ; il ne certifie pas un nouvel audit complet de chaque document.

> ⚠️ **Sur la colonne « Dernière révision ».** La date est celle du **dernier commit git**
> touchant le fichier, relevée le 2026-09-29 ; c'est un fait reproductible (« dernière
> modification du fichier »), **pas** une garantie de révision de fond. Dix docs partagent la
> date **2026-09-09** parce qu'un unique commit transverse `refactor(score)` les a effleurés :
> pour ceux-là, la révision de fond est antérieure et reste à confirmer par l'auteur. Chaque
> doc porte désormais la même information en tête (ligne `> _Dernière révision…_`). `JOURNAL.md`
> se date lui-même par sa §ÉTAT ; cet index par le présent en-tête.

## Suivi et règles

| Document | Dernière révision | Usage |
|---|---|---|
| [Journal](JOURNAL.md) | §ÉTAT (2026-09-25) | Livraison, validations, travail restant et trois dernières passations |
| [AGENTS.md](../AGENTS.md) | — | Consignes de projet lues par Codex, à la racine |
| [CLAUDE.md](../CLAUDE.md) | — | Consignes pour Claude ; faits et règles communs à maintenir cohérents |
| [Modus vivendi](MODUS_VIVENDI.md) | 2026-09-11 | Coordination, documentation et commits |
| [Checklist de publication](CHECKLIST_APPSTORE.md) | 2026-09-22 | Points avant les stores ; items livrés distingués des contrôles encore ouverts |

## Produit et interface

| Document | Dernière révision | Usage / état |
|---|---|---|
| [Accueil](ACCUEIL_GUIDE.md) | 2026-09-23 | Menu responsive avec démo 5×5 ; Training explicite en cycle, niveau 1 à une pièce puis niveau 2 à deux pièces voisines |
| [Barème Géométrie](BAREME_GEOMETRIE.md) | 2026-09-22 | Réglage, formule, Triche, reprise et préparation de la publication |
| [Fonctionnement](FONCTIONNEMENT.md) | 2026-09-23 | Synthèse actuelle en tête ; ancienne description détaillée explicitement historique |
| [Plan d’ergonomie](PLAN_ERGONOMIE_ICONES.md) | 2026-09-25 | Rangée permanente et grisage livrés ; vignettes et axes des miroirs encore ouverts |
| [Cahier des charges V1](CAHIER_DES_CHARGES_V1.md) | 2026-09-09 ⚠ | Périmètre produit et décisions ; défi et multijoueur inclus |
| [Maillots et défis](MANUEL_DEFIS_ET_MAILLOTS.md) | 2026-09-22 | Règles d’acuité, fautes, temps, records et classement |
| [Fiche App Store](FICHE_APP_STORE.md) | 2026-09-09 ⚠ | Textes destinés à la fiche de publication |
| [Indicateurs d’observation](INDICATEURS_OBSERVATION.md) | 2026-09-09 ⚠ | Mesures et observation du jeu |

## Références techniques

| Document | Dernière révision | Usage / état |
|---|---|---|
| [Base locale](BASE_LOCALE.md) | 2026-09-12 | Réglages, partie en cours et records ; vérifier le schéma dans le code avant intervention |
| [Localisation](I18N.md) | 2026-09-09 ⚠ | Procédure EN/FR, ARB et génération |
| [Déplacements](MEMO_DEPLACEMENT_PIECES.md) | 2026-09-11 | Correctifs actuels en tête ; ancien algorithme de snapping conservé comme historique |
| [Encodage des pièces](PIECES_ENCODING.md) | 2026-09-09 ⚠ | Géométrie, bits et orientations |
| [Isométries](REFERENCE_ISOMETRIES.md) | 2026-09-11 | Coûts, chiralité et contrôles rejouables |
| [Tirages](REFERENCE_TIRAGES.md) | 2026-09-09 ⚠ | Configurations solubles et comptes de référence |
| [Stockage des positions](ANALYSE_STOCKAGE_POSITIONS.md) | 2026-09-22 | Fondement combinatoire ; chemins historiques à distinguer du code actuel |
| [Services](services.md) | 2026-09-22 | Chaîne des tables de solutions ; références à l’ancien solveur à relire contre le code |
| [Architecture (Claude)](arch-pentapol-claude.md) | 2026-09-22 | Vue « ce qui est » de `lib/` (v1.0.7+7) ; descriptive, à vérifier contre le code |
| [Cloudflare](CLOUDFLARE_CONFIG.md) | 2026-09-24 | Configuration des services duel et défi |
| [Architecture du duel](DUEL_ISOM_ARCH.md) | 2026-09-09 ⚠ | Protocole et fonctionnement multijoueur |
| [Bilan du duel](BILAN_DUEL_ISOMETRIES.md) | 2026-09-09 ⚠ | Conception et avancement daté |

## Environnement d'exécution

| Document | Dernière révision | Usage / état |
|---|---|---|
| [Environnement cloud](ENV_CLOUD.md) | 2026-09-25 | Session Claude Code on the web : SDK Flutter non préinstallé, script de setup, `.g.dart` Drift, hôtes réseau |
| [Mémo sessions cloud](CLICLOUD.md) | 2026-09-25 | Modèle mental (runner CI, pas poste iOS), cycle de vie éphémère, tâches adaptées et risques |

## Plans anciens et outils

| Document | Dernière révision | Usage / limite |
|---|---|---|
| [Plan 6×10](PLAN_6X10_DANS_PENTOSCOPE.md) | 2026-09-09 ⚠ | Histoire des sources ; rectangles 5×12 et 4×15 abandonnés le 2026-09-08 |
| [Plan de persistance](PLAN_PERSISTANCE.md) | 2026-09-22 | Étapes implémentées ; ne pas traiter ses anciens statuts comme du travail restant |
| [Génération des icônes](ICON_GENERATION.md) | 2026-09-09 ⚠ | Ancienne procédure à vérifier contre les assets et outils actuels |

> ⚠ = date issue du commit transverse `refactor(score)` du 2026-09-09 ; révision de fond antérieure, à confirmer.

## Non référencé (hors index)

- `arch-pentapol-chatgpt.md` (dernier commit 2026-09-23) — **doublon d'architecture** non daté et non
  sourcé, concurrent de `arch-pentapol-claude.md`. Conservé sur disque à la demande de Paul (2026-09-29)
  mais **volontairement hors index** : une seule source d'architecture est référencée. À fusionner ou
  supprimer si l'écart avec `arch-pentapol-claude.md` n'apporte rien.

L’audit documentaire daté du 2026-09-07 reste dans l’historique Git. Ses alertes sur l’absence
de consentement au classement, de sauvegarde, de records ou de compteur 5×n ne sont plus un
état courant. Les validations sur appareil restent consignées comportement par comportement.
