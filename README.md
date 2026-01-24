# PriceMap Tunisia 🗺️💰

> Application mobile collaborative de comparaison de prix géolocalisée pour la Tunisie.

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com)
[![PostGIS](https://img.shields.io/badge/PostGIS-Geospatial-orange.svg)](https://postgis.net)

## 📋 Sommaire

- [À propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Structure du Projet](#-structure-du-projet)
- [Base de Données](#-base-de-données)
- [API & Backend](#-api--backend)
- [Contribution](#-contribution)

## 🎯 À propos

PriceMap Tunisia permet aux utilisateurs de :
- **Trouver** les produits les moins chers autour d'eux (rayon configurable)
- **Contribuer** en signalant les prix qu'ils trouvent
- **Comparer** les prix entre différents commerces
- **Gagner des points** grâce à un système de gamification

L'application utilise le **crowdsourcing** : les prix sont signalés par la communauté et validés par des votes.

## ✨ Fonctionnalités

### 🗺️ Carte Interactive
- Affichage Google Maps centré sur l'utilisateur
- Marqueurs colorés selon le niveau de prix :
  - 🟢 **Vert** : Moins cher (bottom 33%)
  - 🟠 **Orange** : Prix moyen (middle 33%)
  - 🔴 **Rouge** : Plus cher (top 33%)

### 🔍 Recherche Intelligente
- Barre de recherche "Omnibox"
- Full-text search (FR/AR)
- Recherche floue (tolère les fautes)
- Synonymes et dialecte tunisien

### 📍 Filtres de Localisation
- Slider de rayon (500m à 20km)
- Catégories de commerces
- Position en temps réel

### 💰 Système de Prix Collaboratif
- Ajout de prix avec photo optionnelle
- Votes de confirmation (👍/👎)
- Expiration automatique (7 jours sans confirmation)
- Badge "Vérifié" pour les prix officiels

### 🏆 Gamification
| Action | Points |
|--------|--------|
| Signaler un prix | +10 |
| Ajouter une photo | +5 |
| Vote confirmé | +2 |
| Ajouter un commerce | +20 |

### 🏪 Portail Commerçant
- Revendication de lieu
- Mise à jour des prix officiels
- Badge "Vérifié"

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │  Map    │  │ Search  │  │Contribute│  │ Profile │   │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   │
│       └────────────┴────────────┴────────────┘         │
│                         │                               │
│              ┌──────────┴──────────┐                   │
│              │   Riverpod State    │                   │
│              └──────────┬──────────┘                   │
└─────────────────────────┼───────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────┐
│                    Supabase                             │
│  ┌──────────────────────┴───────────────────────────┐  │
│  │              PostgreSQL + PostGIS                 │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐          │  │
│  │  │ Users   │  │ Vendors │  │ Products│          │  │
│  │  └─────────┘  └─────────┘  └─────────┘          │  │
│  │  ┌─────────────────┐  ┌─────────────────┐       │  │
│  │  │  Price Reports  │  │  Price History  │       │  │
│  │  └─────────────────┘  └─────────────────┘       │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Auth + Storage + RLS                 │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Stack Technique

| Composant | Technologie | Justification |
|-----------|-------------|---------------|
| **Frontend** | Flutter (Dart) | Cross-platform, 60fps, UI native |
| **Backend** | Supabase | PostgreSQL, Auth, Realtime, Storage |
| **Database** | PostgreSQL + PostGIS | Requêtes géospatiales performantes |
| **Maps** | Google Maps SDK | Couverture mondiale, qualité |
| **State** | Riverpod | Type-safe, testable, reactive |
| **Navigation** | GoRouter | Declarative, deep linking |

## 📦 Installation

### Prérequis

- Flutter 3.2+
- Dart 3.0+
- Compte Supabase
- Clé API Google Maps

### Configuration

1. **Cloner le repository**
```bash
git clone <repository-url>
cd pricemap_tunisia
```

2. **Installer les dépendances Flutter**
```bash
cd flutter_app
flutter pub get
```

3. **Configurer Supabase**
```bash
# Créer un projet sur supabase.com
# Exécuter les migrations SQL
cd ../supabase/migrations
# Copier-coller 001_initial_schema.sql dans le SQL Editor
# Puis 002_seed_data.sql
```

4. **Configurer les clés API**
```dart
// Modifier lib/core/config/app_config.dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';
```

5. **Configurer Google Maps (Android)**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_KEY"/>
```

6. **Configurer Google Maps (iOS)**
```swift
// ios/Runner/AppDelegate.swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_KEY")
```

7. **Lancer l'application**
```bash
flutter run
```

## 📁 Structure du Projet

```
├── docs/
│   ├── DATABASE_SCHEMA.md      # Documentation du schéma DB
│   └── PRICE_COMPARISON_LOGIC.md # Logique de comparaison
│
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql  # Création des tables
│       └── 002_seed_data.sql       # Données initiales
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart               # Point d'entrée
    │   │
    │   ├── core/
    │   │   ├── config/
    │   │   │   ├── app_config.dart    # Configuration générale
    │   │   │   └── theme_config.dart  # Thème visuel
    │   │   ├── models/
    │   │   │   ├── vendor.dart        # Modèle Commerce
    │   │   │   ├── product.dart       # Modèle Produit
    │   │   │   └── price_report.dart  # Modèle Prix
    │   │   ├── router/
    │   │   │   └── app_router.dart    # Navigation GoRouter
    │   │   ├── services/
    │   │   │   └── location_service.dart # Géolocalisation
    │   │   └── widgets/
    │   │       └── main_scaffold.dart  # Shell avec Bottom Nav
    │   │
    │   └── features/
    │       ├── auth/                  # Authentification
    │       ├── map/                   # Carte interactive
    │       │   ├── data/
    │       │   │   └── repositories/  # Accès Supabase
    │       │   └── presentation/
    │       │       ├── pages/         # MapPage
    │       │       ├── providers/     # State management
    │       │       └── widgets/       # SearchBar, Cards...
    │       ├── search/                # Recherche avancée
    │       ├── contribute/            # Ajout de prix
    │       ├── profile/               # Profil utilisateur
    │       └── vendor/                # Détail commerce
    │
    └── pubspec.yaml                   # Dépendances
```

## 🗄️ Base de Données

### Schéma Principal

```
users ──┬── price_reports ──┬── products
        │         │         │
        │         │         └── categories (product)
        │         │
        └── vendors ─────────── categories (vendor)
                  │
                  └── [PostGIS: location GEOGRAPHY]
```

### Tables Clés

| Table | Description |
|-------|-------------|
| `users` | Utilisateurs avec points/niveau |
| `vendors` | Commerces géolocalisés (PostGIS) |
| `products` | Produits/services hiérarchiques |
| `price_reports` | Prix signalés par les utilisateurs |
| `price_votes` | Votes de confirmation |
| `price_history` | Historique pour analytics |

### Fonctions PostGIS

```sql
-- Trouver les commerces dans un rayon
SELECT * FROM find_vendors_in_radius(36.8065, 10.1815, 5000);

-- Rechercher des produits avec prix locaux
SELECT * FROM search_products_with_local_prices('viande', 36.8065, 10.1815, 5000);
```

Voir [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) pour la documentation complète.

## 🔐 Sécurité

### Row Level Security (RLS)

Toutes les tables utilisent RLS pour contrôler l'accès :

```sql
-- Les utilisateurs peuvent voir tous les prix actifs
CREATE POLICY "Public read prices" ON price_reports
    FOR SELECT USING (is_active = true);

-- Seul l'auteur peut modifier son signalement
CREATE POLICY "Owner can update" ON price_reports
    FOR UPDATE USING (auth.uid() = user_id);
```

## 🎨 Design

### Thème Visuel

- **Style** : Moderne, Minimaliste (inspiration Airbnb/Uber)
- **Couleurs** :
  - Primary : Rouge tunisien `#E63946`
  - Secondary : Bleu méditerranéen `#457B9D`
  - Prix : Vert/Orange/Rouge

### Composants UI

- Cards arrondies avec ombres douces
- Bottom Navigation Bar
- Modal Bottom Sheets pour les formulaires
- Animations fluides (Flutter Animate)

## 📊 Logique de Comparaison

La comparaison des prix utilise :

1. **Taxonomie hiérarchique** des produits
2. **Percentiles locaux** (33%/66% pour les couleurs)
3. **Groupement par unité** (kg vs pièce)
4. **Score de confiance** basé sur votes + fraîcheur

Voir [PRICE_COMPARISON_LOGIC.md](docs/PRICE_COMPARISON_LOGIC.md) pour les détails.

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 🚀 Déploiement

### Android

```bash
flutter build apk --release
# ou pour le Play Store
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 📝 Licence

Ce projet est sous licence MIT.

## 🤝 Contribution

Les contributions sont les bienvenues ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---

**Développé avec ❤️ pour la Tunisie 🇹🇳**
