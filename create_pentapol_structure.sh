#!/bin/bash

# Script de création de l'arborescence Pentapol
# À exécuter depuis la racine du projet Flutter

echo "🚀 Création de l'arborescence Pentapol..."

# Créer les répertoires
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/providers
mkdir -p lib/screens

echo "📁 Répertoires créés"

# Créer les fichiers models
touch lib/models/point.dart
touch lib/models/plateau.dart
touch lib/models/game_piece.dart
touch lib/models/game.dart
echo "✅ Fichiers models créés"

# Créer le fichier service
touch lib/services/pentomino_solver.dart
echo "✅ Fichier service créé"

# Créer les fichiers providers
touch lib/providers/plateau_editor_state.dart
touch lib/providers/plateau_editor_provider.dart
echo "✅ Fichiers providers créés"

# Créer le fichier screen
touch lib/screens/plateau_editor_screen.dart
echo "✅ Fichier screen créé"

echo ""
echo "🎉 Structure créée avec succès !"
echo ""
echo "📋 Arborescence créée :"
echo "lib/"
echo "├── models/"
echo "│   ├── point.dart"
echo "│   ├── plateau.dart"
echo "│   ├── game_piece.dart"
echo "│   └── game.dart"
echo "├── services/"
echo "│   └── pentomino_solver.dart"
echo "├── providers/"
echo "│   ├── plateau_editor_state.dart"
echo "│   └── plateau_editor_provider.dart"
echo "└── screens/"
echo "    └── plateau_editor_screen.dart"
echo ""
echo "⚠️  N'oubliez pas de :"
echo "1. Déplacer pentominos.dart dans lib/models/"
echo "2. Copier le contenu de chaque fichier"
echo "3. Lancer: flutter pub run build_runner build --delete-conflicting-outputs"