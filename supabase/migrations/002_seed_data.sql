-- ============================================================================
-- PriceMap Tunisia - Données Initiales (Seed)
-- Catégories, Unités de mesure, Produits de base
-- ============================================================================

-- ============================================================================
-- UNITÉS DE MESURE
-- ============================================================================

INSERT INTO units (id, name_fr, name_ar, symbol, type, is_default) VALUES
    -- Poids
    ('11111111-0000-0000-0000-000000000001', 'Kilogramme', 'كيلوغرام', 'kg', 'weight', true),
    ('11111111-0000-0000-0000-000000000002', 'Gramme', 'غرام', 'g', 'weight', false),
    ('11111111-0000-0000-0000-000000000003', 'Livre', 'رطل', 'lb', 'weight', false),
    -- Volume
    ('11111111-0000-0000-0000-000000000004', 'Litre', 'لتر', 'L', 'volume', true),
    ('11111111-0000-0000-0000-000000000005', 'Millilitre', 'ميليلتر', 'mL', 'volume', false),
    -- Comptage
    ('11111111-0000-0000-0000-000000000006', 'Unité', 'وحدة', 'unité', 'count', true),
    ('11111111-0000-0000-0000-000000000007', 'Pièce', 'قطعة', 'pièce', 'count', false),
    ('11111111-0000-0000-0000-000000000008', 'Paquet', 'حزمة', 'paquet', 'count', false),
    ('11111111-0000-0000-0000-000000000009', 'Boîte', 'علبة', 'boîte', 'count', false),
    ('11111111-0000-0000-0000-000000000010', 'Douzaine', 'دزينة', 'dz', 'count', false),
    -- Services
    ('11111111-0000-0000-0000-000000000011', 'Séance', 'جلسة', 'séance', 'service', true),
    ('11111111-0000-0000-0000-000000000012', 'Prestation', 'خدمة', 'prestation', 'service', false),
    -- Temps
    ('11111111-0000-0000-0000-000000000013', 'Heure', 'ساعة', 'h', 'time', true),
    ('11111111-0000-0000-0000-000000000014', 'Jour', 'يوم', 'jour', 'time', false),
    -- Surface
    ('11111111-0000-0000-0000-000000000015', 'Mètre carré', 'متر مربع', 'm²', 'area', true),
    -- Longueur
    ('11111111-0000-0000-0000-000000000016', 'Mètre', 'متر', 'm', 'length', true),
    ('11111111-0000-0000-0000-000000000017', 'Centimètre', 'سنتيمتر', 'cm', 'length', false);

-- ============================================================================
-- CATÉGORIES DE COMMERCES (type: 'vendor')
-- ============================================================================

