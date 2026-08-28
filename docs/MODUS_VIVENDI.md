# Modus vivendi — travailler avec Claude Code (CLI) et Claude cowork

> Établi le 2026-08-28 19:33, après une journée de travail à deux agents qui a produit
> six commits corrects et quatre pannes de coordination. Les règles ci-dessous ne sont
> pas théoriques : chacune répond à une panne observée, listée en §7.

---

## 1. Le principe, en une phrase

**Deux agents, un dépôt, aucune mémoire partagée : tout ce qui doit survivre au passage
de l'un à l'autre s'écrit dans un fichier du dépôt.**

---

## 2. Qui fait quoi

| | Claude Code (CLI) | Claude cowork |
|---|---|---|
| Code `lib/` | **oui** | non |
| Compilation, `flutter analyze`, tests | **oui** | non |
| Git — `add`, `commit`, `push` | **oui, exclusivement** | non |
| Analyse, vérification par calcul | secondaire | **oui** |
| Documentation `docs/`, `CLAUDE.md` | non | **oui** |
| Plans et modes opératoires | non | **oui** |
| Recherche web | non | **oui** |

Un seul propriétaire de l'index git : c'est ce qui évite les `.git/index.lock` et les
commits partiels. Cette contrainte n'est pas décorative — cowork a déjà produit deux
commits sans pathspec (`85b8d34`, `bcae01f`) qui n'ont commité que l'index.

---

## 3. Le canal, et ce qui n'en est pas un

Le canal est le **dépôt**. Les deux agents lisent le même arbre de travail : le CLI
nativement, cowork par le pont vers la machine.

**Les mémoires ne sont pas un canal, dans les deux sens :**

| agent | sa mémoire | visible par l'autre |
|---|---|---|
| CLI | `~/.claude/projects/…/memory/` | **non** — locale à ce Mac |
| cowork | mémoire persistante du compte (suit claude.ai et cowork) | **non** |

**Un message de commit n'est pas un canal non plus.** Cowork ne lit pas
`git log` spontanément. Une décision qui n'existe que dans un message de commit est
perdue pour l'autre agent — c'est exactement ce qui est arrivé à `validateSelection`.

**Un copier-coller n'est pas un canal.** Coller une analyse de cowork dans le CLI la
duplique sans l'ancrer : la version collée et celle du dépôt divergent aussitôt. La
bonne formule est toujours « **lis `docs/X`** ».

---

## 4. Les trois gestes de passation

### cowork → CLI

Cowork écrit le plan dans `docs/`, avec son **mode opératoire** : les sites à toucher,
les pièges, les critères de fin vérifiables. Puis tu lances le CLI avec une phrase de la
forme :

> Lis `docs/<PLAN>.md`, section « … ». Applique-la en respectant l'ordre d'exécution.
> Vérifie les critères de fin avant de commiter.

**Aucun commit n'est nécessaire pour cette passation.** Le fichier est visible
immédiatement. `docs/PLAN_SUPPRESSION_DEMO.md` a piloté deux commits alors qu'il n'était
même pas suivi par git.

### CLI → cowork

Le CLI met à jour `docs/JOURNAL.md` : §ÉTAT réécrite, une ligne en §PASSATIONS, et une
ligne en §DÉCISIONS pour **toute décision non prévue au plan**. Puis il commite.

Tu reviens vers cowork en disant simplement ce que tu veux ; cowork lit le journal et
l'état de git.

### Toi, à tout moment

Tu peux basculer sans rien commiter, poser une question au milieu d'un chantier, revenir.
Le protocole ne s'applique qu'aux **fins d'unité de travail**, pas aux allers-retours.

---

## 5. Le commit : qui, quand, et pourquoi pas

**Qui** : le CLI, toujours — y compris pour les `.md` écrits par cowork.

**Quand** :

- un doc qui pilote un travail de code est commité **dans le même commit** que ce code ;
- un doc sans code derrière est commité **seul, en début de session suivante**, avant
  toute modification de `lib/`.

**Pourquoi pas pour transmettre.** Le commit ne sert pas au relais — l'arbre de travail
suffit. Il sert à trois autres choses :

- **durabilité** : un fichier non commité est à un `reset --hard` de disparaître, et il
  n'est pas sur `origin` ;
- **chronologie** : savoir quelle version du plan a produit quel code ;
- **détection de panne** : `git status -s docs/` non vide en fin de session signale que
  quelqu'un a sauté une étape.

La formule à retenir : **on écrit pour transmettre, on commite pour ne pas perdre.**

---

## 6. Vérification, en deux commandes

Après chaque session du CLI :

```bash
git status -s docs/                          # doit être vide
git log --oneline -3 --name-only | grep docs/  # doit trouver quelque chose
```

Si `docs/` est modifié et non commité, le protocole a lâché — c'est le seul contrôle à
faire, il coûte cinq secondes.

Deux autres réflexes, hérités des pannes de la §7 :

```bash
# les headers sont-ils à jour sur ce qui a changé ?
grep -rn "^// Modified: $(date +%Y-%m-%d)" lib/

# du code mort a-t-il été laissé ? flutter analyze ne voit PAS les méthodes
# publiques sans appelant — il faut chercher au grep, par nom.
```

---

## 7. Pourquoi ces règles existent

Quatre pannes observées le 2026-08-28, toutes réelles, toutes évitables :

**Les docs n'entrent jamais dans les commits.** Six commits poussés, **zéro** fichier de
`docs/` dans aucun d'eux, alors que deux plans les ont dictés. Cause : personne n'avait
la charge de les commiter. → règles §2 et §5.

**Une décision de jeu prise sans être annoncée.** Le CLI a introduit
`validateSelection()` (commit `74e56b7`), qui change ce que fait un clic sur une case
vide. Documentée dans le message de commit et l'en-tête du fichier, nulle part ailleurs.
Cowork ne l'a découverte qu'en inspectant `git log`. → §DÉCISIONS du journal.

**Un copier-coller inutile.** Une analyse de cowork a été collée dans le CLI alors
qu'elle était déjà dans `docs/`. → « lis `docs/X` ».

**Des conclusions rangées dans une mémoire privée.** Chaque agent a spontanément écrit
son bilan dans sa propre mémoire, invisible de l'autre. → §3, et l'interdiction de ranger
un fait de projet ailleurs que dans le dépôt.

---

## 8. Ce que ce protocole ne couvre pas

**Il n'est pas contraignant.** `CLAUDE.md` est chargé automatiquement par le CLI, pas
obéi. La mémoire de cowork joue le même rôle de son côté. Au-delà, il n'y a que ta
vigilance et les deux commandes de la §6.

**Il suppose que vous ne travaillez jamais en parallèle.** Deux agents écrivant
`docs/JOURNAL.md` en même temps, c'est le conflit assuré. Un seul actif à la fois.

**Cowork ne sait pas que le CLI a travaillé.** Il n'y a pas de notification : c'est toi
qui fais la bascule. Acceptable tant que la règle du parallélisme est tenue.

**Il ne remplace pas le test.** Six commits ont été poussés — dont un changement de
modèle de données et une suppression de 700 lignes — sans qu'aucun test manuel des trois
modules ait été exécuté. Aucun protocole de communication ne corrige ça.

---

## Voir aussi

- `CLAUDE.md`, §« Protocole entre agents » — la version courte, chargée automatiquement
  par le CLI à chaque session
- `docs/JOURNAL.md` — l'état courant, les décisions, les passations
