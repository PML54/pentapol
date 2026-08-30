# Checklist — avant la première soumission App Store

> Ouverte le 2026-08-30. **Ce fichier s'allonge au fil du travail** : dès qu'une décision
> crée une dette qui ne doit pas partir en production, elle s'inscrit ici, avec sa raison.
> C'est le seul endroit où ces dettes sont rassemblées — le journal les disperse.
>
> État de l'application : **non publiée**, `version: 1.0.0+1`. Paul a déjà publié cinq
> applications ; ce document ne couvre donc **pas** la mécanique de soumission (certificats,
> App Store Connect, captures), seulement ce qui est spécifique à Pentapol.

---

## 1. Bloquants techniques

| # | Point | Pourquoi | Où |
|---|---|---|---|
| 1 | **`flutter test` est rouge** | `test/widget_test.dart` est le **template par défaut** de Flutter : il cherche un compteur et une icône `+` qui n'existent pas. Il ne peut que planter. À réparer ou à supprimer — mais pas à laisser | `test/widget_test.dart` |
| 2 | **Retirer `supabase_flutter`** | Dépendance inutilisée (`bootstrap.dart` : « Vide - Supabase n'est pas utilisé »). Poids du binaire, et surtout une déclaration **App Privacy** à remplir pour un service qu'on n'utilise pas | `pubspec.yaml`, `lib/bootstrap.dart` |
| 3 | **Retirer la réécriture destructive de la base** | `MigrationStrategy` destructive + `schemaVersion` : légitime tant que rien n'est publié, **mine** après. Elle effacerait les records des joueurs, et seulement le jour où le schéma bougera — des mois plus tard | `lib/database/settings_database.dart`, plan `PLAN_PERSISTANCE.md` §5 |
| 4 | **Ajouter un rapport de crash** | Sans ça, publication à l'aveugle : ceux qui plantent désinstallent sans rien dire. Aucun outil aujourd'hui — ni Crashlytics, ni Sentry | `pubspec.yaml`, `main.dart` |
| 5 | **Sauvegarder la partie en cours** | Quitter l'app au milieu d'un 6×10 perd tout. Sur mobile c'est un défaut d'usage de premier ordre | `PLAN_PERSISTANCE.md` §2 |
| 6 | **Décider du sort du multijoueur** | Il dépend d'un worker Cloudflare hors dépôt, **URL en dur**, sans interrupteur distant. Le jour où il tombe, l'app publiée garde un bouton mort — et un lobby sans joueurs est pire que pas de lobby. *Recommandation cowork : le couper pour la v1* | `pentoscope_mp_provider.dart` l.32-35 |
| 7 | **Incrémenter le build number** | `version: 1.0.0+1`. Chaque téléversement demande un numéro de build supérieur au précédent | `pubspec.yaml` |

---

## 2. Bloquants produit

Ceux-là ne font pas planter l'app. Ils décident si quelqu'un la garde.

| # | Point | Pourquoi |
|---|---|---|
| 8 | **Aucun onboarding** | Le tutoriel a été supprimé le 2026-08-28 (décision 5). Un inconnu ouvre l'app, voit un plateau et une barre de pièces, et personne ne lui dit ce qu'est une isométrie ni pourquoi le chiffre en haut change. Ça se paie en désinstallations dans les trente premières secondes |
| 9 | **Le mode phare n'a qu'un seul puzzle** | Le 6×10, c'est 12 pièces sur 12 : un seul tirage possible, toujours le même. Aucune raison de revenir demain. Les tables **5×12 et 4×15** (plan 6×10 §5) sont le remède direct — elles feraient trois grands plateaux au lieu d'un |
| 10 | **Le différenciateur et la rejouabilité sont sur deux modes différents** | Le compteur de solutions compatibles en temps réel est ce que l'app a de rare et de vraiment intéressant. Il n'existe que sur les rectangles complets. Les puzzles à pièces tirées, qui portent la variété, n'ont qu'un booléen. Résoudre le point 9 résout celui-ci |
| 11 | **Records et progression** | Rétablis par `PLAN_PERSISTANCE.md` §4 après avoir été abandonnés (décision 32, prise pour un outil personnel). Sans eux, une partie finie ne compte pas demain |

---

## 3. Conformité

| # | Point | Note |
|---|---|---|
| 12 | **App Privacy** | À remplir en fonction de ce qui est réellement collecté. Après le retrait de Supabase et sans rapport de crash tiers, l'app ne collecte **rien** — c'est la déclaration la plus simple qui soit, et un argument à ne pas gâcher. Un outil de crash change cette réponse : le choisir en connaissance de cause |
| 13 | **Suppression de compte** | Sans création de compte, sans objet. Le jour où un classement partagé arrive, Apple **exige** la suppression du compte depuis l'app. À garder en tête avant de se lancer dans le connecté |
| 14 | **RGPD** | Aujourd'hui : aucune donnée ne quitte l'appareil, sauf en multijoueur. Le point 6 est donc aussi un point de conformité |
| 15 | **Politique de confidentialité** | Une URL est demandée à la soumission, même pour une app qui ne collecte rien |

---

## 4. Recommandé, non bloquant

- Cinq fichiers orphelins dans `lib/` — `bigint_plateau`, `shape_recognizer`,
  `ui_layout_provider` (et ses 9 providers), `solution_collector`, `pentomino_solver` par
  ricochet. Sans effet à l'exécution, mais ils alourdissent toute relecture future.
- `flutter pub add collection` — lint `depend_on_referenced_packages` préexistant.
- La preview cyan morte dans `pentoscope_board.dart` (lit `state.isSnapped`, que personne
  n'écrit).
- Le paramètre `cellSize` de `PieceRenderer` — la miniature signalée par Paul au déplacement
  d'une pièce, taille de case codée en dur à 22 px alors que celle du plateau est calculée.

---

## 5. Ce que cowork ne peut pas juger

À dire franchement, pour que personne ne s'appuie sur un avis qui n'existe pas : **cowork n'a
jamais vu l'application tourner.** Ni les graphismes, ni la fluidité, ni le ressenti d'un
glissé de pièce, ni la lisibilité sur un écran réel. Pour un jeu de puzzle, c'est l'essentiel
de ce qui décide de son sort, et rien dans ce document ne l'évalue.

Deux défauts visibles ont été trouvés par Paul en deux sessions de jeu occasionnel (le
chronomètre qui ne s'arrête pas, le bilan qui masque le plateau). Cela donne une idée de la
densité de ce qui reste : **ça se trouve en jouant, pas en relisant du code.**
