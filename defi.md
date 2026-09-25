# Defi quotidien Pentapol

## Objectif

Le defi quotidien propose a tous les joueurs la meme serie de plateaux. Il doit encourager une
visite reguliere sans transformer Pentapol en jeu punitif. Le defi de la semaine actuel est
remplace : aucune compatibilite avec ses anciennes donnees n'est requise pendant le developpement.

## Serie du jour

- La journee de reference est la date UTC au format `YYYY-MM-DD`.
- La serie contient les neuf tailles, dans cet ordre : 3x5, 4x5, 5x5, 5x6, 5x7, 5x8, 5x9,
  5x10 puis 6x10.
- Seul le 3x5 est ouvert au debut de la journee.
- Terminer un plateau ouvre immediatement le suivant.
- Un algorithme versionne derive le masque de pieces et leur orientation a partir de la date et de
  la taille. Deux joueurs recoivent donc exactement le meme probleme.
- Le nombre exact de solutions est affiche avant le lancement de chaque plateau.
- La lampe d'aide est inactive pendant toute la partie classee.

## Tentative

- Une taille ne peut etre jouee qu'une seule fois par joueur et par jour.
- La tentative commence a l'ouverture du plateau.
- Quitter l'ecran ne l'annule pas : l'etat est conserve localement et la partie reprend au meme
  endroit.
- Un resultat n'est envoye et ne compte dans les classements que lorsque le plateau est rempli.
- Une taille terminee ne peut pas etre relancee le meme jour.
- Le changement de date remet la progression quotidienne a zero sans toucher au jeu Solo.

## Mesures et classements du jour

Chaque taille possede trois classements independants :

1. **Temps** : duree la plus courte.
2. **Acuité** : meilleur rapport entre les isometries minimales de la solution et les isometries
   reellement effectuees.
3. **Coups** : plus petit nombre de placements, deplacements et retraits effectues.

Les ex aequo partagent la meme performance ; le temps sert de departage secondaire pour l'acuite
et les coups. Le serveur n'accepte qu'un resultat par date, taille et identite joueur.

## Classements semaine et mois

Ils sont calcules exclusivement a partir des resultats quotidiens : il n'existe pas de second mode
de jeu hebdomadaire ou mensuel.

- Chaque resultat quotidien rapporte de 20 a 100 points selon son rang relatif pour la mesure.
- Les points des tailles terminees sont additionnes pour former le score du jour.
- Le classement semaine conserve les 5 meilleurs jours sur les 7 jours ISO (lundi a dimanche).
- Le classement mois conserve les 20 meilleurs jours du mois civil.
- Temps, acuite et coups restent trois classements distincts.
- Ce systeme recompense la regularite tout en permettant quelques jours d'absence.

## Donnees et confidentialite

- La publication reste soumise au consentement existant de partage des scores.
- Sans consentement, le joueur peut faire toute la serie et conserver sa progression locale, mais
  aucun resultat ni identifiant n'est envoye.
- Le serveur stocke : version, date UTC, taille, identite, pseudo, acuite, isometries, coups, fautes,
  temps et grille finale.
- La suppression des scores efface toutes les dates associees a l'identite.

## Noms des joueurs

- Un nom contient de 3 a 20 caracteres et au moins une lettre.
- Lettres accentuees, chiffres, espaces, apostrophes et tirets sont acceptes.
- Les espaces exterieurs sont retires et les espaces successifs sont regroupes.
- Les doublons sont autorises. Dans un meme classement, seuls les homonymes recoivent un suffixe
  stable de quatre caracteres derive de leur identifiant, par exemple `Paul · A7F2`.
- Les comparaisons d'homonymes ignorent la casse et les espaces exterieurs.

## Hors ligne et robustesse

- La definition est derivable localement afin que le defi reste jouable sans reseau.
- Une panne du classement ne bloque jamais la partie ni le deblocage du plateau suivant.
- La version de l'algorithme fait partie des cles serveur. Toute modification future des regles
  incremente cette version.

## Criteres d'acceptation du premier lot

- L'ecran affiche la date, les neuf tailles, leur nombre de solutions et leur etat
  (a jouer, en cours, verrouille ou termine).
- Le titre rappelle le jour de la semaine (`Defi du Lundi`) et une carte terminee recoit un fond
  vert pale.
- Les tailles se deverrouillent uniquement dans l'ordre.
- La lampe ne produit aucune action en mode defi.
- L'ecran de jeu porte un badge permanent `Mode Defi` avec un drapeau et ne propose pas de bouton
  de nouvelle partie.
- Apres une victoire et les eventuelles demandes de nom ou de consentement, l'app revient
  automatiquement a la liste des defis du jour.
- Une partie quittee est reprise, et une partie terminee est non rejouable le meme jour.
- Le score termine est envoye avec la date et le nombre de coups.
- Le Worker expose les classements quotidiens temps, acuite et coups ainsi que les agregats semaine
  et mois.
