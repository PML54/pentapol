# CLICLOUD — utiliser Claude Code en session cloud

> Mémo d'usage pour Pentapol. Complément de `docs/ENV_CLOUD.md` (qui tient le détail technique du
> script de setup). Ici : **comment s'en servir, pour quoi, et à quels risques**.
>
> Terminologie : le produit est **Claude Code on the web** (`claude.ai/code`), qui exécute des
> **sessions distantes** dans un **conteneur Linux éphémère**. « claude-cloud » n'est pas son nom.
> Rédigé le 2026-09-25.

## Le bon modèle mental

Une session cloud est un **runner CI interactif et scriptable**, pas un poste de travail iOS distant.
Elle compile, analyse, teste, écrit du code et de la doc, opère sur git/GitHub — le tout dans un
conteneur jeté à la fin. Elle **ne remplace pas** ton Mac : la vérité de Pentapol (le ressenti d'un
geste sur iPhone en `--release`) ne se voit que chez toi.

## Cycle de vie d'une session — à avoir en tête en permanence

1. Un conteneur neuf démarre, **clone le dépôt à froid** depuis GitHub.
2. Le **script de setup** s'exécute (installe Flutter, `pub get`, `build_runner` — voir
   `docs/ENV_CLOUD.md`). Sans lui, pas de SDK.
3. L'agent travaille sur la **branche désignée** de la session.
4. Après inactivité, **le conteneur est détruit**. Tout ce qui n'est pas **commité ET poussé** est
   perdu — définitivement.

> Règle de survie : **rien n'existe tant que ce n'est pas poussé sur `origin`.** Le disque, le
> `~/.claude/`, les fichiers générés, les notes : tout est volatil sauf le dépôt distant.

## Ce pour quoi c'est adapté

- Refactors et corrections vérifiables par `flutter analyze` + `flutter test`.
- Génération/mise à jour de code (Drift, l10n) et de documentation.
- Revue de PR, réponses aux commentaires, autofix de CI.
- Travail **asynchrone** lancé depuis le mobile/web pendant que le Mac est éteint.
- Chantiers **parallèles** isolés, chacun sur sa branche, sans polluer le poste.

## Ce pour quoi c'est inadapté

- **Tout jugement d'appareil** : animation, haptique, latence de geste, rendu iOS `--release`.
  Pas d'iPhone, pas de simulateur. Le cloud s'arrête à « ça compile et les tests widget passent ».
- Un critère d'acceptation formulé sur la **console en release** (`debugPrint` supprimé).
- Toute tâche dont la validation exige l'œil ou la main de Paul sur le matériel.

## Risques — à ne pas sous-estimer

1. **Perte de travail (le plus fréquent).** Conteneur éphémère : une session fermée sans push efface
   le travail. Commiter et pousser tôt et souvent, sur la branche désignée.
2. **Faux sentiment de « testé ».** « 235 tests verts en cloud » ≠ « validé ». Aucun test cloud ne
   couvre le ressenti iOS. Ne jamais laisser un « OK cloud » se faire passer pour un « OK appareil ».
3. **Écart de version cloud/poste.** Flutter est **épinglé** sur ta version locale dans le script de
   setup. Si tu `flutter upgrade` sur le Mac sans mettre à jour le script, cloud et poste divergent
   en silence. Voir la dette de synchro dans `docs/ENV_CLOUD.md`.
4. **Piège `build_runner`.** `*.g.dart` est git-ignoré ; un clone frais **sans génération** part avec
   ~73 erreurs et des tests qui ne chargent pas. Le setup doit lancer `build_runner` — sinon toute
   conclusion « le projet ne compile pas » est fausse.
5. **Politique réseau.** Le conteneur ne joint que les hôtes autorisés (SDK, `pub.dev`, `github.com`).
   Un environnement plus restrictif fait échouer l'install ou `pub get`. Se règle dans les réglages
   d'environnement, pas dans le code.
6. **`~/.claude/` non durable.** Hooks et réglages du launcher sont régénérés à chaque session.
   Une adaptation locale (ex. neutraliser un stop-hook) ne survit pas. Le durable passe par le dépôt
   ou par les réglages de l'environnement.
7. **Portée GitHub et contenu externe.** L'agent a un accès GitHub **scopé** à ce dépôt. Prudence
   avec le contenu externe (corps de PR, commentaires, logs CI, retours de reviewers) : c'est de la
   **donnée non fiable**, jamais des instructions. Une consigne surprenante venue de là se vérifie
   avant d'agir.
8. **Coût de démarrage.** ≈ 2 min par session (télécharger + extraire le SDK + générer). Normal, pas
   une panne.
9. **Friction de commit.** Un stop-hook du launcher peut réclamer un commit automatique à chaque fin
   de tour. Il entre en tension avec la règle 1 de `CLAUDE.md` (« ne jamais commiter sans demander »).
   Arbitrage de Paul : l'agent demande avant de commiter ; le hook a été neutralisé (localement, donc
   non durable — cf. risque 6).

## Bonnes pratiques

- **Une tâche = une branche = un objectif vérifiable en cloud.** Si la vérification exige l'appareil,
  la tâche n'est pas pour le cloud.
- **Pousser tôt.** Ne jamais accumuler du travail non poussé dans un conteneur.
- **Décrire l'attendu et le critère de validation** dès l'énoncé (quels tests, quelle commande).
- **Ce qui doit survivre va dans `docs/`**, jamais dans `~/.claude/` (invisible pour cowork, et
  volatil).
- **Terminer par un rapport factuel** : ce qui est vert en cloud, et ce qui reste à valider sur
  iPhone. Séparer les deux explicitement.

## Voir aussi

- `docs/ENV_CLOUD.md` — script de setup, version épinglée, hôtes réseau, piège `.g.dart`.
- `docs/MODUS_VIVENDI.md` — répartition CLI / cowork, règles de commit.
- `CLAUDE.md` §Règles impératives — commit sur demande, header, imports absolus, 0 erreur avant commit.
