# PriceMap Tunisia - Logique de Comparaison des Prix

## Le Défi

Quand un utilisateur recherche "Viande", comment afficher intelligemment les résultats alors que :
- "Viande" peut désigner du bœuf, de l'agneau, du poulet...
- Le filet de bœuf ne doit pas être comparé à la viande hachée
- Les prix varient selon l'unité (kg, pièce, portion)
- Certains produits sont des services (coiffeur), pas des biens physiques

## Solution : Taxonomie Hiérarchique + Comparaison par Groupe

### 1. Structure Hiérarchique des Produits

La table `products` utilise un système **auto-référencé** avec `parent_id` :

```
Viande Rouge (parent_id: null)
│
├── Bœuf (parent_id: viande_rouge)
│   ├── Filet de bœuf (parent_id: boeuf)
│   ├── Entrecôte (parent_id: boeuf)
│   ├── Viande hachée bœuf (parent_id: boeuf)
│   └── Steak haché (parent_id: boeuf)
│
├── Agneau (parent_id: viande_rouge)
│   ├── Gigot (parent_id: agneau)
│   └── Côtelettes (parent_id: agneau)
│
└── Veau (parent_id: viande_rouge)
    └── Escalope de veau (parent_id: veau)
```

### 2. Résolution de la Recherche

Quand l'utilisateur tape "Viande" :

```sql
-- Étape 1: Trouver les produits matchant directement
SELECT id FROM products 
WHERE search_vector @@ to_tsquery('viande')
   OR name_fr ILIKE '%viande%';

-- Étape 2: Inclure les enfants des produits trouvés
WITH RECURSIVE product_tree AS (
    -- Base: produits matchant directement
    SELECT id, parent_id, name_fr, 0 as depth
    FROM products
    WHERE search_vector @@ to_tsquery('viande')
    
    UNION ALL
    
    -- Récursif: enfants
    SELECT p.id, p.parent_id, p.name_fr, pt.depth + 1
    FROM products p
    JOIN product_tree pt ON p.parent_id = pt.id
    WHERE pt.depth < 3  -- Limiter la profondeur
)
SELECT * FROM product_tree;
```

**Résultat :** On obtient tous les types de viande (bœuf, agneau, veau) et leurs variantes.

### 3. Groupement pour la Comparaison

#### Option A : Comparaison au niveau le plus bas (Recommandé)

On compare uniquement les produits **au même niveau de hiérarchie** :

```sql
-- Grouper les prix par produit direct (pas par parent)
SELECT 
    product_id,
    MIN(price) as min_price,
    MAX(price) as max_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) as median_price
FROM price_reports
WHERE product_id IN (SELECT id FROM product_tree)
GROUP BY product_id;
```

**Avantage :** Le filet de bœuf est comparé à d'autres filets de bœuf, pas à la viande hachée.

#### Option B : Comparaison globale avec normalisation

Pour une vue d'ensemble "Où acheter de la viande moins chère" :

```sql
-- Calculer un score Z par catégorie
WITH category_stats AS (
    SELECT 
        p.category_id,
        AVG(pr.price) as avg_price,
        STDDEV(pr.price) as stddev_price
    FROM price_reports pr
    JOIN products p ON p.id = pr.product_id
    GROUP BY p.category_id
)
SELECT 
    pr.*,
    (pr.price - cs.avg_price) / NULLIF(cs.stddev_price, 0) as z_score
FROM price_reports pr
JOIN products p ON p.id = pr.product_id
JOIN category_stats cs ON cs.category_id = p.category_id;
```

### 4. Attribution du Code Couleur (Vert/Orange/Rouge)

Le code couleur est calculé **par groupe de produits comparables** :

