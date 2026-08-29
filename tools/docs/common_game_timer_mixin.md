# common/game_timer_mixin.dart

**Module:** common

## Fonctions

### stateWithElapsedSeconds

Chronomètre de partie, partagé par tous les modules de jeu.

Le module fournit uniquement [stateWithElapsedSeconds] : le mixin ne connaît pas
la forme de l'état, seulement le moyen d'y écrire le temps écoulé.

## Trois intentions distinctes, trois méthodes

Avant l'unification, les deux providers avaient chacun leur `startTimer` avec une
**garde différente**, ce qui leur donnait des comportements incompatibles :

- le mode classique gardait sur `_startTime != null` : après un `stopTimer`, le
chrono ne repartait jamais, l'origine était préservée ;
- Pentoscope gardait sur `_gameTimer != null` : après un `stopTimer`, le chrono
repartait **en réinitialisant l'origine**, perdant le temps déjà écoulé.

Aucune des deux gardes ne convenait aux deux modules. La divergence venait de ce
que « mettre en pause » et « remettre à zéro » passaient par le même appel. Les
séparer supprime le conflit :

| Méthode | Effet | Reprise après |
|---|---|---|
| [stopTimer] | arrête le tic, **conserve** l'origine | reprend là où on s'était arrêté |
| [resetTimer] | arrête le tic et **efface** l'origine | repart de zéro |

[startTimer] est idempotent : appelé alors que le chrono tourne déjà, il ne fait
rien ; appelé après un [stopTimer], il reprend sans perdre le temps accumulé.
Retourne l'état courant avec [elapsedSeconds] mis à jour.

Implémentation typique : `state.copyWith(elapsedSeconds: elapsedSeconds)`.


```dart
S stateWithElapsedSeconds(int elapsedSeconds);
```

### startTimer

Le chronomètre tourne-t-il.
Démarre le chronomètre, ou le reprend s'il avait été arrêté par [stopTimer].

Sans effet s'il tourne déjà. L'origine n'est posée qu'une fois : après un
[stopTimer], le temps déjà écoulé est conservé. Pour repartir de zéro,
appeler [resetTimer] au préalable.


```dart
void startTimer() {
```

### stopTimer

Arrête le tic en conservant l'origine — une pause, ou une fin de partie.


```dart
void stopTimer() {
```

### resetTimer

Arrête le tic **et** efface l'origine — une nouvelle partie.

Le prochain [startTimer] repartira de zéro.


```dart
void resetTimer() {
```

### getElapsedSeconds

Temps écoulé depuis l'origine, en secondes. 0 si le chrono n'a jamais démarré.


```dart
int getElapsedSeconds() {
```

