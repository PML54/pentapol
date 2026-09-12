# Accueil guidé 3×5

> Révision du 2026-09-11 : rack défilant, sélection numérotée, quatre commandes du jeu
> et encouragements, puis sept variantes dont aucune pièce ne commence orientée comme la cible.
> Sept variantes validées par Paul le 2026-09-11 (« c’est OK »), enregistrées dans `5f910e9`.
> Contour renforcé et célébrations ajoutés ensuite : modifications locales, ressenti à apprécier sur iPhone.
> Sa validation du 2026-09-10 portait sur la version précédente (`72a16bf`).

## Parcours visible

L’application démarre sur `HomeScreen`. L’en-tête présente un bouton plein **Jouer** au centre,
à la place de l’icône personne. Il ouvre directement le jeu sans devoir terminer l’accueil.
Multijoueur et Défi sont à gauche, Records et Réglages à droite ; une place dédiée au bouton
central évite les chevauchements sur petit écran. Le titre PENTAPOL reste retiré.

Le parcours commence par « Fais défiler le rack », puis demande une pièce par son numéro.
Le joueur la touche pour la sélectionner ; sa silhouette apparaît alors sur le plateau.
Un maintien permet aussi de sélectionner et glisser directement, comme dans le jeu.
Aucun compteur ni libellé d’étapes n’est affiché.

## Sept petits entraînements

Les sept pavages existants sont utilisés : **PFU, PUN, PVL, PVU, PYU, TYL, VLN**.
L’accueil choisit un premier tirage au montage. Le bouton **« Training »**
en fin de parcours, de même style plein que Jouer, passe au tirage suivant : les sept configurations sont parcourues avant
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

Les consignes parlent d’**icônes**, y compris pour les rotations et les miroirs (EN : icons).
Les consignes EN/FR encouragent après sélection, pose et tentative ratée : « Bien ! »,
« Parfait ! », « Bien joué ! », « Tu y es presque ! », puis « Bravo… » au plateau rempli.
Depuis le 2026-09-12, la police est agrandie (22 à 28 pixels logiques selon la largeur),
en gras, et respecte l’agrandissement système. À la demande de Paul, le message défile désormais
en continu vers la gauche à 72 pixels logiques/s (vitesse doublée), sans pause ni arrêt après
un tour. Une seconde copie assure le raccord entre les tours ; le changement de consigne
redémarre immédiatement avec le nouveau texte.
La zone garde la hauteur de la plus longue consigne : ni le mouvement ni le changement de message
ne déplacent le plateau. Le bandeau laisse passer les gestes. En réduction des animations ou
navigation accessible, la consigne est fixe dès le départ et annoncée une seule fois aux aides vocales.
Rendu isolé dans `lib/pentoscope/home/guided_scrolling_message.dart`.
À la fin, Training lance un autre entraînement. Jouer reste dans l’en-tête, sans doublon
sous le plateau. Aucune boucle animée ne joue à la place du joueur.

## Contour et encouragements animés

Le plateau reprend le contour du jeu : gris foncé, épaisseur de 3 pixels logiques, coins
arrondis de 16 et ombre. Le contour est dessiné par-dessus les cases, sans réduire leur taille
ni déplacer les zones de dépôt.

Chaque pose acceptée déclenche une coche verte rebondissante et des confettis colorés pendant
850 ms, centrés sur la pièce posée. À la dernière pièce, l’effet est plus ample et dure
1 400 ms au centre du plateau. Une tentative refusée ne déclenche aucune célébration.
L’effet laisse passer les gestes et disparaît seul ; le plateau reste fixe.
Le réglage système de réduction des animations supprime cet effet. Les consignes et
encouragements textuels EN/FR restent disponibles.
Le rendu est isolé dans `lib/pentoscope/home/guided_success_celebration.dart`.

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

## Retours physiques

L’accueil suit le réglage `enableHaptics` du jeu : clic discret à la sélection et à une
transformation, impact léger à la prise, clic à l’entrée dans une cible valide, impact moyen
uniquement à la pose acceptée. Aucun retour répété à chaque déplacement dans la même cible,
et aucune confirmation de pose sur un dépôt refusé. Le retour automatique de prise de Flutter
est désactivé pour éviter un doublon et respecter la désactivation des vibrations.
La sensation réelle dépend de l’appareil ; le réglage coupe tous ces retours dans l’accueil.

## Architecture et limites

`lib/pentoscope/home/guided_home.dart` contient un état local et ses propres widgets de geste.
Il réutilise `PieceRenderer`, la géométrie et les transformations de `Pento`, ainsi que les sept pavages
présents dans `home_tirages_data.dart`. Il ne charge pas de solveur et n’écrit ni partie solo,
ni temps, ni score, ni record, ni progression. Le parcours n’est pas mémorisé entre lancements.

En portrait, les zones se suivent verticalement. En paysage, le plateau 3×5 reste vertical
à gauche et les commandes/rack sont à droite. La hauteur des consignes est réservée en fonction
des textes mesurés pour éviter les débordements et les mouvements du plateau.

Depuis le 2026-09-11, à la demande de Paul, l’icône et le mode séparé à une pièce sur 5×7
sont supprimés. Les sept parcours de cet accueil constituent l’entraînement de l’application.
L’accueil enseigne placement, rotation, miroir et remplissage ; l’explication du compteur
de solutions et des aides reste à traiter séparément (checklist de publication n°8).

## Vérifications

`test/guided_home_test.dart` vérifie les sept pavages sans chevauchement, l’orientation
initiale différente pour chaque pièce et la nécessité du miroir pour la dernière.
**88 parcours complets** : 40 prises PFU (cinq cases × quatre formats × deux langues) et
48 parcours supplémentaires (six tirages × quatre formats × deux langues).
Les tests couvrent défilement, sélection, transformations, dépôt, stabilité du plateau,
contour, déclenchement et disparition de la célébration,
le bouton Training plein, puis le passage au vrai tirage suivant avec réinitialisation des orientations.
Le retour du septième au premier est également vérifié.

Trois tests dans `test/guided_success_celebration_test.dart` vérifient que les gestes restent
possibles pendant les deux célébrations, que les effets se terminent et que la réduction des
animations est respectée.

Un parcours négatif contrôle les quatre opérations, les mauvais choix, les dépôts mal orientés
et hors plateau, puis la possibilité de réessayer sans perdre la pièce.
Quatre tests du bandeau vérifient message court/long, vitesse de 72 pixels/s, répétition sur
plusieurs tours, nouvelle consigne et arrêt lors du passage dans un mode accessible.
Les parcours de gestes utilisent la navigation accessible pour isoler leurs vérifications du défilement.
Deux tests de gestes réels contrôlent les appels haptiques, vibrations activées et désactivées :
sélection, transformation, prise, entrée dans la cible, mouvement interne, refus et pose acceptée.
Les formats de tests widget ne constituent pas une validation tactile sur appareil.

Vérification du 2026-09-12 : **188 tests réussis** en suite complète ; analyse du dépôt
complet : **0 erreur, 0 avertissement, 106 informations** (incluant les outils).
Quatre tests dans `test/home_play_test.dart` vérifient l’accès immédiat via Jouer, la conservation
de la partie et du chrono, et l’absence de chevauchement des boutons (petit portrait/paysage, EN/FR).
Les tests de l’accueil et le contrôle combinatoire des distances restent conservés.
Paul confirme « c’est OK » le 2026-09-11 pour cette version à sept variantes et orientations
à corriger. Le contour renforcé et les célébrations ont été ajoutés après ce retour.
Le mode séparé sur 5×7 a été retiré ensuite à la demande de Paul.