```sql
CREATE OR REPLACE FUNCTION calculate_price_color(
    p_product_id UUID,
    p_price DECIMAL,
    p_radius_meters INTEGER,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
)
RETURNS VARCHAR AS $$
DECLARE
    p33 DECIMAL;
    p66 DECIMAL;
BEGIN
    -- Calculer les percentiles pour CE produit dans CE rayon
    SELECT 
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY pr.price),
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY pr.price)
    INTO p33, p66
    FROM price_reports pr
    JOIN vendors v ON v.id = pr.vendor_id
    WHERE pr.product_id = p_product_id
        AND pr.is_active = true
        AND ST_DWithin(v.location, ST_Point(p_lng, p_lat)::geography, p_radius_meters);
    
    -- Attribuer la couleur
    IF p_price <= p33 THEN
        RETURN 'green';  -- Bottom 33% = Moins cher
    ELSIF p_price <= p66 THEN
        RETURN 'orange'; -- Middle 33% = Moyen
    ELSE
        RETURN 'red';    -- Top 33% = Plus cher
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### 5. Gestion des Unités

Les comparaisons ne sont valides qu'entre **mêmes unités** :

```sql
-- MAUVAIS: Comparer kg et unité
SELECT * FROM price_reports WHERE product_id = 'poulet';
-- Retourne: 8.5 DT/kg ET 12 DT/pièce <- Non comparable !

-- BON: Filtrer par unité
SELECT * FROM price_reports 
WHERE product_id = 'poulet' 
  AND unit_id = (SELECT id FROM units WHERE symbol = 'kg');
```

**Stratégie dans l'UI :**
1. Grouper les résultats par unité
2. Calculer le code couleur **séparément** pour chaque groupe d'unité
3. Afficher clairement l'unité : "8.50 DT/kg" vs "12.00 DT/pièce"

### 6. Recherche Floue et Synonymes

Pour améliorer les résultats quand l'utilisateur fait des fautes :

```sql
-- Utiliser pg_trgm pour la recherche floue
SELECT *, similarity(name_fr, 'boeuf') as sim
FROM products
WHERE name_fr % 'boeuf'  -- Trigram similarity
   OR search_vector @@ plainto_tsquery('french', 'boeuf')
ORDER BY sim DESC, name_fr;

-- Les aliases dans JSONB permettent aussi de matcher
-- "steak" -> "Filet de bœuf" via aliases.fr = ["steak", "bifteck"]
```

### 7. Services vs Produits

Les services (coiffeur, pressing) suivent la même logique mais avec des unités différentes :

| Type | Unités courantes | Comparaison |
|------|-----------------|-------------|
| Alimentation (kg) | kg, L, unité | Par kg ou unité |
| Services | séance, prestation, heure | Par prestation |
| Bricolage | m², m, kg | Par unité de mesure |

**Exemple :**
- "Coupe homme" : Comparer les prix à la **séance** entre coiffeurs
- "Ciment" : Comparer les prix au **kg** entre quincailleries

### 8. Algorithme Final Implémenté

```dart
// Dans Flutter/Dart
List<PriceReport> calculatePriceColors(List<PriceReport> prices) {
  // Grouper par product_id
  final grouped = groupBy(prices, (p) => p.productId);
  
  for (final productPrices in grouped.values) {
    // Trier par prix
    productPrices.sort((a, b) => a.price.compareTo(b.price));
    final count = productPrices.length;
    
    // Calculer les seuils
    final p33Index = (count * 0.33).floor();
    final p66Index = (count * 0.66).floor();
    
    // Attribuer les couleurs
    for (int i = 0; i < count; i++) {
      if (i <= p33Index) {
        productPrices[i] = productPrices[i].copyWith(priceColor: 'green');
      } else if (i <= p66Index) {
        productPrices[i] = productPrices[i].copyWith(priceColor: 'orange');
      } else {
        productPrices[i] = productPrices[i].copyWith(priceColor: 'red');
      }
    }
  }
  
  return grouped.values.expand((x) => x).toList();
}
```

## Recommandations

### Pour une Taxonomie Stricte
1. **Créer des catégories de produits claires** avec hiérarchie à 2-3 niveaux max
2. **Imposer la sélection d'un produit existant** plutôt que saisie libre
3. **Normaliser les unités** par catégorie (viande = kg obligatoire)

### Pour une Taxonomie Flexible
1. **Permettre la création de nouveaux produits** par les utilisateurs
2. **Utiliser le machine learning** pour suggérer des regroupements
3. **Modération communautaire** pour fusionner les doublons

### Équilibre Recommandé (PriceMap Tunisia)
- **Niveau 1** : Catégories fixes (Alimentation, Services, Bricolage...)
- **Niveau 2** : Sous-catégories prédéfinies (Boucherie, Coiffeur...)
- **Niveau 3** : Produits populaires prédéfinis + possibilité d'ajouter
- **Unités** : Imposées selon la catégorie parent

Cette approche garantit la comparabilité tout en permettant l'évolution de la base de données.
