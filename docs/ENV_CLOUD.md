# Environnement cloud — Claude Code on the web

> Ce document décrit l'exécution de Pentapol dans une **session distante** de Claude Code
> (`claude.ai/code`), c'est-à-dire un **conteneur Linux éphémère** cloné à froid depuis GitHub
> au démarrage et détruit après inactivité. Il ne concerne **pas** le poste de développement de
> Paul (macOS), qui reste la référence pour tout test sur appareil.
>
> Rédigé le 2026-09-25 après première mise en service de Flutter en cloud.

## Ce que le cloud peut et ne peut pas faire

- **Peut** : `flutter analyze`, `flutter test`, génération de code, refactors, docs, revue/réponses
  de PR, autofix CI — tout ce qui se valide par compilation et tests widget.
- **Ne peut pas** : tester le **ressenti sur iPhone en `--release`**. Pas d'appareil, pas de
  simulateur iOS. La boucle de validation finale reste sur le poste de Paul
  (`flutter run --release -d 00008150-000165D4027B401C`). Le cloud est un **runner CI interactif**,
  pas un poste de travail iOS.

## Le SDK Flutter n'est PAS préinstallé

Le conteneur cloud ne contient **ni `flutter` ni `dart`** par défaut. Il faut les installer via le
**script de setup de l'environnement** (réglages de l'environnement cloud → Edit → Setup script).
Ce script s'exécute au démarrage de chaque nouvelle session ; il **ne vit pas dans le dépôt** et ne
peut donc pas être committé ici.

### Version épinglée — couplée au poste de Paul

`FLUTTER_VERSION` est **volontairement figé sur la version macOS locale de Paul** (au 2026-09-25 :
**3.47.2 stable**, Dart 3.13.2), pour que cloud et poste partagent exactement la même chaîne
d'outils. C'est le prix de la reproductibilité pour un projet qui vise l'App Store.

> ⚠️ **Dette de synchronisation manuelle.** Le jour où Paul fait `flutter upgrade` sur son Mac,
> ce script continuera d'installer l'ancienne version en cloud → écart silencieux. **Mettre à jour
> `FLUTTER_VERSION` dans le script de setup en même temps que le poste**, ou basculer sur un
> résolveur « dernière stable » (plus simple, mais on perd la garantie cloud = poste).

### Script de setup (testé de bout en bout le 2026-09-25)

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Flutter : épinglé sur la version macOS locale de Paul ---
FLUTTER_VERSION="3.47.2"
FLUTTER_DIR="/opt/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  curl -fSL "$url" -o /tmp/flutter.tar.xz
  rm -rf "$FLUTTER_DIR"
  tar -xf /tmp/flutter.tar.xz -C /opt
  rm -f /tmp/flutter.tar.xz
fi

# flutter/dart visibles dans TOUTES les commandes (le shell des tool calls n'est
# ni login ni interactif : /etc/profile.d ne suffit pas, d'où les symlinks).
ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
ln -sf "$FLUTTER_DIR/bin/dart"    /usr/local/bin/dart
git config --global --add safe.directory "$FLUTTER_DIR"
flutter --disable-analytics >/dev/null 2>&1 || true

# --- Projet : dépendances + génération Drift (le .g.dart est git-ignoré) ---
repo="$(git rev-parse --show-toplevel 2>/dev/null || echo /home/user/pentapol)"
cd "$repo"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Piège majeur — la génération de code Drift est obligatoire

`*.g.dart` est **git-ignoré** (`.gitignore`, `*.g.dart`). Le fichier généré par Drift
`lib/database/settings_database.g.dart` n'est donc **jamais présent dans un clone frais**. Sans lui,
`flutter analyze` reporte **~73 erreurs en cascade** (`SettingsCompanion` indéfini, `.select` absent,
`CurrentGameData` non typé, etc.) et **~15 fichiers de test ne chargent pas**. Ce ne sont **pas** des
erreurs de version Flutter : c'est l'étape `build_runner` manquante.

**Après `dart run build_runner build --delete-conflicting-outputs`** : état sain confirmé sur 3.47.2
le 2026-09-25 → **0 erreur / 0 avertissement / 113 infos**, **235/235 tests au vert**.

## Réseau

La politique réseau de l'environnement doit autoriser :
- `storage.googleapis.com` — SDK Flutter et artefacts moteur ;
- `pub.dev` — packages Dart/Flutter ;
- `github.com` — clone du dépôt (déjà autorisé par défaut).

Au 2026-09-25, la politique en place les autorise. Un environnement plus restrictif exigerait de les
ajouter aux domaines permis (réglages de l'environnement → Edit → Network access).

## Coût de démarrage

≈ 2 min par nouvelle session : ~13 s de téléchargement + ~60 s d'extraction + ~30 s de génération.
Le SDK n'est pas re-téléchargé si `/opt/flutter` existe, mais un conteneur neuf repart de zéro.

## Rappel — rien de `~/.claude/` n'est durable

Le dossier `~/.claude/` du conteneur (hooks, réglages du launcher) est **local et régénéré** à chaque
session. Toute modification qu'on y fait (ex. neutraliser le stop-hook qui réclame un commit) ne vaut
que pour le conteneur courant et ne survit pas. Le seul canal durable reste le dépôt (`docs/`).
