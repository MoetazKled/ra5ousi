-- ============================================================================
-- PriceMap Tunisia - Migration Initiale
-- Base de données PostgreSQL avec PostGIS pour Supabase
-- ============================================================================

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Pour la recherche floue

-- ============================================================================
-- TYPES ENUM
-- ============================================================================

CREATE TYPE user_role AS ENUM ('user', 'merchant', 'admin');
CREATE TYPE category_type AS ENUM ('vendor', 'product');
CREATE TYPE unit_type AS ENUM ('weight', 'volume', 'count', 'service', 'time', 'area', 'length');
CREATE TYPE contribution_type AS ENUM ('price_report', 'price_vote', 'vendor_add', 'vendor_claim', 'photo_add');

-- ============================================================================
-- TABLE: users
-- Gestion des utilisateurs de l'application
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    phone VARCHAR(20),
    role user_role DEFAULT 'user',
    points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    preferred_language VARCHAR(2) DEFAULT 'fr' CHECK (preferred_language IN ('fr', 'ar')),
    notification_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche par email
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role ON users (role);

-- ============================================================================
-- TABLE: categories
-- Catégories hiérarchiques pour commerces et produits
-- ============================================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name_fr VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    slug VARCHAR(100) UNIQUE NOT NULL,
    icon VARCHAR(50) DEFAULT 'category',
    color VARCHAR(7) DEFAULT '#6366F1',
    type category_type NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour navigation hiérarchique
CREATE INDEX idx_categories_parent ON categories (parent_id);
CREATE INDEX idx_categories_type ON categories (type, is_active);
CREATE INDEX idx_categories_slug ON categories (slug);

-- ============================================================================
-- TABLE: units
-- Unités de mesure pour les prix
-- ============================================================================

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_fr VARCHAR(50) NOT NULL,
    name_ar VARCHAR(50),
    symbol VARCHAR(20) NOT NULL,
    type unit_type NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index par type d'unité
CREATE INDEX idx_units_type ON units (type);

-- ============================================================================
-- TABLE: vendors
-- Commerces et points de vente (avec géolocalisation PostGIS)
-- ============================================================================

CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_place_id VARCHAR(255) UNIQUE,
    name VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200),
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    -- Point géographique PostGIS (SRID 4326 = WGS84, standard GPS)
    location GEOGRAPHY(Point, 4326) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    governorate VARCHAR(100),
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    website VARCHAR(255),
    photo_urls JSONB DEFAULT '[]'::jsonb,
    opening_hours JSONB DEFAULT '{}'::jsonb,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    rating_avg DECIMAL(2,1) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    price_report_count INTEGER DEFAULT 0,
    last_price_update TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEX GÉOSPATIAL CRITIQUE (utilise GIST pour PostGIS)
CREATE INDEX idx_vendors_location ON vendors USING GIST (location);

-- Autres index utiles
CREATE INDEX idx_vendors_category ON vendors (category_id, is_active);
CREATE INDEX idx_vendors_city ON vendors (city, governorate);
CREATE INDEX idx_vendors_owner ON vendors (owner_id) WHERE owner_id IS NOT NULL;
CREATE INDEX idx_vendors_google_place ON vendors (google_place_id) WHERE google_place_id IS NOT NULL;

-- Index pour recherche textuelle sur le nom
CREATE INDEX idx_vendors_name_trgm ON vendors USING GIN (name gin_trgm_ops);

-- ============================================================================
-- TABLE: products
-- Produits et services avec hiérarchie et recherche full-text
-- ============================================================================

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES products(id) ON DELETE SET NULL,
    name_fr VARCHAR(200) NOT NULL,
    name_ar VARCHAR(200),
    slug VARCHAR(200) UNIQUE NOT NULL,
    description_fr TEXT,
    description_ar TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    barcode VARCHAR(50),
    image_url TEXT,
    -- Synonymes et alias pour améliorer la recherche
    aliases JSONB DEFAULT '{"fr": [], "ar": [], "dialect": []}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    -- Vecteur de recherche full-text (français)
    search_vector TSVECTOR,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index hiérarchique
