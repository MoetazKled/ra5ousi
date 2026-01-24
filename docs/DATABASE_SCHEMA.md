# PriceMap Tunisia - Schéma de Base de Données

## Vue d'ensemble de l'Architecture

Cette base de données est conçue pour Supabase (PostgreSQL + PostGIS) et supporte :
- **Géolocalisation performante** via PostGIS pour les requêtes spatiales
- **Flexibilité produit/service** : un modèle générique qui s'adapte aux boucheries, coiffeurs, quincailleries, etc.
- **Crowdsourcing** : système de votes, historique des prix, gamification
- **Multi-devises** : préparé pour TND avec support futur d'autres devises
- **Multilingue** : support FR/AR via champs JSON

---

## Diagramme Entité-Relation (Simplifié)

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   users     │       │   vendors    │       │  categories │
│─────────────│       │──────────────│       │─────────────│
│ id (PK)     │       │ id (PK)      │       │ id (PK)     │
│ email       │       │ google_place │       │ name_fr     │
│ points      │       │ location     │◄──────│ name_ar     │
│ role        │       │ category_id  │       │ icon        │
└─────────────┘       └──────────────┘       └─────────────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│price_reports│       │   products   │       │    units    │
│─────────────│       │──────────────│       │─────────────│
│ id (PK)     │──────►│ id (PK)      │       │ id (PK)     │
│ product_id  │       │ name_fr/ar   │◄──────│ name (kg,L) │
│ vendor_id   │       │ category_id  │       │ type        │
│ price       │       │ unit_id      │       └─────────────┘
│ user_id     │       │ parent_id    │
└─────────────┘       └──────────────┘
       │                     │
       ▼                     │
┌─────────────┐              │ (Hiérarchie)
│ price_votes │              ▼
│─────────────│       ┌──────────────┐
│ id (PK)     │       │  (self-ref)  │
│ report_id   │       │ Viande       │
│ user_id     │       │  └─ Bœuf     │
│ is_valid    │       │  └─ Agneau   │
└─────────────┘       └──────────────┘
```

---

## Tables Principales

### 1. `users` - Utilisateurs

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique (Auth Supabase) |
| `email` | VARCHAR(255) | Email de l'utilisateur |
| `display_name` | VARCHAR(100) | Nom affiché |
| `avatar_url` | TEXT | URL de l'avatar |
| `phone` | VARCHAR(20) | Numéro de téléphone (optionnel) |
| `role` | ENUM | 'user', 'merchant', 'admin' |
| `points` | INTEGER | Points de gamification |
| `level` | INTEGER | Niveau basé sur les points |
| `preferred_language` | VARCHAR(2) | 'fr' ou 'ar' |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Dernière mise à jour |

**Pourquoi ?** Le système de points encourage la contribution. Les rôles permettent de distinguer utilisateurs normaux, commerçants et admins.

---

### 2. `categories` - Catégories de commerces/produits

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `parent_id` | UUID (FK) | Auto-référence pour hiérarchie |
| `name_fr` | VARCHAR(100) | Nom en français |
| `name_ar` | VARCHAR(100) | Nom en arabe |
| `slug` | VARCHAR(100) | URL-friendly (ex: "boucherie") |
| `icon` | VARCHAR(50) | Nom de l'icône Material/FontAwesome |
| `color` | VARCHAR(7) | Code couleur HEX |
| `type` | ENUM | 'vendor' (commerce) ou 'product' |
| `is_active` | BOOLEAN | Catégorie active ou non |
| `sort_order` | INTEGER | Ordre d'affichage |

**Exemple de hiérarchie :**
```
Alimentation (type: vendor)
├── Boucherie
├── Poissonnerie
└── Épicerie

