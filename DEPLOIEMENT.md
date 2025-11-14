# 🚀 Guide de Déploiement Pentapol

## 📱 Problèmes iOS et Solutions

### ⚠️ Problème : Xcode 26.1 beta + iPhone physique iOS 18.6.2

**Erreur** :
```
iOS 26.1 is not installed. Please download and install the platform from Xcode > Settings > Components.
```

**Cause** : Incompatibilité entre Xcode 26.1 beta et les appareils physiques iOS 18.x

### ✅ Solutions

#### **Solution 1 : Utiliser un simulateur iOS** (Rapide)

```bash
# Créer un simulateur iPhone 13 avec iOS 18.5
xcrun simctl create "iPhone 13 Dev" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-13 \
  com.apple.CoreSimulator.SimRuntime.iOS-18-5

# Lancer l'app sur ce simulateur
flutter run -d "iPhone 13 Dev"
```

#### **Solution 2 : Downgrader vers Xcode stable** (Recommandé pour production)

1. Télécharger **Xcode 16.x stable** depuis https://developer.apple.com/download/
2. Installer à côté de Xcode 26.1 beta (renommer en `Xcode-16.app`)
3. Changer la version active :
```bash
sudo xcode-select -s /Applications/Xcode-16.app/Contents/Developer
```
4. Vérifier :
```bash
xcodebuild -version
# Devrait afficher : Xcode 16.x
```

#### **Solution 3 : Mettre à jour iPhone vers iOS 26 beta**

⚠️ **Attention** : iOS 26 est en beta, peut être instable.

1. S'inscrire au programme beta Apple Developer
2. Installer le profil beta sur l'iPhone
3. Mettre à jour vers iOS 26.x

---

## 🌐 Problème Web : Écran blanc

### **Cause** : Supabase peut échouer sur le web

### ✅ Solution : Mode Debug Éditeur

Dans `lib/main.dart`, nous avons ajouté un flag de debug :

```dart
// MODE DEBUG : Lancer directement l'éditeur
const bool debugEditorMode = true;  // ← Mettre à true pour tester
```

**Pour tester sur le web** :
```bash
flutter run -d chrome
```

**Pour désactiver le mode debug** (production) :
```dart
const bool debugEditorMode = false;
```

---

## 🎯 Commandes de lancement

### **Simulateur iPhone 13** (créé)
```bash
flutter run -d "iPhone 13 Dev"
```

### **Simulateur iPhone 15 Pro Max** (existant)
```bash
flutter run -d "iPhone 15 Pro Max"
```

### **Web (Chrome)**
```bash
flutter run -d chrome
```

### **macOS Desktop**
```bash
flutter run -d macos
```

### **Liste tous les appareils**
```bash
flutter devices
```

---

## 📊 Status des Plateformes

| Plateforme | Status | Notes |
|------------|--------|-------|
| ✅ iOS Simulateur | Fonctionne | iPhone 13 Dev créé |
| ❌ iOS Physique | Bloqué | Xcode 26.1 beta incompatible |
| ✅ Web (Chrome) | Fonctionne | Mode debug actif |
| ✅ macOS | Fonctionne | Natif |
| ❓ Android | Non testé | À tester |

---

## 🔧 Dépannage

### **Nettoyer le build**
```bash
flutter clean
flutter pub get
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### **Vérifier les appareils disponibles**
```bash
flutter devices
xcrun simctl list devices available
```

### **Créer un nouveau simulateur**
```bash
# Lister les types d'appareils
xcrun simctl list devicetypes | grep iPhone

# Lister les runtimes iOS
xcrun simctl list runtimes | grep iOS

# Créer un simulateur
xcrun simctl create "Mon iPhone" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-15 \
  com.apple.CoreSimulator.SimRuntime.iOS-18-5
```

### **Redémarrer un simulateur**
```bash
# Arrêter tous les simulateurs
xcrun simctl shutdown all

# Lancer un simulateur spécifique
open -a Simulator --args -CurrentDeviceUDID <UDID>
```

---

## 📅 Dernière mise à jour : 10 novembre 2024

**Version Xcode** : 26.1 (17B55)
**Version Flutter** : (voir `flutter --version`)
**Simulateurs créés** :
- iPhone 13 Dev (iOS 18.5)
- iPhone 15 Pro Max (iOS 17.5)


