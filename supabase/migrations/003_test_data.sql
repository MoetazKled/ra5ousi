-- ============================================================================
-- PriceMap Tunisia - Données de Test (Tunis)
-- Commerces et prix fictifs pour démonstration
-- ============================================================================

-- ============================================================================
-- COMMERCES DE TEST (TUNIS)
-- ============================================================================

-- Boucheries
INSERT INTO vendors (id, name, name_ar, category_id, location, address, city, governorate, phone, is_verified, is_active) VALUES
    ('55555555-0000-0000-0000-000000000001', 'Boucherie El Baraka', 'جزارة البركة', '22222222-0000-0000-0000-000000000002', 
     ST_SetSRID(ST_MakePoint(10.1815, 36.8065), 4326)::geography, '15 Avenue Habib Bourguiba', 'Tunis', 'Tunis', '+216 71 123 456', true, true),
    
    ('55555555-0000-0000-0000-000000000002', 'Boucherie Essalem', 'جزارة السلام', '22222222-0000-0000-0000-000000000002',
     ST_SetSRID(ST_MakePoint(10.1750, 36.8100), 4326)::geography, '23 Rue de Marseille', 'Tunis', 'Tunis', '+216 71 234 567', false, true),
    
    ('55555555-0000-0000-0000-000000000003', 'Boucherie Ben Ali', 'جزارة بن علي', '22222222-0000-0000-0000-000000000002',
     ST_SetSRID(ST_MakePoint(10.1880, 36.8030), 4326)::geography, '8 Avenue de la Liberté', 'Tunis', 'Tunis', '+216 71 345 678', true, true),

-- Boulangeries
    ('55555555-0000-0000-0000-000000000010', 'Boulangerie Le Croissant', 'مخبزة الكرواسون', '22222222-0000-0000-0000-000000000005',
     ST_SetSRID(ST_MakePoint(10.1790, 36.8080), 4326)::geography, '5 Rue de Rome', 'Tunis', 'Tunis', '+216 71 456 789', true, true),
    
    ('55555555-0000-0000-0000-000000000011', 'Boulangerie Essabah', 'مخبزة الصباح', '22222222-0000-0000-0000-000000000005',
     ST_SetSRID(ST_MakePoint(10.1830, 36.8045), 4326)::geography, '12 Avenue de Paris', 'Tunis', 'Tunis', '+216 71 567 890', false, true),

-- Épiceries
    ('55555555-0000-0000-0000-000000000020', 'Épicerie Chez Mohamed', 'بقالة عند محمد', '22222222-0000-0000-0000-000000000004',
     ST_SetSRID(ST_MakePoint(10.1800, 36.8055), 4326)::geography, '18 Rue Ibn Khaldoun', 'Tunis', 'Tunis', '+216 71 678 901', false, true),
    
    ('55555555-0000-0000-0000-000000000021', 'Superette El Manar', 'سوبريت المنار', '22222222-0000-0000-0000-000000000004',
     ST_SetSRID(ST_MakePoint(10.1760, 36.8090), 4326)::geography, '25 Avenue Farhat Hached', 'Tunis', 'Tunis', '+216 71 789 012', true, true),

-- Primeurs
    ('55555555-0000-0000-0000-000000000030', 'Primeur Fruits du Soleil', 'خضر وفواكه الشمس', '22222222-0000-0000-0000-000000000006',
     ST_SetSRID(ST_MakePoint(10.1840, 36.8070), 4326)::geography, '3 Marché Central', 'Tunis', 'Tunis', '+216 71 890 123', false, true),

-- Coiffeurs
    ('55555555-0000-0000-0000-000000000040', 'Salon Élégance', 'صالون الأناقة', '22222222-0000-0000-0000-000000000011',
     ST_SetSRID(ST_MakePoint(10.1770, 36.8060), 4326)::geography, '7 Rue de Hollande', 'Tunis', 'Tunis', '+216 71 901 234', true, true),
    
    ('55555555-0000-0000-0000-000000000041', 'Coiffeur Le Style', 'حلاق الستايل', '22222222-0000-0000-0000-000000000011',
     ST_SetSRID(ST_MakePoint(10.1820, 36.8095), 4326)::geography, '14 Avenue de Carthage', 'Tunis', 'Tunis', '+216 71 012 345', false, true),

