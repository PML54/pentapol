# Présentation App Store — Pentapol (ébauche V1)

> Réécrite par cowork le 2026-09-03 sur le positionnement du **mémo commercial de Paul**,
> croisé avec les mesures du dépôt (`de7f576`). Le cahier des charges est dans
> `CAHIER_DES_CHARGES_V1.md` ; ce document n'est que la vitrine.
>
> ⚠️ **Aucune phrase de cette fiche n'annonce une fonction que l'application n'a pas.** Les
> paragraphes qui dépendent d'un chantier non terminé sont marqués **[conditionnel]** et ne
> doivent être collés dans App Store Connect que lorsque le chantier est livré.

Limites App Store Connect, par localisation : nom 30, sous-titre 30, mots-clés 100,
texte promotionnel 170, description 4 000.

---

## 1. Champs courts

| Champ | Proposition | Car. |
|---|---|---|
| **Nom** | `Pentapol : puzzle pentominos` | 28 |
| **Sous-titre** | `Voyez juste avant d'agir` | 24 |
| **Mots-clés** | `pentomino,polyomino,pavage,casse-tête,logique,spatial,grille,réflexion,solitaire,blocs` | 86 |

Le nom garde *pentominos* : c'est le mot que tapent ceux qui cherchent ce jeu, et le champ
le plus indexé. Le sous-titre porte la promesse et ne suppose aucun vocabulaire.

**Texte promotionnel** (modifiable sans repasser en revue — à utiliser pour annoncer une
mise à jour) :

```
Un puzzle où chaque pièce posée réduit le nombre de solutions encore atteignables.
Sans publicité, sans compte, sans connexion.
```

---

## 2. Description — socle livrable

```
Douze pièces. Une grille. Aucune case en trop.

Pentapol vous donne quelques pentominos — les douze figures que forment cinq
carrés accolés — et une grille qu'ils remplissent exactement. À vous de trouver
comment.

CHAQUE PLACEMENT RÉDUIT LES SOLUTIONS
C'est ce que Pentapol fait et que les autres ne font pas. À chaque pièce posée,
l'application recalcule combien de solutions restent atteignables depuis votre
position, et vous le montre. Le nombre descend pendant que vous jouez. Quand il
tombe à zéro, vous le savez sur-le-champ — au lieu de vous en apercevoir dix
minutes plus tard, la grille à moitié pleine.

TOURNEZ MOINS, VOYEZ MIEUX
Une pièce ne rentre pas ? Faites-la pivoter d'un quart de tour, ou retournez-la.
Quatre transformations suffisent à lui donner n'importe quelle orientation.
Pentapol compte vos rotations et vos retournements — et vous dit combien il en
fallait au minimum. Le meilleur joueur n'est pas le plus rapide : c'est celui qui
manipule le moins parce qu'il a vu avant de toucher.

DE TROIS PIÈCES À LA GRILLE COMPLÈTE
Le premier niveau tient dans trois pièces. Le dernier est la grille 6 × 10 avec
les douze : 9 356 façons de la remplir, aucune qui se trouve par hasard. Entre
les deux, 996 configurations réparties sur huit niveaux — chacune vérifiée
résoluble avant de vous être proposée. Rien n'est laissé au générateur.

QUAND VOUS BLOQUEZ
Un indice pose une pièce à sa place — mais une partie résolue sans aide compte
toujours plus qu'une partie résolue avec. Sur la grande grille, vous pouvez aussi
parcourir toutes les solutions encore compatibles avec ce que vous avez posé.

CE QUE PENTAPOL NE FAIT PAS
Pas de publicité. Pas d'achat intégré. Pas de compte. Pas de vies à attendre.
Rien ne quitte votre appareil, et tout fonctionne sans connexion.
```

**Ce paragraphe suppose deux chantiers du cahier des charges** : l'oracle du minimum
d'isométries (§4.2) pour « combien il en fallait au minimum », et le compteur affiché à
symétrie près (§2.3). Si l'un des deux n'est pas livré, retirer la phrase correspondante
plutôt que de la nuancer.

---

## 3. Blocs conditionnels

**[conditionnel — sauvegarde de la partie en cours livrée]**
```
Fermez l'application au milieu d'une grille : vous la retrouverez telle quelle.
```