CREATE INDEX idx_products_parent ON products (parent_id);
CREATE INDEX idx_products_category ON products (category_id, is_active);
CREATE INDEX idx_products_barcode ON products (barcode) WHERE barcode IS NOT NULL;

-- Index full-text search
CREATE INDEX idx_products_search ON products USING GIN (search_vector);

-- Index trigram pour recherche floue
CREATE INDEX idx_products_name_trgm ON products USING GIN (name_fr gin_trgm_ops);

-- ============================================================================
-- TABLE: price_reports
-- Signalements de prix par les utilisateurs (crowdsourcing)
-- ============================================================================

CREATE TABLE price_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    price DECIMAL(10,3) NOT NULL CHECK (price > 0),
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    quantity DECIMAL(10,3) DEFAULT 1,
    currency VARCHAR(3) DEFAULT 'TND',
    is_promotion BOOLEAN DEFAULT false,
    promo_end_date DATE,
    photo_url TEXT,
    notes TEXT,
    -- Score de confiance calculé (0.0 à 1.0)
    confidence_score DECIMAL(3,2) DEFAULT 0.50,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    -- Expiration automatique après 7 jours sans confirmation
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index composite pour recherche de prix
CREATE INDEX idx_price_reports_product_vendor ON price_reports (product_id, vendor_id, is_active) WHERE is_active = true;
CREATE INDEX idx_price_reports_vendor ON price_reports (vendor_id, is_active) WHERE is_active = true;
CREATE INDEX idx_price_reports_user ON price_reports (user_id);
CREATE INDEX idx_price_reports_recent ON price_reports (created_at DESC) WHERE is_active = true;
CREATE INDEX idx_price_reports_expires ON price_reports (expires_at) WHERE is_active = true;

-- ============================================================================
-- TABLE: price_votes
-- Votes des utilisateurs sur les prix signalés
-- ============================================================================

CREATE TABLE price_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    price_report_id UUID NOT NULL REFERENCES price_reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_valid BOOLEAN NOT NULL,  -- true = prix correct, false = prix incorrect
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Un utilisateur ne peut voter qu'une fois par prix
    CONSTRAINT unique_vote_per_user UNIQUE (price_report_id, user_id)
);

CREATE INDEX idx_price_votes_report ON price_votes (price_report_id);
CREATE INDEX idx_price_votes_user ON price_votes (user_id);

-- ============================================================================
-- TABLE: price_history
-- Historique des prix pour analytics et graphiques
-- ============================================================================

CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    price DECIMAL(10,3) NOT NULL,
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    currency VARCHAR(3) DEFAULT 'TND',
    source_report_id UUID REFERENCES price_reports(id) ON DELETE SET NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour requêtes d'historique
CREATE INDEX idx_price_history_product ON price_history (product_id, recorded_at DESC);
CREATE INDEX idx_price_history_vendor ON price_history (vendor_id, recorded_at DESC);
CREATE INDEX idx_price_history_date ON price_history (recorded_at DESC);

-- ============================================================================
-- TABLE: user_contributions
-- Tracking des contributions pour gamification
-- ============================================================================

CREATE TABLE user_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type contribution_type NOT NULL,
    points_earned INTEGER NOT NULL DEFAULT 0,
    reference_id UUID,  -- ID de l'objet concerné (price_report, vendor, etc.)
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contributions_user ON user_contributions (user_id, created_at DESC);
CREATE INDEX idx_contributions_type ON user_contributions (action_type);

-- ============================================================================
-- TABLE: favorites
-- Favoris des utilisateurs (produits et commerces)
-- ============================================================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Au moins un des deux doit être défini
    CONSTRAINT fav_has_target CHECK (vendor_id IS NOT NULL OR product_id IS NOT NULL),
    -- Unique par utilisateur/cible
    CONSTRAINT unique_favorite UNIQUE (user_id, vendor_id, product_id)
);

