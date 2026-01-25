#!/usr/bin/env python3
"""
Script pour importer les commerces de Tunisie depuis OpenStreetMap.
Gratuit et légal - données open source.

Usage:
    pip install requests
    python import_osm_data.py
"""

import requests
import json
from typing import List, Dict

# API Overpass (gratuit) pour extraire les données OSM
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# Types de commerces à extraire
SHOP_TYPES = {
    "butcher": "Boucherie",
    "bakery": "Boulangerie", 
    "supermarket": "Supermarché",
    "convenience": "Épicerie",
    "greengrocer": "Primeur",
    "pharmacy": "Pharmacie",
    "hairdresser": "Coiffeur",
    "hardware": "Quincaillerie",
    "fuel": "Station-service",
    "seafood": "Poissonnerie",
}

def get_shops_in_tunisia(shop_type: str) -> List[Dict]:
    """
    Récupère tous les commerces d'un type en Tunisie.
    
    Args:
        shop_type: Type de commerce OSM (butcher, bakery, etc.)
        
    Returns:
        Liste des commerces avec leurs infos
    """
    
    # Requête Overpass pour la Tunisie
    query = f"""
    [out:json][timeout:60];
    area["ISO3166-1"="TN"]->.tunisie;
    (
      node["shop"="{shop_type}"](area.tunisie);
      way["shop"="{shop_type}"](area.tunisie);
    );
    out center;
    """
    
    try:
        response = requests.post(OVERPASS_URL, data={"data": query})
        response.raise_for_status()
        data = response.json()
        
        shops = []
        for element in data.get("elements", []):
            shop = {
                "osm_id": element.get("id"),
                "type": shop_type,
                "type_fr": SHOP_TYPES.get(shop_type, shop_type),
                "name": element.get("tags", {}).get("name", ""),
                "name_ar": element.get("tags", {}).get("name:ar", ""),
                "latitude": element.get("lat") or element.get("center", {}).get("lat"),
                "longitude": element.get("lon") or element.get("center", {}).get("lon"),
                "address": element.get("tags", {}).get("addr:street", ""),
                "city": element.get("tags", {}).get("addr:city", ""),
                "phone": element.get("tags", {}).get("phone", ""),
                "website": element.get("tags", {}).get("website", ""),
                "opening_hours": element.get("tags", {}).get("opening_hours", ""),
            }
            
            # Ne garder que ceux avec un nom
            if shop["name"] or shop["name_ar"]:
                shops.append(shop)
                
        return shops
        
    except Exception as e:
        print(f"Erreur pour {shop_type}: {e}")
        return []


def get_all_shops() -> List[Dict]:
    """Récupère tous les types de commerces en Tunisie."""
    
    all_shops = []
    
    for shop_type, shop_name_fr in SHOP_TYPES.items():
        print(f"📍 Récupération des {shop_name_fr}s...")
        shops = get_shops_in_tunisia(shop_type)
        print(f"   ✅ {len(shops)} {shop_name_fr}s trouvés")
        all_shops.extend(shops)
    
    return all_shops


def generate_sql_insert(shops: List[Dict]) -> str:
    """Génère le SQL pour insérer les commerces dans Supabase."""
    
    # Mapping des types OSM vers les IDs de catégories dans ta base
    category_mapping = {
        "butcher": "22222222-0000-0000-0000-000000000002",      # Boucherie
        "bakery": "22222222-0000-0000-0000-000000000005",       # Boulangerie
        "supermarket": "22222222-0000-0000-0000-000000000004",  # Supermarché
        "convenience": "22222222-0000-0000-0000-000000000004",  # Épicerie
        "greengrocer": "22222222-0000-0000-0000-000000000006",  # Primeur
        "pharmacy": "22222222-0000-0000-0000-000000000031",     # Pharmacie
        "hairdresser": "22222222-0000-0000-0000-000000000011",  # Coiffeur
        "hardware": "22222222-0000-0000-0000-000000000021",     # Quincaillerie
        "fuel": "22222222-0000-0000-0000-000000000041",         # Station-service
        "seafood": "22222222-0000-0000-0000-000000000003",      # Poissonnerie
    }
    
    sql_lines = [
        "-- Commerces importés depuis OpenStreetMap (gratuit)",
        "-- Généré automatiquement",
        "",
        "INSERT INTO vendors (id, name, name_ar, category_id, location, address, city, phone, website, is_active, is_verified) VALUES"
    ]
    
    values = []
    for i, shop in enumerate(shops):
        if not shop["latitude"] or not shop["longitude"]:
            continue
            
        # Générer un UUID basé sur l'OSM ID
        uuid = f"osm-{shop['osm_id']:012d}-0000-000000000000"
        
        name = shop["name"].replace("'", "''") if shop["name"] else shop["type_fr"]
        name_ar = shop["name_ar"].replace("'", "''") if shop["name_ar"] else ""
        address = shop["address"].replace("'", "''") if shop["address"] else ""
        city = shop["city"].replace("'", "''") if shop["city"] else ""
        phone = shop["phone"].replace("'", "''") if shop["phone"] else ""
        website = shop["website"].replace("'", "''") if shop["website"] else ""
        category_id = category_mapping.get(shop["type"], "22222222-0000-0000-0000-000000000004")
        
        value = f"""    ('{uuid}', '{name}', '{name_ar}', '{category_id}', 
     ST_SetSRID(ST_MakePoint({shop["longitude"]}, {shop["latitude"]}), 4326)::geography,
     '{address}', '{city}', '{phone}', '{website}', true, false)"""
        
        values.append(value)
    
    sql_lines.append(",\n".join(values))
    sql_lines.append("ON CONFLICT (id) DO NOTHING;")
    
    return "\n".join(sql_lines)


def main():
    print("=" * 60)
    print("🗺️  IMPORT DES COMMERCES TUNISIE DEPUIS OPENSTREETMAP")
    print("=" * 60)
    print()
    
    # Récupérer tous les commerces
    shops = get_all_shops()
    
    print()
    print(f"📊 TOTAL : {len(shops)} commerces trouvés en Tunisie !")
    print()
    
    # Sauvegarder en JSON
    with open("tunisie_commerces.json", "w", encoding="utf-8") as f:
        json.dump(shops, f, ensure_ascii=False, indent=2)
    print("✅ Sauvegardé dans tunisie_commerces.json")
    
    # Générer le SQL
    sql = generate_sql_insert(shops)
    with open("tunisie_commerces.sql", "w", encoding="utf-8") as f:
        f.write(sql)
    print("✅ SQL généré dans tunisie_commerces.sql")
    
    print()
    print("📋 Pour importer dans Supabase :")
    print("   1. Va sur https://supabase.com/dashboard")
    print("   2. SQL Editor")
    print("   3. Colle le contenu de tunisie_commerces.sql")
    print("   4. Run !")


if __name__ == "__main__":
    main()
