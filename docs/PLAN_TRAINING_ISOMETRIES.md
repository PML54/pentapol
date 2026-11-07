# Plan — Training « isométries » (8×5, fantôme pièce par pièce)

> Rédigé par cowork le 2026-10-09, après discussion avec Paul. Aucun code écrit.
> Ce plan **pilote du code** : il est commité DANS le même commit que ce code (CLAUDE.md §Protocole, règle 5).

## Ajustement approuvé — acuité et étoiles (2026-10-31, Codex)

- Bilan réduit à « Acuité : XX/10 », entier tronqué de `10 × minimum / réalisé`,
  plafonné à 10 ; aucun détail de coups, choix ou refus dans l’interface Isométries.
- Délai porté à 180 s, démarrant après l’aperçu du tiroir comme auparavant.
- Cinq étoiles avant 35 s, quatre avant 60 s, trois avant 90 s, deux avant 150 s,
  une avant 180 s. Les seuils sont stricts. La réussite fige temps et étoiles.
- À 180 s sans résolution : zéro étoile, « Temps écoulé », sélection annulée et
  manipulations bloquées. Accueil et Nouvelle partie restent accessibles.
- Ces décisions remplacent les mentions historiques des 60 s et du bilan détaillé ci-dessous.

## Ajustements approuvés et réalisation (2026-10-09, Codex)

- Paul réduit l'aperçu général du tiroir à une seconde (800 ms de parcours,
  200 ms de retour) puis démarre le chrono. Le compte à rebours attend la fin
  réelle de cet aperçu ; un geste peut l'interrompre. Animations réduites ou
  tiroir entièrement visible : démarrage direct sans mouvement inutile.

- Paul ajoute le bouton « Nouveau jeu » dans la barre, disponible pendant et
  après l'exercice, et un chrono dégressif de 60 s. Chrono vert puis orange à
  20 s, rouge et pulsation douce à 10 s ; animations réduites respectées. Réussite
  : chrono figé ; nouveau tirage : remise à 60 s. À zéro : 0 s rouge, grille et
  manipulation conservées (aucune défaite ni relance forcée demandée). Ces ajouts
  sont limités au Training isométries, sans changer le Training 3×5.
  Le chrono conserve son temps lors d'une rotation portrait/paysage. Validation :
  302 tests de la suite, puis quatre tests enrichis chrono/rotation réussis ;
  analyse sans erreur ni avertissement.
- Dernier choix de Paul : proposer l'ensemble des huit pièces dès l'entrée et
  à chaque relance. Plateau vide de pièces réelles, huit silhouettes pastel,
  aucune pièce préposée ni progression 2–5. Le Training 3×5 reste inchangé.
- Paul souhaite coller les pièces du tiroir sur la solution visible : toutes les
  silhouettes ont leur vraie couleur en pastel uniforme (35 % mélangé au blanc),
  sans numéro ni cible plus marquée. Remplissage dans n'importe quel ordre ;
  chaque pièce doit correspondre à sa propre silhouette, avec aimantation.
- Paul remplace le 5×5 par le format 8×5 existant (size8x5) : huit pièces au
  total, k=2 à 5 au tiroir et 8−k préposées verrouillées. Les mesures combinatoires
  du §3 et tools/verif/unicite_5x5.py restent des résultats historiques du 5×5,
  pas une vérification du 8×5. L'unicité n'est pas requise avec le fantôme.
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

1. Plateau **8×5** (choix révisé de Paul), mode `PentoscopeMode.training`, **compte à rebours 60 s**.
2. **Solution complète en couleurs pastel** : toutes les pièces manquantes sont
   visibles, dans leur couleur propre ; ordre de remplissage libre.
3. Dépôt hors fantôme : **simple refus** (la grille reste légale — invariant n°7).
4. Le jeu fonctionne **comme le jeu normal** : **pas d'aimantation** (décision du 2026-09-07 maintenue),
   suivi exact du doigt.
5. **Les huit pièces du tirage sont au tiroir**, en orientations aléatoires,
   avec leur solution entière visible en pastel. Aucune pièce n'est posée d'avance.

## 3. Faits historiques du 5×5 (rejouables)

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

**Exercice complet** : huit pièces à placer dès le départ. À la complétion,
tap : nouveau tirage complet à huit pièces ; double tap : ouvrir le Game.
L'alternance 1/2 pièces du Training 3×5 reste indépendante.

**Préparation** (à partir de `startRecreationalPuzzle`, qui part déjà d'un plateau complet issu de `applyHint`) :
- taille `size8x5`, remettre les huit pièces au tiroir **sans exiger l'unicité** ;
- aucune pièce préposée ; les pièces réussies sont **verrouillées** ;
- chaque pièce du tiroir part dans une orientation **différente** de sa cible (`_differentOrientation` existe) ;
- ne pas casser le Training 3×5 actuel (1 ou 2 pièces) : nouveau paramètre ou nouveau point d'entrée,
  au choix du CLI ; l'entrée « Training » de l'accueil garde son comportement.

**Guide** : toutes les silhouettes manquantes sont affichées en couleurs pastel
**avant** toute sélection. Chaque pièce peut être posée directement sur sa propre
silhouette, quel que soit l'ordre. Après un dépôt valide, la pièce posée retrouve
sa couleur pleine ; les autres silhouettes restent visibles.

**Refus** : le dépôt n'est valide que si les cases de la pièce sont **exactement** celles de sa propre silhouette.
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

Chaîne automatique de grilles (idée arcade, mise de côté, non rejetée) · 6×10 ·
duel · persistance des résultats de Training · pièces X, I, T, U comme cibles spécifiques (elles restent
dans les tirages, mais rien ne les sélectionne).

## 6. Critères d'acceptation

- `flutter analyze` : 0 erreur ; la suite de tests passe (297 au 2026-10-08) ;
- tests nouveaux : (i) dépôt hors fantôme refusé et plateau inchangé ; (ii) orientation de départ du tiroir
  toujours ≠ cible ; (iii) aucune écriture en base en Training ; (iv) huit pièces au tiroir, zéro posée,
  huit silhouettes visibles ; relance proposant de nouveau huit pièces ;
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
