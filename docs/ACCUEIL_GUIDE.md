# Accueil guidé 3×5

> Révision du 2026-09-11 : rack défilant, sélection numérotée, quatre commandes du jeu
> et encouragements, puis sept variantes dont aucune pièce ne commence orientée comme la cible.
> Version validée par Paul le 2026-09-11 (« c’est OK »), après invitation à l’essayer sur iPhone. Modifications locales.
> Sa validation du 2026-09-10 portait sur la version précédente (`72a16bf`).

## Parcours visible

L’application démarre sur `HomeScreen`. L’en-tête conserve Jouer (personne verte,
plus grande, au centre), Multijoueur, Entraînement, Défi, Records et Réglages.
Le titre PENTAPOL a été retiré. Jouer reste accessible sans terminer le parcours.

Le parcours commence par « Fais défiler le rack », puis demande une pièce par son numéro.
Le joueur la touche pour la sélectionner ; sa silhouette apparaît alors sur le plateau.
Un maintien permet aussi de sélectionner et glisser directement, comme dans le jeu.
Aucun compteur ni libellé d’étapes n’est affiché.

## Sept petits entraînements

Les sept pavages existants sont utilisés : **PFU, PUN, PVL, PVU, PYU, TYL, VLN**.
L’accueil choisit un premier tirage au montage. Le bouton **« Un autre entraînement »**
en fin de parcours passe au tirage suivant : les sept configurations sont parcourues avant
répétition, y compris le retour du dernier au premier. Ce choix est local, sans persistance.

Toutes les pièces démarrent dans une orientation géométriquement différente de leur silhouette.
Les deux premières demandent une rotation ; la dernière est une pièce chirale qui nécessite
un miroir. La consigne s’adapte aux transformations réalisées par le joueur. Exemple PFU :

| Ordre interne (non affiché) | Pièce | Geste enseigné |
|---|---|---|
| 1 | U, n°7 | Tourner, puis déposer |
| 2 | P, n°2 | Tourner, puis déposer |
| 3 | F, n°4 | Retourner en miroir, puis déposer |

Le rack place la première pièce demandée en dernier pour inviter à explorer. Il défile
horizontalement en portrait et verticalement en paysage, avec une barre de défilement.
Les pièces restent numérotées et disponibles ; un mauvais choix invite à retrouver le numéro
demandé. Une pièce posée quitte le rack. Les emplacements réservent assez de place pour les
pièces longues dans toutes leurs orientations, sans changer de taille lors d’une rotation.

Les quatre icônes proviennent de `GameIcons`, avec le même ordre, les mêmes couleurs et la
même taille partagée que le jeu : rotation antihoraire, horaire, miroir horizontal, vertical.
Les quatre boutons sont gris sans sélection et actifs sur une pièce du rack. Les opérations
utilisent `Pento`. Le joueur peut essayer, revenir en arrière et corriger son orientation.

Les consignes EN/FR encouragent après sélection, pose et tentative ratée : « Bien ! »,
« Parfait ! », « Bien joué ! », « Tu y es presque ! », puis « Bravo… » au plateau rempli.
Leur hauteur est réservée sur la consigne la plus haute ; aucun changement de message ne
modifie la position du plateau.
À la fin, le joueur peut jouer ou lancer un autre entraînement. Aucune boucle animée ne joue à sa place.

## Prise et dépôt

La pièce suit le doigt dès sa prise. Le délai de prise et le rapport de taille rack/plateau
proviennent des réglages. Un contour rouge et un remplissage atténué indiquent que le dépôt
n’est pas accepté ; l’aspect redevient normal dans la zone cible avec la bonne orientation.

Le joueur peut saisir **n’importe laquelle des cinq cases**. Pour accepter le dépôt :

- la forme doit correspondre à la cible (comparaison géométrique, pas d’index arbitraire) ;
- le doigt doit être sur le plateau, dans la boîte englobante de la silhouette augmentée
  d’un quart de case de chaque côté.

La pièce se place alors exactement sur le modèle. La case saisie sert à l’ancrage visuel
pendant le déplacement, sans imposer une visée exacte sur sa case d’arrivée.
Cette assistance est propre à l’accueil ; elle ne modifie pas le placement dans le jeu.

## Architecture et limites

`lib/pentoscope/home/guided_home.dart` contient un état local et ses propres widgets de geste.
Il réutilise `PieceRenderer`, la géométrie et les transformations de `Pento`, ainsi que les sept pavages
présents dans `home_tirages_data.dart`. Il ne charge pas de solveur et n’écrit ni partie solo,
ni temps, ni score, ni record, ni progression. Le parcours n’est pas mémorisé entre lancements.

En portrait, les zones se suivent verticalement. En paysage, le plateau 3×5 reste vertical
à gauche et les commandes/rack sont à droite. La hauteur des consignes est réservée en fonction
des textes mesurés pour éviter les débordements et les mouvements du plateau.

L’**entraînement** accessible par son icône est un autre parcours : une pièce sur **5×7**,
avec le provider et l’écran de jeu partagés. Voir [son plan](PLAN_MODE_ENTRAINEMENT.md).
L’accueil enseigne placement, rotation, miroir et remplissage ; l’explication du compteur
de solutions et des aides reste à traiter séparément (checklist de publication n°8).

## Vérifications

`test/guided_home_test.dart` vérifie les sept pavages sans chevauchement, l’orientation
initiale différente pour chaque pièce et la nécessité du miroir pour la dernière.
**88 parcours complets** : 40 prises PFU (cinq cases × quatre formats × deux langues) et
48 parcours supplémentaires (six tirages × quatre formats × deux langues).
Les tests couvrent défilement, sélection, transformations, dépôt, stabilité du plateau,
Jouer, puis le passage au vrai tirage suivant avec réinitialisation des orientations.
Le retour du septième au premier est également vérifié.

Un parcours négatif contrôle les quatre opérations, les mauvais choix, les dépôts mal orientés
et hors plateau, puis la possibilité de réessayer sans perdre la pièce.
Les formats de tests widget ne constituent pas une validation tactile sur appareil.

Vérification du 2026-09-11 : **166 tests réussis** en suite complète ; analyse du dépôt
complet : **0 erreur, 0 avertissement, 106 informations** (incluant les outils).
Paul confirme « c’est OK » le 2026-09-11 pour cette version à sept variantes et orientations
à corriger. Cette validation ne s’étend pas au mode entraînement distinct sur 5×7.