**[conditionnel — records personnels livrés]**
```
VOS RECORDS
Meilleur temps, minimum de rotations, résolutions sans aide : Pentapol garde vos
records par configuration. Vous vous mesurez à vous-même, sans que personne
d'autre n'ait à être connecté.
```

**[conditionnel — classement asynchrone livré, et §9 du cahier des charges tranché]**
```
COMPAREZ VOTRE RÉSOLUTION
Envoyez votre résultat sur une configuration commune et comparez-le : trois
maillots indépendants — acuité, fautes (culs-de-sac), temps. L'envoi est
facultatif et désactivé par défaut.
```
Si ce bloc est publié, la phrase « rien ne quitte votre appareil » du §2 doit devenir
« rien ne quitte votre appareil tant que vous n'envoyez pas de score », et la déclaration
App Privacy cesse d'être « aucune donnée collectée ».

**[conditionnel — duel temps réel conservé, ce qui n'est pas la recommandation]**
```
EN DUEL
Affrontez un autre joueur sur la même configuration, en temps réel. Une connexion
est nécessaire pour ce mode.
```

---

## 4. Ce que la fiche n'annonce pas, volontairement

- **Les six réglages inertes** (taille des icônes, numéros de pièce, quadrillage, animations,
  opacité, couleur de la barre) : ils s'enregistrent sans rien changer — `CHECKLIST_APPSTORE`
  point 16. Ne jamais écrire « personnalisation complète ».
- **Le navigateur de solutions** est annoncé sur la grande grille seulement : c'est ce que
  fait le code (`state.puzzle?.size.table != null`).
- **« 996 puzzles » tout court** : les 996 couvrent huit niveaux ; le neuvième en a un.
  La formulation retenue le dit.
- **« Tirage aléatoire »** : remplacé par « vérifiée résoluble avant de vous être proposée »,
  qui est exact et vaut mieux.

---

## 5. Scénario de captures

Six captures, lisibles sans lire. **Les nombres montrés doivent être ceux d'une partie
réelle** — une capture non représentative est un motif de rejet.

| # | Texte | Ce que l'image montre | Contrainte mesurée |
|---|---|---|---|
| 1 | **Douze pièces. Une grille.** | la 6 × 10 en cours, tiroir visible | — |
| 2 | **Chaque placement réduit les solutions.** | le compteur en gros, une suite réelle | **prendre les chiffres du 6 × 10** (9 356 au départ) ou d'un niveau 7-8. Aux niveaux 1 à 3 le compteur part de 4, 8 ou 16 : un « 128 » y serait faux |
| 3 | **Tournez moins. Voyez mieux.** | la barre d'isométries, compteur de rotations | montrer l'acuité à côté du nombre, sinon le nombre brut ne veut rien dire |
| 4 | **Résolvez sans aide.** | bilan de fin : `acuité 86 % / 0 faute / 03:42` | exige `minIso` et l'acuité, cahier des charges §4.2 (refonte « A » : trois maillots acuité/fautes/temps) |
| 5 | **996 configurations, jusqu'à la 6 × 10.** | la grille de choix des niveaux | ne pas écrire « 996 sur 9 niveaux » |
| 6 | **[conditionnel]** **Comparez votre résolution.** | le classement | seulement si le classement est livré |

Si le classement n'est pas dans la V1, la capture 6 devient une vue du 6 × 10 résolu — la
plus belle image que le jeu produise.

---

## 6. Rappels avant de remplir App Store Connect

1. **`PRODUCT_BUNDLE_IDENTIFIER = com.example.pentapol`** (`ios/Runner.xcodeproj/project.pbxproj`
   l. 473). Apple refuse le préfixe `com.example` ; le téléversement échoue avant la revue.
   Absent de la checklist, à y ajouter.
2. **Une seule localisation.** `app_fr.arb` et `app_en.arb` existent mais `AppLocalizations`
   n'est référencé nulle part dans `lib/` : l'interface est en français en dur. Une fiche
   anglaise sans interface anglaise se paie en avis d'anglophones déçus.
3. **Politique de confidentialité** : une URL est exigée même pour une application qui ne
   collecte rien.
4. Les autres bloquants restent ceux de `CHECKLIST_APPSTORE.md` §1.
