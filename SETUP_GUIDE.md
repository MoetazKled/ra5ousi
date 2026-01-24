# Guide de Configuration - PriceMap Tunisia

## 1. Configuration de la Base de Données Supabase

### Étape 1 : Accéder au SQL Editor

1. Connectez-vous à [Supabase Dashboard](https://supabase.com/dashboard)
2. Sélectionnez votre projet : `jygnfrvfrbkdvvgeykii`
3. Dans le menu de gauche, cliquez sur **SQL Editor**

### Étape 2 : Exécuter les Migrations

**Migration 1 - Schéma Initial :**

1. Cliquez sur **+ New query**
2. Copiez-collez le contenu de `supabase/migrations/001_initial_schema.sql`
3. Cliquez sur **Run** (ou Ctrl+Enter)
4. Attendez le message "Success"

**Migration 2 - Données Initiales :**

1. Créez une nouvelle query
2. Copiez-collez le contenu de `supabase/migrations/002_seed_data.sql`
3. Exécutez

### Étape 3 : Vérifier les Tables

Allez dans **Table Editor** et vérifiez que ces tables existent :
- ✅ users
- ✅ categories
- ✅ units
- ✅ vendors
- ✅ products
- ✅ price_reports
- ✅ price_votes
- ✅ price_history
- ✅ user_contributions
- ✅ favorites
- ✅ search_history

## 2. Récupérer la Clé API Anonyme

1. Dans le dashboard Supabase, allez dans **Settings** > **API**
2. Copiez la clé **anon public** (pas la service_role!)
3. Mettez à jour le fichier `flutter_app/lib/core/config/app_config.dart` :

```dart
static const String supabaseAnonKey = 'VOTRE_CLE_ANON_ICI';
```

## 3. Configurer le Storage (Photos)

### Créer les Buckets

1. Allez dans **Storage**
2. Créez deux buckets :
   - `price-photos` (Public)
   - `avatars` (Public)

### Politiques de Sécurité

Pour chaque bucket, ajoutez ces policies :

**price-photos :**
```sql
-- Lecture publique
CREATE POLICY "Public read" ON storage.objects
FOR SELECT USING (bucket_id = 'price-photos');

-- Upload pour utilisateurs authentifiés
CREATE POLICY "Authenticated upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'price-photos' 
  AND auth.role() = 'authenticated'
);
```

**avatars :**
```sql
-- Lecture publique
CREATE POLICY "Public read avatars" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

-- Upload/Update pour son propre avatar
CREATE POLICY "User can manage own avatar" ON storage.objects
FOR ALL USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## 4. Configurer l'Authentification

### Activer les Providers

1. Allez dans **Authentication** > **Providers**
2. Activez :
   - ✅ Email (activé par défaut)
   - ✅ Google (optionnel)

### Configurer Google OAuth (Optionnel)

1. Créez un projet sur [Google Cloud Console](https://console.cloud.google.com)
2. Activez l'API Google+ et OAuth
3. Créez des identifiants OAuth 2.0
4. Configurez les URLs de redirection :
   - `https://jygnfrvfrbkdvvgeykii.supabase.co/auth/v1/callback`
5. Copiez le Client ID et Secret dans Supabase > Auth > Google

## 5. Configurer Google Maps

### Obtenir une Clé API

1. Allez sur [Google Cloud Console](https://console.cloud.google.com)
2. Créez un projet ou sélectionnez-en un
3. Activez ces APIs :
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Créez une clé API dans **Identifiants**

### Configurer Android

Modifiez `flutter_app/android/app/src/main/AndroidManifest.xml` :

```xml
<manifest ...>
    <application ...>
        <!-- Ajoutez cette ligne -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="VOTRE_CLE_GOOGLE_MAPS"/>
        ...
    </application>
</manifest>
```

### Configurer iOS

Modifiez `flutter_app/ios/Runner/AppDelegate.swift` :

```swift
import UIKit
import Flutter
import GoogleMaps  // Ajoutez cette ligne

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("VOTRE_CLE_GOOGLE_MAPS")  // Ajoutez cette ligne
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Mettez aussi à jour `flutter_app/lib/core/config/app_config.dart` :

```dart
static const String googleMapsApiKey = 'VOTRE_CLE_GOOGLE_MAPS';
```

## 6. Lancer l'Application

```bash
cd flutter_app

# Installer les dépendances
flutter pub get

# Lancer sur un émulateur/appareil
flutter run
```

## 7. Tester les Fonctionnalités

### Test de Base

1. **Carte** : Vérifiez que la carte s'affiche et demande la localisation
2. **Catégories** : Les chips de catégories doivent apparaître
3. **Recherche** : Tapez "viande" et vérifiez les résultats

### Test Complet (après inscription)

1. Créez un compte via l'app
2. Ajoutez un commerce test
3. Signalez un prix
4. Vérifiez les points gagnés

## Résolution des Problèmes

### "Extension PostGIS non trouvée"

Exécutez dans SQL Editor :
```sql
CREATE EXTENSION IF NOT EXISTS "postgis";
```

### "Permission denied sur les tables"

Les policies RLS sont peut-être mal configurées. Vérifiez dans **Authentication** > **Policies**.

### "Google Maps ne s'affiche pas"

1. Vérifiez que la clé API est correcte
2. Vérifiez que les APIs sont activées dans Google Cloud
3. Sur Android, vérifiez le SHA-1 de votre app

### "Erreur de connexion Supabase"

1. Vérifiez l'URL Supabase (`https://jygnfrvfrbkdvvgeykii.supabase.co`)
2. Vérifiez la clé anon (pas service_role!)
3. Vérifiez votre connexion internet

## Support

Pour toute question, consultez :
- [Documentation Supabase](https://supabase.com/docs)
- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