-- Quincailleries
    ('55555555-0000-0000-0000-000000000050', 'Quincaillerie Générale', 'خردوات عامة', '22222222-0000-0000-0000-000000000021',
     ST_SetSRID(ST_MakePoint(10.1850, 36.8040), 4326)::geography, '20 Rue Mongi Slim', 'Tunis', 'Tunis', '+216 71 123 456', true, true);

-- ============================================================================
-- PRODUITS SUPPLÉMENTAIRES
-- ============================================================================

-- Pain
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000070', NULL, 'Pain', 'خبز', 'pain', '22222222-0000-0000-0000-000000000005', '11111111-0000-0000-0000-000000000006',
     '{"fr": ["baguette", "pain de mie"], "ar": ["خبز"], "dialect": ["khobz"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000071', '44444444-0000-0000-0000-000000000070', 'Baguette', 'باقيت', 'baguette', '22222222-0000-0000-0000-000000000005', '11111111-0000-0000-0000-000000000006',
     '{"fr": ["baguette française"], "ar": ["باقيت"], "dialect": []}'::jsonb),
    ('44444444-0000-0000-0000-000000000072', '44444444-0000-0000-0000-000000000070', 'Pain tabouna', 'طابونة', 'pain-tabouna', '22222222-0000-0000-0000-000000000005', '11111111-0000-0000-0000-000000000006',
     '{"fr": ["tabouna", "pain traditionnel"], "ar": ["طابونة"], "dialect": ["tabouna"]}'::jsonb);

-- ============================================================================
-- UTILISATEUR DE TEST
-- ============================================================================

INSERT INTO users (id, email, display_name, role, points, level) VALUES
    ('66666666-0000-0000-0000-000000000001', 'test@pricemap.tn', 'Utilisateur Test', 'user', 100, 2);

-- ============================================================================
-- PRIX DE TEST
-- ============================================================================

-- Prix Viande de bœuf
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    -- Boucherie El Baraka - Moins cher
    ('77777777-0000-0000-0000-000000000001', '44444444-0000-0000-0000-000000000001', '55555555-0000-0000-0000-000000000001', '66666666-0000-0000-0000-000000000001',
     28.500, '11111111-0000-0000-0000-000000000001', 'TND', 0.85, 15, true, true, NOW() + INTERVAL '30 days'),
    -- Boucherie Essalem - Moyen
    ('77777777-0000-0000-0000-000000000002', '44444444-0000-0000-0000-000000000001', '55555555-0000-0000-0000-000000000002', '66666666-0000-0000-0000-000000000001',
     32.000, '11111111-0000-0000-0000-000000000001', 'TND', 0.70, 8, false, true, NOW() + INTERVAL '30 days'),
    -- Boucherie Ben Ali - Plus cher
    ('77777777-0000-0000-0000-000000000003', '44444444-0000-0000-0000-000000000001', '55555555-0000-0000-0000-000000000003', '66666666-0000-0000-0000-000000000001',
     35.000, '11111111-0000-0000-0000-000000000001', 'TND', 0.90, 20, true, true, NOW() + INTERVAL '30 days');

-- Prix Poulet
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000010', '44444444-0000-0000-0000-000000000020', '55555555-0000-0000-0000-000000000001', '66666666-0000-0000-0000-000000000001',
     12.500, '11111111-0000-0000-0000-000000000001', 'TND', 0.80, 12, true, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000011', '44444444-0000-0000-0000-000000000020', '55555555-0000-0000-0000-000000000002', '66666666-0000-0000-0000-000000000001',
     13.800, '11111111-0000-0000-0000-000000000001', 'TND', 0.65, 5, false, true, NOW() + INTERVAL '30 days');

-- Prix Pain
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000020', '44444444-0000-0000-0000-000000000070', '55555555-0000-0000-0000-000000000010', '66666666-0000-0000-0000-000000000001',
     0.350, '11111111-0000-0000-0000-000000000006', 'TND', 0.90, 25, true, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000021', '44444444-0000-0000-0000-000000000070', '55555555-0000-0000-0000-000000000011', '66666666-0000-0000-0000-000000000001',
     0.400, '11111111-0000-0000-0000-000000000006', 'TND', 0.75, 10, false, true, NOW() + INTERVAL '30 days');