CREATE INDEX idx_favorites_user ON favorites (user_id);

-- ============================================================================
-- TABLE: search_history
-- Historique de recherche pour suggestions
-- ============================================================================

CREATE TABLE search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    result_count INTEGER DEFAULT 0,
    location GEOGRAPHY(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_search_history_user ON search_history (user_id, created_at DESC);
CREATE INDEX idx_search_history_query ON search_history USING GIN (query gin_trgm_ops);

-- ============================================================================
-- FONCTIONS ET TRIGGERS
-- ============================================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger sur toutes les tables avec updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_price_reports_updated_at BEFORE UPDATE ON price_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Fonction pour générer le search_vector des produits
-- ============================================================================

CREATE OR REPLACE FUNCTION products_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('french', COALESCE(NEW.name_fr, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.name_ar, '')), 'A') ||
        setweight(to_tsvector('french', COALESCE(NEW.description_fr, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.aliases::text, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_search_vector_trigger
    BEFORE INSERT OR UPDATE OF name_fr, name_ar, description_fr, aliases
    ON products
    FOR EACH ROW
    EXECUTE FUNCTION products_search_vector_update();

-- ============================================================================
-- Fonction pour mettre à jour les compteurs de votes
-- ============================================================================

CREATE OR REPLACE FUNCTION update_price_report_votes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.is_valid THEN
            UPDATE price_reports SET upvotes = upvotes + 1 WHERE id = NEW.price_report_id;
        ELSE
            UPDATE price_reports SET downvotes = downvotes + 1 WHERE id = NEW.price_report_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.is_valid THEN
            UPDATE price_reports SET upvotes = upvotes - 1 WHERE id = OLD.price_report_id;
        ELSE
            UPDATE price_reports SET downvotes = downvotes - 1 WHERE id = OLD.price_report_id;
        END IF;
    ELSIF TG_OP = 'UPDATE' AND OLD.is_valid != NEW.is_valid THEN
        IF NEW.is_valid THEN
            UPDATE price_reports SET upvotes = upvotes + 1, downvotes = downvotes - 1 WHERE id = NEW.price_report_id;
        ELSE
            UPDATE price_reports SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.price_report_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER price_votes_counter_trigger
    AFTER INSERT OR UPDATE OR DELETE ON price_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_price_report_votes();

-- ============================================================================
-- Fonction pour calculer le score de confiance
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_confidence_score(
    p_upvotes INTEGER,
    p_downvotes INTEGER,
    p_created_at TIMESTAMPTZ,
    p_is_verified BOOLEAN,
    p_has_photo BOOLEAN
)
RETURNS DECIMAL AS $$
DECLARE
    base_score DECIMAL;
    freshness_factor DECIMAL;
    age_days INTEGER;
BEGIN
    -- Score de base basé sur les votes (Wilson score simplifié)
    IF (p_upvotes + p_downvotes) = 0 THEN
        base_score := 0.5;
    ELSE
        base_score := (p_upvotes + 1.0) / (p_upvotes + p_downvotes + 2.0);
    END IF;
    
    -- Facteur de fraîcheur (décroît avec l'âge)
    age_days := EXTRACT(DAY FROM NOW() - p_created_at);
    freshness_factor := GREATEST(0.5, 1.0 - (age_days * 0.05));
    
    -- Appliquer les bonus
    base_score := base_score * freshness_factor;
    
    IF p_is_verified THEN
        base_score := base_score * 1.2;
    END IF;
    
    IF p_has_photo THEN
        base_score := base_score * 1.1;
    END IF;
    
    RETURN LEAST(1.0, base_score);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Fonction pour attribuer des points
-- ============================================================================

CREATE OR REPLACE FUNCTION award_points(
    p_user_id UUID,
    p_action contribution_type,
    p_reference_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS INTEGER AS $$
DECLARE
    points_to_award INTEGER;
BEGIN
    -- Définir les points selon l'action
    points_to_award := CASE p_action
        WHEN 'price_report' THEN 10
        WHEN 'price_vote' THEN 2
        WHEN 'vendor_add' THEN 20
        WHEN 'vendor_claim' THEN 5
        WHEN 'photo_add' THEN 5
        ELSE 1
    END;
    
    -- Bonus si photo incluse
    IF p_metadata->>'has_photo' = 'true' AND p_action = 'price_report' THEN
        points_to_award := points_to_award + 5;
    END IF;
    
    -- Enregistrer la contribution
    INSERT INTO user_contributions (user_id, action_type, points_earned, reference_id, metadata)
    VALUES (p_user_id, p_action, points_to_award, p_reference_id, p_metadata);
    
    -- Mettre à jour les points de l'utilisateur
    UPDATE users SET points = points + points_to_award WHERE id = p_user_id;
    
    -- Mettre à jour le niveau si nécessaire
    UPDATE users SET level = FLOOR(SQRT(points / 100)) + 1 WHERE id = p_user_id;
    
    RETURN points_to_award;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FONCTIONS GÉOSPATIALES
-- ============================================================================

-- Trouver les commerces dans un rayon
CREATE OR REPLACE FUNCTION find_vendors_in_radius(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters INTEGER DEFAULT 5000,
    p_category_slug VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    vendor_id UUID,
    name VARCHAR,
    name_ar VARCHAR,
    category_name VARCHAR,
    address TEXT,
    phone VARCHAR,
    distance_meters DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_verified BOOLEAN,
    rating_avg DECIMAL,
    photo_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.name,
        v.name_ar,
        c.name_fr,
        v.address,
        v.phone,
        ST_Distance(v.location, ST_Point(p_lng, p_lat)::geography) as distance,
        ST_Y(v.location::geometry) as lat,
        ST_X(v.location::geometry) as lng,
        v.is_verified,
        v.rating_avg,
        v.photo_urls->>0 as photo
    FROM vendors v
    LEFT JOIN categories c ON c.id = v.category_id
    WHERE v.is_active = true
        AND ST_DWithin(v.location, ST_Point(p_lng, p_lat)::geography, p_radius_meters)
        AND (p_category_slug IS NULL OR c.slug = p_category_slug)
    ORDER BY distance
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Rechercher des produits avec leurs prix locaux
CREATE OR REPLACE FUNCTION search_products_with_local_prices(
    p_search_query TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters INTEGER DEFAULT 5000,
    p_limit INTEGER DEFAULT 30
)
RETURNS TABLE (
    product_id UUID,
    product_name_fr VARCHAR,
    product_name_ar VARCHAR,
    vendor_id UUID,
    vendor_name VARCHAR,
    vendor_address TEXT,
    price DECIMAL,
    unit_symbol VARCHAR,
    distance_meters DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    confidence_score DECIMAL,
    is_verified BOOLEAN,
    price_color VARCHAR,  -- 'green', 'orange', 'red'
    reported_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    WITH search_results AS (
        SELECT 
            p.id as pid,
            p.name_fr as pname_fr,
            p.name_ar as pname_ar,
            v.id as vid,
            v.name as vname,
            v.address as vaddress,
            pr.price as pprice,
            u.symbol as usymbol,
            ST_Distance(v.location, ST_Point(p_lng, p_lat)::geography) as dist,
            ST_Y(v.location::geometry) as vlat,
            ST_X(v.location::geometry) as vlng,
            pr.confidence_score as conf,
            pr.is_verified as verified,
            pr.created_at as reported
        FROM products p
        JOIN price_reports pr ON pr.product_id = p.id AND pr.is_active = true
        JOIN vendors v ON v.id = pr.vendor_id AND v.is_active = true
        LEFT JOIN units u ON u.id = pr.unit_id
        WHERE (
            p.search_vector @@ plainto_tsquery('french', p_search_query)
            OR p.name_fr ILIKE '%' || p_search_query || '%'
            OR p.name_ar ILIKE '%' || p_search_query || '%'
            OR similarity(p.name_fr, p_search_query) > 0.3
        )
        AND ST_DWithin(v.location, ST_Point(p_lng, p_lat)::geography, p_radius_meters)
        AND pr.expires_at > NOW()
    ),
    price_percentiles AS (
        SELECT 
            pid,
            PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY pprice) as p33,
            PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY pprice) as p66
        FROM search_results
        GROUP BY pid
    )
    SELECT 
        sr.pid,
        sr.pname_fr,
        sr.pname_ar,
        sr.vid,
        sr.vname,
        sr.vaddress,
        sr.pprice,
        sr.usymbol,
        sr.dist,
        sr.vlat,
        sr.vlng,
        sr.conf,
        sr.verified,
        CASE 
            WHEN sr.pprice <= pp.p33 THEN 'green'
            WHEN sr.pprice <= pp.p66 THEN 'orange'
            ELSE 'red'
        END::VARCHAR as color,
        sr.reported
    FROM search_results sr
    JOIN price_percentiles pp ON pp.pid = sr.pid
    ORDER BY sr.pprice ASC, sr.conf DESC, sr.dist ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_contributions ENABLE ROW LEVEL SECURITY;

-- Policies pour users
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Policies pour vendors (lecture publique)
CREATE POLICY "Anyone can view active vendors" ON vendors FOR SELECT USING (is_active = true);
CREATE POLICY "Authenticated users can insert vendors" ON vendors FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Owners can update their vendors" ON vendors FOR UPDATE USING (auth.uid() = owner_id);

-- Policies pour products (lecture publique)
CREATE POLICY "Anyone can view active products" ON products FOR SELECT USING (is_active = true);

-- Policies pour price_reports
CREATE POLICY "Anyone can view active prices" ON price_reports FOR SELECT USING (is_active = true);
CREATE POLICY "Authenticated users can add prices" ON price_reports FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own reports" ON price_reports FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Verified merchants can update prices for their vendors" ON price_reports FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM vendors v 
        WHERE v.id = vendor_id 
        AND v.owner_id = auth.uid()
        AND v.is_verified = true
    )
);

-- Policies pour price_votes
CREATE POLICY "Anyone can view votes" ON price_votes FOR SELECT USING (true);
CREATE POLICY "Authenticated users can vote" ON price_votes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own votes" ON price_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own votes" ON price_votes FOR DELETE USING (auth.uid() = user_id);

-- Policies pour favorites
CREATE POLICY "Users can view own favorites" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (auth.uid() = user_id);

-- Policies pour contributions
CREATE POLICY "Users can view own contributions" ON user_contributions FOR SELECT USING (auth.uid() = user_id);

-- ============================================================================
-- COMMENTAIRES SUR LES TABLES (Documentation)
-- ============================================================================

COMMENT ON TABLE users IS 'Utilisateurs de l''application PriceMap Tunisia';
COMMENT ON TABLE categories IS 'Catégories hiérarchiques pour commerces et produits';
COMMENT ON TABLE units IS 'Unités de mesure (kg, L, unité, séance, etc.)';
COMMENT ON TABLE vendors IS 'Commerces et points de vente géolocalisés';
COMMENT ON TABLE products IS 'Produits et services avec recherche full-text';
COMMENT ON TABLE price_reports IS 'Prix signalés par les utilisateurs (crowdsourcing)';
COMMENT ON TABLE price_votes IS 'Votes de confirmation/infirmation des prix';
COMMENT ON TABLE price_history IS 'Historique des prix pour analytics';
COMMENT ON TABLE user_contributions IS 'Points et actions pour gamification';

COMMENT ON COLUMN vendors.location IS 'Point géographique PostGIS (SRID 4326 = WGS84)';
COMMENT ON COLUMN products.search_vector IS 'Vecteur tsvector pour recherche full-text multilingue';
COMMENT ON COLUMN price_reports.confidence_score IS 'Score de confiance 0-1 basé sur votes, fraîcheur, vérification';
