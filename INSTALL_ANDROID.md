# Installation sur Android - PriceMap Tunisia

## Prérequis sur ton ordinateur

1. **Flutter SDK** (version 3.2+)
   - Télécharge depuis : https://flutter.dev/docs/get-started/install
   - Ajoute Flutter au PATH

2. **Android Studio** ou **Android SDK**
   - Télécharge depuis : https://developer.android.com/studio
   - Installe les SDK Tools

3. **Git**
   - Pour cloner le projet

---

## Étape 1 : Cloner le projet

```bash
git clone https://github.com/kbilel/ra5ousi.git
cd ra5ousi
git checkout cursor/sch-ma-et-interface-carte-bbc3
```

---

## Étape 2 : Configurer les clés API

### 2.1 Clé Supabase

1. Va sur https://supabase.com/dashboard/project/jygnfrvfrbkdvvgeykii
2. **Settings** > **API**
3. Copie la clé **anon public**
4. Ouvre `flutter_app/lib/core/config/app_config.dart`
5. Remplace :
```dart
static const String supabaseAnonKey = 'TA_CLE_ANON_ICI';
```

### 2.2 Clé Google Maps

1. Va sur https://console.cloud.google.com
2. Crée un projet ou utilise un existant
3. Active ces APIs :
   - Maps SDK for Android
   - Places API
   - Geocoding API
4. **Identifiants** > **Créer des identifiants** > **Clé API**
5. Ouvre `flutter_app/android/app/src/main/AndroidManifest.xml`
6. Remplace :
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY"
```
par ta clé.

7. Mets aussi à jour `flutter_app/lib/core/config/app_config.dart` :
```dart
static const String googleMapsApiKey = 'TA_CLE_GOOGLE_MAPS';
```

---

## Étape 3 : Exécuter les migrations SQL

1. Va sur https://supabase.com/dashboard/project/jygnfrvfrbkdvvgeykii
2. **SQL Editor** > **+ New query**
3. Copie-colle le contenu de `supabase/migrations/001_initial_schema.sql`
4. Clique **Run**
5. Crée une nouvelle query
6. Copie-colle `supabase/migrations/002_seed_data.sql`
7. Clique **Run**

---

## Étape 4 : Construire l'APK

### Option A : Mode Debug (rapide, pour tester)

```bash
cd flutter_app

# Installer les dépendances
flutter pub get

# Construire l'APK debug
flutter build apk --debug
```

L'APK sera dans : `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`

### Option B : Mode Release (optimisé, pour distribution)

```bash
cd flutter_app

# Installer les dépendances
flutter pub get

# Construire l'APK release
flutter build apk --release
```

L'APK sera dans : `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

---

## Étape 5 : Installer sur ton téléphone

### Méthode 1 : Via USB (recommandée)

1. Active le **Mode développeur** sur ton téléphone :
   - **Paramètres** > **À propos** > Tape 7 fois sur **Numéro de build**
   
2. Active le **Débogage USB** :
   - **Paramètres** > **Options développeur** > **Débogage USB** : ON
   
3. Connecte ton téléphone en USB

4. Exécute :
```bash
cd flutter_app
flutter install
```

### Méthode 2 : Transfert manuel de l'APK

1. Copie l'APK (`app-debug.apk` ou `app-release.apk`) vers ton téléphone
   - Par USB
   - Par Google Drive
   - Par email

2. Sur ton téléphone :
   - **Paramètres** > **Sécurité** > Active **Sources inconnues** (ou **Installer des apps inconnues**)
   
3. Ouvre le fichier APK et installe

### Méthode 3 : Lancer directement (développement)

Avec le téléphone connecté en USB :

```bash
cd flutter_app
flutter run
```

L'app se lancera directement sur ton téléphone.

---

## Commandes utiles

```bash
# Vérifier que Flutter est bien configuré
flutter doctor

# Voir les appareils connectés
flutter devices

# Nettoyer le projet (si problèmes de build)
flutter clean
flutter pub get

# Lancer en mode debug avec logs
flutter run --verbose
```

---

## Résolution des problèmes

### "No connected devices"
- Vérifie que le débogage USB est activé
- Accepte la popup "Autoriser le débogage USB" sur ton téléphone
- Essaie un autre câble USB

### "Gradle build failed"
```bash
cd flutter_app/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### "Google Maps ne s'affiche pas"
- Vérifie que ta clé API est correcte
- Vérifie que les APIs sont activées dans Google Cloud Console
- Vérifie les restrictions de ta clé (package name: `com.pricemap.tunisia`)

### "Erreur Supabase"
- Vérifie que l'URL est correcte : `https://jygnfrvfrbkdvvgeykii.supabase.co`
- Vérifie que tu utilises la clé **anon** (pas service_role)
- Vérifie que les migrations SQL ont été exécutées

---

## Structure des fichiers générés

```
flutter_app/
├── build/
│   └── app/
│       └── outputs/
│           └── flutter-apk/
│               ├── app-debug.apk      ← APK debug
│               └── app-release.apk    ← APK release
```

---

## Besoin d'aide ?

1. Exécute `flutter doctor -v` et partage le résultat
2. Partage les logs d'erreur complets