-- Prix Baguette
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000022', '44444444-0000-0000-0000-000000000071', '55555555-0000-0000-0000-000000000010', '66666666-0000-0000-0000-000000000001',
     0.800, '11111111-0000-0000-0000-000000000006', 'TND', 0.85, 18, true, true, NOW() + INTERVAL '30 days');

-- Prix Lait
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000030', '44444444-0000-0000-0000-000000000030', '55555555-0000-0000-0000-000000000020', '66666666-0000-0000-0000-000000000001',
     1.450, '11111111-0000-0000-0000-000000000004', 'TND', 0.88, 22, true, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000031', '44444444-0000-0000-0000-000000000030', '55555555-0000-0000-0000-000000000021', '66666666-0000-0000-0000-000000000001',
     1.500, '11111111-0000-0000-0000-000000000004', 'TND', 0.80, 15, true, true, NOW() + INTERVAL '30 days');

-- Prix Œufs (douzaine)
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000040', '44444444-0000-0000-0000-000000000033', '55555555-0000-0000-0000-000000000020', '66666666-0000-0000-0000-000000000001',
     4.200, '11111111-0000-0000-0000-000000000010', 'TND', 0.82, 14, false, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000041', '44444444-0000-0000-0000-000000000033', '55555555-0000-0000-0000-000000000021', '66666666-0000-0000-0000-000000000001',
     4.500, '11111111-0000-0000-0000-000000000010', 'TND', 0.78, 10, true, true, NOW() + INTERVAL '30 days');

-- Prix Huile d'olive
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000050', '44444444-0000-0000-0000-000000000063', '55555555-0000-0000-0000-000000000020', '66666666-0000-0000-0000-000000000001',
     15.000, '11111111-0000-0000-0000-000000000004', 'TND', 0.75, 8, false, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000051', '44444444-0000-0000-0000-000000000063', '55555555-0000-0000-0000-000000000021', '66666666-0000-0000-0000-000000000001',
     18.500, '11111111-0000-0000-0000-000000000004', 'TND', 0.85, 12, true, true, NOW() + INTERVAL '30 days');

-- Prix Tomates
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000060', '44444444-0000-0000-0000-000000000060', '55555555-0000-0000-0000-000000000030', '66666666-0000-0000-0000-000000000001',
     2.800, '11111111-0000-0000-0000-000000000001', 'TND', 0.70, 6, false, true, NOW() + INTERVAL '30 days');

-- Prix Coupe homme (coiffeur)
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000070', '44444444-0000-0000-0000-000000000040', '55555555-0000-0000-0000-000000000040', '66666666-0000-0000-0000-000000000001',
     8.000, '11111111-0000-0000-0000-000000000011', 'TND', 0.90, 30, true, true, NOW() + INTERVAL '30 days'),
    ('77777777-0000-0000-0000-000000000071', '44444444-0000-0000-0000-000000000040', '55555555-0000-0000-0000-000000000041', '66666666-0000-0000-0000-000000000001',
     12.000, '11111111-0000-0000-0000-000000000011', 'TND', 0.75, 15, false, true, NOW() + INTERVAL '30 days');

-- Prix Ciment
INSERT INTO price_reports (id, product_id, vendor_id, user_id, price, unit_id, currency, confidence_score, upvotes, is_verified, is_active, expires_at) VALUES
    ('77777777-0000-0000-0000-000000000080', '44444444-0000-0000-0000-000000000050', '55555555-0000-0000-0000-000000000050', '66666666-0000-0000-0000-000000000001',
     0.450, '11111111-0000-0000-0000-000000000001', 'TND', 0.85, 20, true, true, NOW() + INTERVAL '30 days');

-- ============================================================================
-- Mise à jour des compteurs de prix sur les vendors
-- ============================================================================

UPDATE vendors SET price_report_count = (
    SELECT COUNT(*) FROM price_reports WHERE vendor_id = vendors.id AND is_active = true
);

UPDATE vendors SET last_price_update = (
    SELECT MAX(created_at) FROM price_reports WHERE vendor_id = vendors.id
);