-- Catégories principales
INSERT INTO categories (id, parent_id, name_fr, name_ar, slug, icon, color, type, sort_order) VALUES
    -- Alimentation
    ('22222222-0000-0000-0000-000000000001', NULL, 'Alimentation', 'تغذية', 'alimentation', 'restaurant', '#EF4444', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', 'Boucherie', 'جزارة', 'boucherie', 'lunch_dining', '#DC2626', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000001', 'Poissonnerie', 'بائع السمك', 'poissonnerie', 'set_meal', '#0EA5E9', 'vendor', 2),
    ('22222222-0000-0000-0000-000000000004', '22222222-0000-0000-0000-000000000001', 'Épicerie', 'بقالة', 'epicerie', 'local_grocery_store', '#F59E0B', 'vendor', 3),
    ('22222222-0000-0000-0000-000000000005', '22222222-0000-0000-0000-000000000001', 'Boulangerie', 'مخبزة', 'boulangerie', 'bakery_dining', '#D97706', 'vendor', 4),
    ('22222222-0000-0000-0000-000000000006', '22222222-0000-0000-0000-000000000001', 'Primeur', 'بائع الخضر والفواكه', 'primeur', 'nutrition', '#22C55E', 'vendor', 5),
    ('22222222-0000-0000-0000-000000000007', '22222222-0000-0000-0000-000000000001', 'Supermarché', 'سوبرماركت', 'supermarche', 'store', '#6366F1', 'vendor', 6),
    
    -- Services
    ('22222222-0000-0000-0000-000000000010', NULL, 'Services', 'خدمات', 'services', 'miscellaneous_services', '#8B5CF6', 'vendor', 2),
    ('22222222-0000-0000-0000-000000000011', '22222222-0000-0000-0000-000000000010', 'Coiffeur', 'حلاق', 'coiffeur', 'content_cut', '#EC4899', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000012', '22222222-0000-0000-0000-000000000010', 'Pressing', 'تنظيف الملابس', 'pressing', 'local_laundry_service', '#14B8A6', 'vendor', 2),
    ('22222222-0000-0000-0000-000000000013', '22222222-0000-0000-0000-000000000010', 'Mécanicien', 'ميكانيكي', 'mecanicien', 'car_repair', '#64748B', 'vendor', 3),
    
    -- Bricolage & Construction
    ('22222222-0000-0000-0000-000000000020', NULL, 'Bricolage', 'أدوات البناء', 'bricolage', 'hardware', '#78716C', 'vendor', 3),
    ('22222222-0000-0000-0000-000000000021', '22222222-0000-0000-0000-000000000020', 'Quincaillerie', 'خردوات', 'quincaillerie', 'construction', '#A3A3A3', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000022', '22222222-0000-0000-0000-000000000020', 'Matériaux', 'مواد البناء', 'materiaux', 'foundation', '#737373', 'vendor', 2),
    ('22222222-0000-0000-0000-000000000023', '22222222-0000-0000-0000-000000000020', 'Peinture', 'دهان', 'peinture', 'format_paint', '#F97316', 'vendor', 3),
    
    -- Santé & Beauté
    ('22222222-0000-0000-0000-000000000030', NULL, 'Santé', 'صحة', 'sante', 'health_and_safety', '#10B981', 'vendor', 4),
    ('22222222-0000-0000-0000-000000000031', '22222222-0000-0000-0000-000000000030', 'Pharmacie', 'صيدلية', 'pharmacie', 'local_pharmacy', '#059669', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000032', '22222222-0000-0000-0000-000000000030', 'Optique', 'بصريات', 'optique', 'visibility', '#0D9488', 'vendor', 2),
    
    -- Autres
    ('22222222-0000-0000-0000-000000000040', NULL, 'Divers', 'متنوع', 'divers', 'category', '#6B7280', 'vendor', 10),
    ('22222222-0000-0000-0000-000000000041', '22222222-0000-0000-0000-000000000040', 'Librairie', 'مكتبة', 'librairie', 'menu_book', '#3B82F6', 'vendor', 1),
    ('22222222-0000-0000-0000-000000000042', '22222222-0000-0000-0000-000000000040', 'Électronique', 'إلكترونيات', 'electronique', 'devices', '#1E40AF', 'vendor', 2);

-- ============================================================================
-- CATÉGORIES DE PRODUITS (type: 'product')
-- ============================================================================

INSERT INTO categories (id, parent_id, name_fr, name_ar, slug, icon, color, type, sort_order) VALUES
    -- Viandes
    ('33333333-0000-0000-0000-000000000001', NULL, 'Viandes', 'لحوم', 'viandes', 'lunch_dining', '#DC2626', 'product', 1),
    ('33333333-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', 'Bœuf', 'لحم بقر', 'boeuf', 'lunch_dining', '#B91C1C', 'product', 1),
    ('33333333-0000-0000-0000-000000000003', '33333333-0000-0000-0000-000000000001', 'Agneau', 'لحم غنم', 'agneau', 'lunch_dining', '#991B1B', 'product', 2),
    ('33333333-0000-0000-0000-000000000004', '33333333-0000-0000-0000-000000000001', 'Poulet', 'دجاج', 'poulet', 'lunch_dining', '#F59E0B', 'product', 3),
    
    -- Produits laitiers
    ('33333333-0000-0000-0000-000000000010', NULL, 'Produits laitiers', 'منتجات الألبان', 'laitiers', 'egg_alt', '#FBBF24', 'product', 2),
    
    -- Fruits & Légumes
    ('33333333-0000-0000-0000-000000000020', NULL, 'Fruits & Légumes', 'فواكه وخضروات', 'fruits-legumes', 'nutrition', '#22C55E', 'product', 3),
    
    -- Services (produits)
    ('33333333-0000-0000-0000-000000000030', NULL, 'Services Coiffure', 'خدمات الحلاقة', 'services-coiffure', 'content_cut', '#EC4899', 'product', 4),
    
    -- Matériaux construction
    ('33333333-0000-0000-0000-000000000040', NULL, 'Matériaux Construction', 'مواد البناء', 'materiaux-construction', 'foundation', '#78716C', 'product', 5);

-- ============================================================================
-- PRODUITS DE BASE
-- ============================================================================

-- Viandes - Bœuf
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000001', NULL, 'Viande de bœuf', 'لحم بقر', 'viande-boeuf', '33333333-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001', 
     '{"fr": ["boeuf", "vache"], "ar": ["بقر"], "dialect": ["lahm bagri", "3ajel"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000002', '44444444-0000-0000-0000-000000000001', 'Filet de bœuf', 'فيليه بقر', 'filet-boeuf', '33333333-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["filet", "tournedos"], "ar": ["فيليه"], "dialect": ["file"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000003', '44444444-0000-0000-0000-000000000001', 'Viande hachée bœuf', 'لحم مفروم بقر', 'hache-boeuf', '33333333-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["haché", "steak haché", "kefta"], "ar": ["مفروم", "كفتة"], "dialect": ["kefta", "kafteji"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000004', '44444444-0000-0000-0000-000000000001', 'Entrecôte', 'ريب آي', 'entrecote', '33333333-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["côte", "ribeye"], "ar": ["انتركوت"], "dialect": []}'::jsonb);

-- Viandes - Agneau
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000010', NULL, 'Viande d''agneau', 'لحم غنم', 'viande-agneau', '33333333-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["agneau", "mouton"], "ar": ["غنم", "خروف"], "dialect": ["lahm ghanmi", "3louch"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000011', '44444444-0000-0000-0000-000000000010', 'Gigot d''agneau', 'فخذ غنم', 'gigot-agneau', '33333333-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["gigot", "cuisse"], "ar": ["فخذ"], "dialect": ["fakhdh"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000012', '44444444-0000-0000-0000-000000000010', 'Côtelettes d''agneau', 'ضلوع غنم', 'cotelettes-agneau', '33333333-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["côtelettes", "côtes"], "ar": ["ضلوع"], "dialect": []}'::jsonb);

-- Viandes - Poulet
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000020', NULL, 'Poulet entier', 'دجاجة كاملة', 'poulet-entier', '33333333-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["poulet", "volaille"], "ar": ["دجاج", "فرّوج"], "dialect": ["djej", "ferrouj"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000021', '44444444-0000-0000-0000-000000000020', 'Escalope de poulet', 'صدر دجاج', 'escalope-poulet', '33333333-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["escalope", "blanc", "filet"], "ar": ["صدر"], "dialect": ["sadr djej"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000022', '44444444-0000-0000-0000-000000000020', 'Cuisses de poulet', 'أفخاذ دجاج', 'cuisses-poulet', '33333333-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["cuisses", "hauts de cuisse"], "ar": ["أفخاذ"], "dialect": []}'::jsonb);

-- Produits laitiers
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000030', NULL, 'Lait', 'حليب', 'lait', '33333333-0000-0000-0000-000000000010', '11111111-0000-0000-0000-000000000004',
     '{"fr": ["lait"], "ar": ["حليب"], "dialect": ["hlib"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000031', NULL, 'Yaourt', 'ياغورت', 'yaourt', '33333333-0000-0000-0000-000000000010', '11111111-0000-0000-0000-000000000006',
     '{"fr": ["yaourt", "yogourt"], "ar": ["زبادي", "ياغورت"], "dialect": ["rayeb"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000032', NULL, 'Fromage', 'جبن', 'fromage', '33333333-0000-0000-0000-000000000010', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["fromage"], "ar": ["جبن"], "dialect": ["jben"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000033', NULL, 'Œufs', 'بيض', 'oeufs', '33333333-0000-0000-0000-000000000010', '11111111-0000-0000-0000-000000000010',
     '{"fr": ["oeufs", "œuf"], "ar": ["بيض"], "dialect": ["3dham"]}'::jsonb);

-- Services coiffure
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000040', NULL, 'Coupe homme', 'حلاقة رجالية', 'coupe-homme', '33333333-0000-0000-0000-000000000030', '11111111-0000-0000-0000-000000000011',
     '{"fr": ["coupe", "haircut"], "ar": ["حلاقة"], "dialect": ["7la9a"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000041', NULL, 'Coupe femme', 'حلاقة نسائية', 'coupe-femme', '33333333-0000-0000-0000-000000000030', '11111111-0000-0000-0000-000000000011',
     '{"fr": ["coupe femme", "coiffure"], "ar": ["تسريحة"], "dialect": []}'::jsonb),
    ('44444444-0000-0000-0000-000000000042', NULL, 'Barbe', 'حلاقة ذقن', 'barbe', '33333333-0000-0000-0000-000000000030', '11111111-0000-0000-0000-000000000011',
     '{"fr": ["barbe", "rasage"], "ar": ["ذقن"], "dialect": ["le7ya"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000043', NULL, 'Coloration', 'صبغة شعر', 'coloration', '33333333-0000-0000-0000-000000000030', '11111111-0000-0000-0000-000000000011',
     '{"fr": ["coloration", "teinture", "couleur"], "ar": ["صبغة"], "dialect": ["sabgha"]}'::jsonb);

-- Matériaux construction
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000050', NULL, 'Ciment', 'إسمنت', 'ciment', '33333333-0000-0000-0000-000000000040', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["ciment", "cement"], "ar": ["إسمنت", "اسمنت"], "dialect": ["cima"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000051', NULL, 'Sable', 'رمل', 'sable', '33333333-0000-0000-0000-000000000040', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["sable"], "ar": ["رمل"], "dialect": ["raml"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000052', NULL, 'Fer à béton', 'حديد البناء', 'fer-beton', '33333333-0000-0000-0000-000000000040', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["fer", "armature", "acier"], "ar": ["حديد"], "dialect": ["7did"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000053', NULL, 'Carrelage', 'بلاط', 'carrelage', '33333333-0000-0000-0000-000000000040', '11111111-0000-0000-0000-000000000015',
     '{"fr": ["carrelage", "carreaux", "faience"], "ar": ["بلاط", "سيراميك"], "dialect": ["blat", "karraja"]}'::jsonb);

-- Fruits & Légumes courants
INSERT INTO products (id, parent_id, name_fr, name_ar, slug, category_id, unit_id, aliases) VALUES
    ('44444444-0000-0000-0000-000000000060', NULL, 'Tomates', 'طماطم', 'tomates', '33333333-0000-0000-0000-000000000020', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["tomate"], "ar": ["طماطم"], "dialect": ["tmatem"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000061', NULL, 'Pommes de terre', 'بطاطا', 'pommes-de-terre', '33333333-0000-0000-0000-000000000020', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["patates", "pommes de terre"], "ar": ["بطاطا"], "dialect": ["batata"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000062', NULL, 'Oignons', 'بصل', 'oignons', '33333333-0000-0000-0000-000000000020', '11111111-0000-0000-0000-000000000001',
     '{"fr": ["oignon"], "ar": ["بصل"], "dialect": ["bsal"]}'::jsonb),
    ('44444444-0000-0000-0000-000000000063', NULL, 'Huile d''olive', 'زيت زيتون', 'huile-olive', '33333333-0000-0000-0000-000000000020', '11111111-0000-0000-0000-000000000004',
     '{"fr": ["huile olive", "olive oil"], "ar": ["زيت زيتون"], "dialect": ["zit zitoun"]}'::jsonb);

-- ============================================================================
-- Mise à jour du search_vector pour tous les produits
-- ============================================================================

UPDATE products SET 
    search_vector = 
        setweight(to_tsvector('french', COALESCE(name_fr, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(name_ar, '')), 'A') ||
        setweight(to_tsvector('french', COALESCE(description_fr, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(aliases::text, '')), 'B');
