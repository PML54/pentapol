# Plan — Training « isométries » (5×5, fantôme pièce par pièce)

> Rédigé par cowork le 2026-10-09, après discussion avec Paul. Aucun code écrit.
> Ce plan **pilote du code** : il est commité DANS le même commit que ce code (CLAUDE.md §Protocole, règle 5).

## Ajustements approuvés et réalisation (2026-10-09, Codex)

- Paul confirme le verrouillage des pièces préposées.
- Paul demande de garder l'aimantation : contrairement aux §2/§4 ci-dessous,
  le nouveau Training aimante vers la cible à une case de distance maximum sur
  chaque axe, uniquement pour la bonne pièce correctement orientée. Aucun effet
  sur le Game ni sur le Training 3×5. Le dépôt final reste exactement sur la cible.
- Entrée « Isométries » indépendante sur l'accueil, toujours en mode training ;
  le bouton Training existant et son alternance 1/2 pièces restent inchangés.
- X n'a pas d'autre orientation : les tirages de cet exercice excluent X pour
  garantir une orientation initiale différente même à k=5. Les autres pièces,
  y compris I/T/U, peuvent rester dans un tirage sans être ciblées spécialement.
- Les pièces déposées sont également verrouillées pour préserver les cibles déjà
  réussies. Mesures éphémères : compteur d'isométries/minimum cumulé (calculé
  par pièce), choix erronés et refus ; aucune table nouvelle.
- Nouveau marqueur isTraining : garde des records, sauvegardes, effacements et
  tentatives abandonnées pendant l'exercice. Le 3×5 reçoit aussi ce marqueur.
- Fichiers : provider, plateau, écran de jeu, accueil, ARB/générés EN/FR et
  test/isometry_training_test.dart. Aucun correctif tiroir ou Solo antérieur
  n'appartient à ce commit.
- Validation : 302 tests du dossier courant, 299 du contenu Git isolé ; analyse
  sans erreur ni avertissement dans les deux contextes (infos existantes).
  Les quatre niveaux sont testés sur le moteur réel, le fantôme EN/FR sur les
  deux orientations d'écran ; le tap de progression vérifie le niveau demandé,
  plafonné à cinq. Les deux scripts de vérification ont été exécutés.

## 1. Objectif

**N°1 : la maîtrise des isométries** — pas la dextérité, pas le raisonnement, pas le chrono.
Un débutant a deux difficultés : (a) **reconnaître** quelle pièce du tiroir correspond à la cible ;
(b) **l'orienter** (choisir la bonne icône parmi les 4). Ce niveau les isole : la place est donnée,
il ne reste que (a) et (b), puis le dépôt, qui fonctionne comme dans le jeu.

## 2. Décisions de Paul (2026-10-09)

1. Plateau **5×5**, mode `PentoscopeMode.training`, **sans compte à rebours**.
2. **Une pièce fantôme à la fois** : la cible de la pièce à poser s'affiche en grisé sur le plateau.
3. Dépôt hors fantôme : **simple refus** (la grille reste légale — invariant n°7).
4. Le jeu fonctionne **comme le jeu normal** : **pas d'aimantation** (décision du 2026-09-07 maintenue),
   suivi exact du doigt.
5. Des pièces sont **posées d'avance** ; le joueur place les k autres. Le tiroir ne contient que ces k pièces,
   en orientations aléatoires (comme le jeu : le tiroir = pièces du tirage non posées).
   ⚠️ Une version de la discussion parlait de « 12 pièces » : c'est faux sur le 5×5, le tirage a 5 pièces.

## 3. Faits mesurés (rejouables)

`python3 -I tools/verif/unicite_5x5.py` — retrouve **856 pavages / 45 tirages** (= `REFERENCE_TIRAGES.md`).
Unicité du complément quand on retire k pièces d'un pavage :

| k | cas à solution unique | pavages ayant ≥ 1 retrait unique |
|---|---|---|
| 1 | 4280 / 4280 | 856 / 856 |
| 2 | 7824 / 8560 | 856 / 856 |
| 3 | 6128 / 8560 | 856 / 856 |
| 4 | 1520 / 4280 | 512 / 856 |
| 5 | 0 / 856 | 0 / 856 |

`python3 -I tools/verif/iso_distances.py` — appuis minimaux entre orientations (4 icônes) :
**maximum 2** pour toute pièce. F, L, N, P, Y : 8 orientations (par départ : 1 à 0 appui, 4 à 1, 3 à 2).
V, W, Z : 4 (1/2/1). T, U : 4 (1/3/0). I : 2. X : 1 (aucun exercice).

