# Mémo Terminale — visualiser les isométries de Pentapol

> _Créé le 2026-09-30. Mémo pédagogique : puissances, exponentielle complexe et compositions._

> Version mathématique typographiée avec aperçu PDF :
> [`MEMO_ISOMETRIES_TERMINALE.tex`](MEMO_ISOMETRIES_TERMINALE.tex).

## Objectif

Pentapol permet quatre gestes élémentaires sur une pièce :

- rotation d'un quart de tour dans un sens ;
- rotation d'un quart de tour dans l'autre sens ;
- symétrie axiale horizontale ;
- symétrie axiale verticale.

Ce mémo montre comment représenter les huit transformations possibles avec :

1. les puissances `r^k` ;
2. les nombres complexes et `e^(iθ)` ;
3. une écriture unique pour les rotations et les symétries.

Le repère utilisé est le repère mathématique habituel : `x` vers la droite et `y` vers le haut.
L'écran d'un téléphone compte généralement `y` vers le bas ; cela inverse l'apparence horaire ou
antihoraire dans le code, mais ne change aucune relation entre les transformations.

## 1. Placer le centre de la pièce à l'origine

On représente chaque point de la pièce par le nombre complexe :

```text
z = x + iy
```

Le centre de rotation est l'origine `O`. Si le centre réel de la pièce est un point `c`, on commence
par étudier `z - c`, puis on remet le centre à la fin :

```text
z' = c + transformation(z - c)
```

Dans la suite, on suppose donc simplement que `c = 0`.

## 2. Pourquoi l'exponentielle décrit une rotation

La formule d'Euler donne :

```text
e^(iθ) = cos(θ) + i sin(θ)
```

Multiplier `z` par `e^(iθ)` fait tourner le point d'un angle `θ` autour de l'origine :

```text
Rθ(z) = e^(iθ) z
```

Dans Pentapol, les angles sont uniquement des multiples de `π/2`. Posons :

```text
r(z) = e^(iπ/2) z = iz
```

`r` est donc la rotation mathématique antihoraire d'un quart de tour.

## 3. Le cycle des quatre rotations

Comme `i² = -1` et `i⁴ = 1`, les puissances de `i` se répètent tous les quatre pas :

```text
                       i = e^(iπ/2)
                       ↑
      -1 = e^(iπ) ←── 0 ──→ 1 = e^(i0)
                       ↓
                      -i = e^(i3π/2)
```

La flèche circulaire mentale est :

```text
1 → i → -1 → -i → 1 → ...
```

| Puissance | Exponentielle | Multiplicateur | Angle | Coordonnées obtenues |
|---|---|---|---|---|
| `r^0` | `e^(i0)` | `1` | `0` | `(x, y)` |
| `r^1` | `e^(iπ/2)` | `i` | `π/2` | `(-y, x)` |
| `r^2` | `e^(iπ)` | `-1` | `π` | `(-x, -y)` |
| `r^3` | `e^(i3π/2)` | `-i` | `3π/2` | `(y, -x)` |
| `r^4` | `e^(i2π)` | `1` | retour à `0` | `(x, y)` |

Les exposants se calculent donc **modulo 4** :

```text
r^5 = r
r^7 = r^3
r^10 = r^2
r^(-1) = r^3
```

## 4. Une symétrie demande la conjugaison

Une multiplication par `e^(iθ)` produit toujours une rotation. Elle ne peut pas, à elle seule,
produire une symétrie axiale.

La conjugaison complexe change le signe de la partie imaginaire :

```text
z = x + iy
conjugué(z) = x - iy
```

Géométriquement, c'est la symétrie par rapport à l'axe horizontal. Notons-la `s` :

```text
s(z) = conjugué(z)
s² = identité
```

Pour un axe faisant un angle `φ` avec l'axe horizontal, la formule générale est :

```text
Sφ(z) = e^(2iφ) conjugué(z)
```

Le facteur `2φ` vient du fait que l'axe se situe à mi-chemin entre un rayon et son image réfléchie.

## 5. Les quatre symétries du carré

Avec `r(z) = iz` et `s(z) = conjugué(z)`, toutes les symétries s'écrivent `r^k s` :

```text
(r^k s)(z) = i^k conjugué(z)
```

Dans un produit comme `rs`, on applique d'abord l'opération la plus à droite : `s`, puis `r`.

| Écriture | Formule complexe | Coordonnées | Axe de symétrie |
|---|---|---|---|
| `s` | `conjugué(z)` | `(x, -y)` | horizontal |
| `rs` | `i conjugué(z)` | `(y, x)` | diagonale `y = x` |
| `r²s` | `-conjugué(z)` | `(-x, y)` | vertical |
| `r³s` | `-i conjugué(z)` | `(-y, -x)` | diagonale `y = -x` |

Pentapol possède des boutons directs pour `s` et `r²s`, les axes horizontal et vertical. Les deux
symétries diagonales sont obtenues par composition avec une rotation d'un quart de tour.

## 6. Les huit transformations de Pentapol

Le groupe des symétries du carré contient exactement huit éléments :

```text
Rotations   : 1, r, r², r³
Réflexions : s, rs, r²s, r³s
```

On l'appelle ici `D4`, le groupe diédral du carré. Il contient quatre rotations et quatre
réflexions, donc huit transformations au total.