Services (type: vendor)
├── Coiffure
└── Pressing
```

---

### 3. `vendors` - Commerces / Points de vente

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `google_place_id` | VARCHAR(255) | ID Google Places (pour sync) |
| `name` | VARCHAR(200) | Nom du commerce |
| `description` | TEXT | Description optionnelle |
| `category_id` | UUID (FK) | Catégorie du commerce |
| `location` | GEOGRAPHY(Point, 4326) | **Point PostGIS** (lat/lng) |
| `address` | TEXT | Adresse complète |
| `city` | VARCHAR(100) | Ville |
| `governorate` | VARCHAR(100) | Gouvernorat (Tunisie) |
| `phone` | VARCHAR(20) | Téléphone |
| `website` | VARCHAR(255) | Site web |
| `photo_urls` | JSONB | Array d'URLs photos |
| `opening_hours` | JSONB | Horaires d'ouverture |
| `owner_id` | UUID (FK) | Propriétaire (si revendiqué) |
| `is_verified` | BOOLEAN | Badge "Vérifié" |
| `is_active` | BOOLEAN | Commerce actif |
| `rating_avg` | DECIMAL(2,1) | Note moyenne |
| `rating_count` | INTEGER | Nombre d'avis |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Dernière mise à jour |

**Point clé PostGIS :** Le type `GEOGRAPHY(Point, 4326)` permet des requêtes comme :
```sql
SELECT * FROM vendors 
WHERE ST_DWithin(location, ST_Point(10.1815, 36.8065)::geography, 5000)
-- Trouve tous les commerces dans un rayon de 5km autour de Tunis
```

---

### 4. `units` - Unités de mesure

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `name_fr` | VARCHAR(50) | Nom français (kilogramme) |
| `name_ar` | VARCHAR(50) | Nom arabe |
| `symbol` | VARCHAR(10) | Symbole (kg, L, unité) |
| `type` | ENUM | 'weight', 'volume', 'count', 'service', 'time' |

**Exemples :**
| symbol | type | Usage |
|--------|------|-------|
| kg | weight | Viande, fruits |
| L | volume | Huile, lait |
| unité | count | Pain, oeufs |
| séance | service | Coiffeur |
| m² | area | Carrelage |

---

### 5. `products` - Produits et Services

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `parent_id` | UUID (FK) | Hiérarchie (Viande → Bœuf) |
| `name_fr` | VARCHAR(200) | Nom français |
| `name_ar` | VARCHAR(200) | Nom arabe |
| `slug` | VARCHAR(200) | URL-friendly |
| `description_fr` | TEXT | Description FR |
| `description_ar` | TEXT | Description AR |
| `category_id` | UUID (FK) | Catégorie associée |
| `unit_id` | UUID (FK) | Unité de mesure par défaut |
| `barcode` | VARCHAR(50) | Code-barres (si applicable) |
| `image_url` | TEXT | Image du produit |
| `aliases` | JSONB | Synonymes pour la recherche |
| `is_active` | BOOLEAN | Produit actif |
| `search_vector` | TSVECTOR | Full-text search (FR/AR) |

**Hiérarchie produits (exemple Boucherie) :**
```
Viande Rouge (parent_id: null)
├── Bœuf
│   ├── Filet de bœuf
│   ├── Entrecôte
│   └── Viande hachée bœuf
├── Agneau
│   ├── Gigot d'agneau
│   └── Côtelettes
└── Veau
```

**Champ `aliases`** (important pour la recherche) :
```json
{
  "fr": ["steak", "bifteck", "bavette"],
  "ar": ["لحم", "ستيك"],
  "dialect": ["lahm", "3ajel"]  // Tunisien translittéré
}
```

---

### 6. `price_reports` - Signalements de prix (Crowdsourcing)

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `product_id` | UUID (FK) | Produit concerné |
| `vendor_id` | UUID (FK) | Commerce concerné |
| `user_id` | UUID (FK) | Utilisateur qui signale |
| `price` | DECIMAL(10,3) | Prix en TND |
| `unit_id` | UUID (FK) | Unité du prix |
| `quantity` | DECIMAL(10,3) | Quantité (ex: 0.5 kg) |
| `currency` | VARCHAR(3) | 'TND' par défaut |
| `is_promotion` | BOOLEAN | Prix promo |
| `promo_end_date` | DATE | Fin de la promo |
| `photo_url` | TEXT | Photo preuve (optionnel) |
| `confidence_score` | DECIMAL(3,2) | Score de confiance (0-1) |
| `upvotes` | INTEGER | Votes positifs |
| `downvotes` | INTEGER | Votes négatifs |
| `is_verified` | BOOLEAN | Vérifié par le commerçant |
| `is_active` | BOOLEAN | Prix toujours valide |
| `expires_at` | TIMESTAMPTZ | Expiration auto (7 jours) |
| `created_at` | TIMESTAMPTZ | Date du signalement |

**Calcul du `confidence_score`** :
```
score = (upvotes - downvotes) / (upvotes + downvotes + 1) 
        * freshness_factor  -- Pénalité si ancien
        * (1.2 if is_verified else 1.0)  -- Bonus commerçant
        * (1.1 if photo_url else 1.0)  -- Bonus photo