**Conséquence** : avec un fantôme qui dicte la place, **l'unicité n'est pas nécessaire** (elle l'était pour
`startRecreationalPuzzle`, qui déduit sans fantôme). k peut donc aller jusqu'à 5. Le calcul de la table
sert seulement si on voulait un jour une variante sans fantôme (k ≤ 3 garanti).
Limite du calcul : je compte les compléments par les pièces retirées ; non vérifié que `countFrom` fait pareil.

## 4. Spécification

**Niveaux** : k = 2, 3, 4, 5 pièces à placer (k = 1 : une seule pièce au tiroir, rien à reconnaître → exclu).
Progression à la complétion, calquée sur `_trainingStage` (tap : niveau suivant ; double tap : ouvrir le Game).
Au-delà de k = 5, rester à 5.

**Préparation** (à partir de `startRecreationalPuzzle`, qui part déjà d'un plateau complet issu de `applyHint`) :
- taille `size5x5`, retirer k pièces **sans exiger l'unicité** et sans la contrainte « partagent un côté » ;
- les pièces restantes sont posées et **verrouillées** (proposition : non déplaçables, comme les pièces fixes
  des défis — à confirmer par Paul, sinon il peut les retirer et casser l'exercice) ;
- chaque pièce du tiroir part dans une orientation **différente** de sa cible (`_differentOrientation` existe) ;
- ne pas casser le Training 3×5 actuel (1 ou 2 pièces) : nouveau paramètre ou nouveau point d'entrée,
  au choix du CLI ; l'entrée « Training » de l'accueil garde son comportement.

**Fantôme** : le grisé de la pièce courante est affiché **avant** toute sélection (aujourd'hui la silhouette
n'apparaît qu'à la sélection : c'est le comportement à ne pas reprendre ici, sinon la reconnaissance est
donnée). Ordre : aléatoire parmi les pièces restantes. Après un dépôt valide, le fantôme suivant apparaît.

**Refus** : le dépôt n'est valide que si les cases de la pièce sont **exactement** celles du fantôme.
Pièce juste mais mal orientée sur le fantôme : refus aussi. Aperçu rouge pendant le glissé hors cible ;
au relâchement, la pièce retourne au tiroir **en gardant son orientation** (comportement de `cancelSelection`).
Pas de message (cohérent avec le grisage préventif des isométries, invariant n°7).

**Mesures** (Training : aucune écriture en base, `isTraining` / `_isRecreationalSetup` court-circuitent) :
- appuis d'isométrie réalisés **contre le minimum** par pièce (le moteur a `isometryCount` / `minIso` : à réutiliser) ;
- sélections de pièce **erronées** avant la bonne (compteur à créer — non vérifié qu'il existe) ;
- dépôts refusés ;
- affichage : une ligne de bilan à la fin, dans la barre du Training. Pas de chrono visible requis.

**i18n** : toute chaîne nouvelle dans `app_en.arb` ET `app_fr.arb`, puis `flutter gen-l10n` (règle 8).

## 5. Hors périmètre

Compte à rebours et chaîne de grilles (idée arcade, mise de côté, non rejetée) · aimantation · 6×10 ·
duel · persistance des résultats de Training · pièces X, I, T, U comme cibles spécifiques (elles restent
dans les tirages, mais rien ne les sélectionne).

## 6. Critères d'acceptation

- `flutter analyze` : 0 erreur ; la suite de tests passe (297 au 2026-10-08) ;
- tests nouveaux : (i) dépôt hors fantôme refusé et plateau inchangé ; (ii) orientation de départ du tiroir
  toujours ≠ cible ; (iii) aucune écriture en base en Training ; (iv) k pièces au tiroir, 5 − k posées ;
- header `// Modified:` à jour sur chaque `.dart` touché ;
- **test sur appareil par Paul** : `flutter run --release -d 00008150-000165D4027B401C`.
  Aucun agent ne juge le ressenti du geste, notamment du dépôt exact sans aimantation à k = 4 et 5.
  Pas de critère fondé sur la console (`debugPrint` supprimé en release).

## 7. Points à surveiller (objections non levées)

1. **Dépôt exact sans aimantation + refus** : un décalage d'une case est refusé. Peut frustrer un débutant ;
   non mesurable ici. Si Paul le juge trop dur : décision séparée, qui reviendrait sur celle du 2026-09-07.
2. **Un indice progressif** (le bon emplacement du tiroir clignote après hésitation) a été évoqué, pas décidé.
3. Paul juge la difficulté en expert : un essai avec un vrai débutant vaut plus que ce plan.
4. Les chiffres de §3 supposent que les 4 icônes sont de pures transformations de forme.