| Transformation | Lecture | Nombre minimal de boutons génériques |
|---|---|---:|
| `1` | ne rien changer | 0 |
| `r` | quart de tour antihoraire | 1 |
| `r³` | quart de tour horaire | 1 |
| `s` | symétrie horizontale | 1 |
| `r²s` | symétrie verticale | 1 |
| `r²` | demi-tour | 2 |
| `rs` | symétrie selon `y = x` | 2 |
| `r³s` | symétrie selon `y = -x` | 2 |

Ainsi, avec les quatre boutons de Pentapol, aucune orientation ne demande plus de deux appuis.

## 7. Composer les transformations

### Deux rotations

On additionne les exposants modulo 4 :

```text
r^a r^b = r^(a+b modulo 4)
```

Exemples :

```text
r r = r²                 deux quarts de tour donnent un demi-tour
r r³ = r⁴ = 1            les rotations opposées s'annulent
r³ r³ = r^6 = r²         deux quarts de tour horaires donnent aussi un demi-tour
```

### Une rotation et une symétrie

La relation fondamentale est :

```text
s r = r^(-1) s = r³s
```

Une symétrie inverse donc le sens d'une rotation. En particulier :

```text
s r s = r^(-1)
```

Visuellement, regarder une rotation dans un miroir échange horaire et antihoraire.

### Deux symétries

Deux symétries d'axes sécants donnent une rotation. Dans Pentapol :

```text
H puis V = (r²s)s = r²
```

La symétrie horizontale suivie de la verticale donne donc une rotation de `π`, et non de `π/2`.

## 8. Exemple avec un point

Prenons le point `A(2, 1)`, donc `z = 2 + i`.

| Transformation | Calcul | Image de A |
|---|---|---|
| `r` | `i(2+i) = -1+2i` | `(-1, 2)` |
| `r²` | `-(2+i)` | `(-2, -1)` |
| `r³` | `-i(2+i) = 1-2i` | `(1, -2)` |
| `s` | `2-i` | `(2, -1)` |
| `rs` | `i(2-i) = 1+2i` | `(1, 2)` |
| `r²s` | `-(2-i) = -2+i` | `(-2, 1)` |
| `r³s` | `-i(2-i) = -1-2i` | `(-1, -2)` |

Pour transformer une pièce entière, on applique exactement le même calcul aux cinq cellules,
toujours par rapport au même centre.

## 9. Pourquoi aucune rotation de π/4 n'apparaît

Une rotation de `π/4` aurait pour multiplicateur :

```text
e^(iπ/4) = (1+i) / √2
```

Ce nombre n'appartient pas au cycle `{1, i, -1, -i}`. En outre, il introduit généralement des
coordonnées divisées par `√2`, qui ne retombent pas sur la grille carrée de Pentapol.

Les compositions des huit transformations restent toujours parmi ces huit transformations : elles
ne peuvent donc jamais créer une rotation de `π/4`.

## 10. Attention aux symétries propres des pièces

Le groupe abstrait possède huit transformations, mais une pièce peut présenter moins de huit
orientations visibles :

- X : 1 orientation ;
- I : 2 orientations ;
- T, U, V, W et Z : 4 orientations ;
- P, F, Y, L et N : 8 orientations.

Par exemple, transformer X ne change jamais son apparence. Pour cette raison, Pentapol calcule la
distance minimale sur la pièce concernée et ne suppose pas que les huit transformations donnent
toujours huit formes différentes.

## 11. Exercices rapides

### Questions

1. Simplifier `r^11`.
2. Quelle rotation représente `e^(i5π/2)` ?
3. Simplifier `r² r³`.
4. Que produit `s s` ?
5. Que produit une symétrie horizontale suivie d'une symétrie verticale ?
6. Donner la formule complexe de la symétrie d'axe `y = x`.
7. Pourquoi `rs` et `sr` ne représentent-ils pas la même diagonale ?
8. Une suite de boutons Pentapol peut-elle produire `e^(iπ/4)` ?

### Corrigé

1. `r^11 = r^3`, car `11 = 2 × 4 + 3`.
2. `e^(i5π/2) = e^(iπ/2) = i` : un quart de tour antihoraire.
3. `r² r³ = r^5 = r`.
4. `s s = s² = 1` : appliquer deux fois la même symétrie ramène au départ.
5. `r²`, donc une rotation de `π`.
6. `z' = i conjugué(z)`, soit `(x, y) → (y, x)`.
7. L'opération de droite est effectuée en premier : l'ordre rotation/symétrie change l'axe obtenu.
8. Non : toutes les compositions restent dans `{r^k, r^k s}`, avec `k` entier modulo 4.

## 12. Formulaire à retenir

```text
Rotation de kπ/2       : r^k(z) = e^(ikπ/2) z = i^k z
Symétrie d'axe φ       : Sφ(z) = e^(2iφ) conjugué(z)
Transformations D4     : r^k ou r^k s, avec k modulo 4
Relations essentielles: r⁴ = 1, s² = 1, srs = r^(-1)
```

Pour le calcul des gestes minimaux réellement utilisé dans Pentapol, voir
[`REFERENCE_ISOMETRIES.md`](REFERENCE_ISOMETRIES.md).