```

---

### 7. `price_votes` - Votes sur les prix

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `price_report_id` | UUID (FK) | Prix concerné |
| `user_id` | UUID (FK) | Utilisateur votant |
| `is_valid` | BOOLEAN | true=correct, false=incorrect |
| `created_at` | TIMESTAMPTZ | Date du vote |

**Contrainte UNIQUE** sur `(price_report_id, user_id)` : un utilisateur ne peut voter qu'une fois par prix.

---

### 8. `price_history` - Historique des prix

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `product_id` | UUID (FK) | Produit |
| `vendor_id` | UUID (FK) | Commerce |
| `price` | DECIMAL(10,3) | Prix archivé |
| `unit_id` | UUID (FK) | Unité |
| `recorded_at` | TIMESTAMPTZ | Date d'enregistrement |
| `source_report_id` | UUID (FK) | Report d'origine |

**Usage :** Générer des graphiques d'évolution des prix, détecter l'inflation.

---

### 9. `user_contributions` - Points et badges

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID (PK) | Identifiant unique |
| `user_id` | UUID (FK) | Utilisateur |
| `action_type` | ENUM | 'price_report', 'vote', 'vendor_add' |
| `points_earned` | INTEGER | Points gagnés |
| `reference_id` | UUID | ID de l'action (report, vote...) |
| `created_at` | TIMESTAMPTZ | Date de l'action |

**Barème de points :**
| Action | Points |
|--------|--------|
| Ajout de prix | +10 |
| Ajout de prix avec photo | +15 |
| Vote confirmé (majorité) | +2 |
| Ajout d'un commerce | +20 |
| Prix confirmé par commerçant | +25 |

---

## Index Critiques pour la Performance

```sql
-- Index géospatial (LE PLUS IMPORTANT)
CREATE INDEX idx_vendors_location ON vendors USING GIST (location);

-- Index pour recherche de prix par produit/vendor
CREATE INDEX idx_price_reports_product_vendor 
ON price_reports (product_id, vendor_id, is_active) 
WHERE is_active = true;

-- Index full-text pour recherche produits
CREATE INDEX idx_products_search ON products USING GIN (search_vector);

-- Index pour les prix actifs récents
CREATE INDEX idx_price_reports_recent 
ON price_reports (created_at DESC) 
WHERE is_active = true;

-- Index composite pour requêtes par catégorie + localisation
CREATE INDEX idx_vendors_category ON vendors (category_id, is_active);
```

---

## Vues Matérialisées

### `mv_best_prices` - Meilleurs prix actuels par produit/zone

```sql
CREATE MATERIALIZED VIEW mv_best_prices AS
SELECT 
    p.id as product_id,
    v.id as vendor_id,
    v.name as vendor_name,
    v.location,
    pr.price,
    pr.unit_id,
    pr.confidence_score,
    pr.updated_at,
    ROW_NUMBER() OVER (
        PARTITION BY p.id 
        ORDER BY pr.price ASC, pr.confidence_score DESC
    ) as price_rank
FROM products p
JOIN price_reports pr ON pr.product_id = p.id AND pr.is_active = true
JOIN vendors v ON v.id = pr.vendor_id AND v.is_active = true
WHERE pr.expires_at > NOW();

-- Refresh toutes les 5 minutes
```

Cette vue permet de récupérer instantanément les meilleurs prix sans calcul à la volée.

---

## Fonctions PostGIS Clés

### Trouver les commerces dans un rayon

```sql
CREATE OR REPLACE FUNCTION find_vendors_in_radius(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_meters INTEGER,
    category_slug VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    vendor_id UUID,
    name VARCHAR,
    distance_meters DOUBLE PRECISION,
    location GEOGRAPHY
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.name,
        ST_Distance(v.location, ST_Point(lng, lat)::geography) as distance,
        v.location
    FROM vendors v
    LEFT JOIN categories c ON c.id = v.category_id
    WHERE v.is_active = true
        AND ST_DWithin(v.location, ST_Point(lng, lat)::geography, radius_meters)
        AND (category_slug IS NULL OR c.slug = category_slug)
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;
```

### Recherche de produits avec prix locaux

```sql
CREATE OR REPLACE FUNCTION search_products_with_prices(
    search_query TEXT,
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    vendor_id UUID,
    vendor_name VARCHAR,
    price DECIMAL,
    unit_symbol VARCHAR,
    distance_meters DOUBLE PRECISION,
    price_rank INTEGER  -- 1=moins cher, 2=moyen, 3=plus cher
) AS $$
BEGIN
    RETURN QUERY
    WITH nearby_prices AS (
        SELECT 
            p.id as pid,
            p.name_fr as pname,
            v.id as vid,
            v.name as vname,
            pr.price,
            u.symbol,
            ST_Distance(v.location, ST_Point(user_lng, user_lat)::geography) as dist,
            NTILE(3) OVER (PARTITION BY p.id ORDER BY pr.price ASC) as rank
        FROM products p
        JOIN price_reports pr ON pr.product_id = p.id AND pr.is_active = true
        JOIN vendors v ON v.id = pr.vendor_id
        JOIN units u ON u.id = pr.unit_id
        WHERE p.search_vector @@ plainto_tsquery('french', search_query)
            AND ST_DWithin(v.location, ST_Point(user_lng, user_lat)::geography, radius_meters)
    )
    SELECT pid, pname, vid, vname, price, symbol, dist, rank::INTEGER
    FROM nearby_prices
    ORDER BY rank, price, dist;
END;
$$ LANGUAGE plpgsql;
```

---

## Policies Row Level Security (RLS)

```sql
-- Les utilisateurs peuvent voir tous les prix
CREATE POLICY "Public read prices" ON price_reports
    FOR SELECT USING (is_active = true);

-- Seul l'auteur ou un admin peut modifier un report
CREATE POLICY "Owner can update" ON price_reports
    FOR UPDATE USING (auth.uid() = user_id);

-- Les commerçants vérifiés peuvent modifier leurs prix
CREATE POLICY "Merchant can update own vendor prices" ON price_reports
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM vendors v 
            WHERE v.id = vendor_id 
            AND v.owner_id = auth.uid()
            AND v.is_verified = true
        )
    );
```

---

## Logique de Comparaison des Prix

### Le Problème
Quand l'utilisateur cherche "Viande", il faut :
1. Trouver tous les produits matchant (Bœuf, Agneau, Viande hachée...)
2. Grouper par type comparable (ne pas comparer filet mignon et viande hachée)
3. Attribuer un code couleur basé sur le percentile local

### La Solution : Taxonomie Flexible

```sql
-- 1. Résolution de la recherche vers produits comparables
SELECT * FROM products 
WHERE search_vector @@ to_tsquery('viande')
   OR parent_id IN (SELECT id FROM products WHERE search_vector @@ to_tsquery('viande'));

-- 2. Calcul des percentiles par groupe de produits
WITH price_stats AS (
    SELECT 
        product_id,
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY price) as p33,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY price) as p66
    FROM price_reports
    WHERE product_id IN (...) AND is_active = true
    GROUP BY product_id
)
SELECT 
    pr.*,
    CASE 
        WHEN pr.price <= ps.p33 THEN 'green'   -- Moins cher (33% inf)
        WHEN pr.price <= ps.p66 THEN 'orange'  -- Moyen
        ELSE 'red'                              -- Plus cher (33% sup)
    END as price_color
FROM price_reports pr
JOIN price_stats ps ON ps.product_id = pr.product_id;
```

### Alternative : Score Normalisé

Pour comparer des produits de catégories différentes (ex: recherche "courses"), on peut utiliser un score Z normalisé :

```sql
z_score = (price - avg_price_category) / stddev_price_category
```

Un z_score < -0.5 = Vert, entre -0.5 et 0.5 = Orange, > 0.5 = Rouge.

---

## Résumé de l'Architecture

| Aspect | Choix | Justification |
|--------|-------|---------------|
| **DB** | PostgreSQL + PostGIS | Requêtes géo performantes, SQL standard |
| **Recherche** | Full-text + trigram | Supporte FR/AR, fautes de frappe |
| **Hiérarchie** | Self-referencing (parent_id) | Flexible, pas de limite de profondeur |
| **Prix** | Crowdsourced + verified | Double source de vérité |
| **Performance** | Materialized views + Index GIST | Réponse < 100ms |
| **Sécurité** | RLS Supabase | Contrôle fin des accès |
