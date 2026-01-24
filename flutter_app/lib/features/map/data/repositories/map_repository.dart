import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../../main.dart';

/// Provider pour le repository de la carte.
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(supabase);
});

/// Repository pour les opérations liées à la carte.
/// 
/// Gère les requêtes géospatiales vers Supabase pour récupérer
/// les commerces et prix dans un rayon donné.
class MapRepository {
  final SupabaseClient _client;

  MapRepository(this._client);

  /// Récupère les commerces dans un rayon autour d'une position.
  /// 
  /// Utilise la fonction PostGIS `find_vendors_in_radius` pour
  /// des performances optimales.
  Future<List<Vendor>> getVendorsInRadius({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? categorySlug,
    int limit = 50,
  }) async {
    try {
      final response = await _client.rpc(
        'find_vendors_in_radius',
        params: {
          'p_lat': latitude,
          'p_lng': longitude,
          'p_radius_meters': radiusMeters,
          'p_category_slug': categorySlug,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      return (response as List).map((json) {
        // Adapter le format de la fonction RPC au modèle Vendor
        return Vendor(
          id: json['vendor_id'] as String,
          name: json['name'] as String,
          nameAr: json['name_ar'] as String?,
          categoryName: json['category_name'] as String?,
          location: LatLng(
            (json['latitude'] as num).toDouble(),
            (json['longitude'] as num).toDouble(),
          ),
          address: json['address'] as String?,
          phone: json['phone'] as String?,
          isVerified: json['is_verified'] as bool? ?? false,
          ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
          photoUrls: json['photo_url'] != null ? [json['photo_url'] as String] : [],
          distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw MapRepositoryException('Erreur lors de la récupération des commerces: $e');
    }
  }

  /// Recherche des produits avec leurs prix dans un rayon.
  /// 
  /// Utilise la fonction PostGIS `search_products_with_local_prices`
  /// qui calcule aussi le code couleur (vert/orange/rouge).
  Future<List<PriceReport>> searchProductsWithPrices({
    required String query,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    int limit = 30,
  }) async {
    try {
      final response = await _client.rpc(
        'search_products_with_local_prices',
        params: {
          'p_search_query': query,
          'p_lat': latitude,
          'p_lng': longitude,
          'p_radius_meters': radiusMeters,
          'p_limit': limit,
        },
      );

      if (response == null) return [];

      return (response as List).map((json) {
        return PriceReport(
          id: '${json['product_id']}_${json['vendor_id']}', // ID composite
          productId: json['product_id'] as String,
          productName: json['product_name_fr'] as String?,
          vendorId: json['vendor_id'] as String,
          vendorName: json['vendor_name'] as String?,
          vendorAddress: json['vendor_address'] as String?,
          vendorLocation: LatLng(
            (json['latitude'] as num).toDouble(),
            (json['longitude'] as num).toDouble(),
          ),
          userId: '', // Non fourni par cette requête
          price: (json['price'] as num).toDouble(),
          unitSymbol: json['unit_symbol'] as String?,
          confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
          isVerified: json['is_verified'] as bool? ?? false,
          distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
          priceColor: json['price_color'] as String?,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          createdAt: json['reported_at'] != null 
              ? DateTime.parse(json['reported_at'] as String)
              : DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw MapRepositoryException('Erreur lors de la recherche de prix: $e');
    }
  }

  /// Récupère tous les prix pour un commerce donné.
  Future<List<PriceReport>> getPricesForVendor(String vendorId) async {
    try {
      final response = await _client
          .from('price_reports')
          .select('''
            *,
            products:product_id (name_fr, name_ar),
            units:unit_id (symbol)
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        return PriceReport(
          id: json['id'] as String,
          productId: json['product_id'] as String,
          productName: json['products']?['name_fr'] as String?,
          vendorId: json['vendor_id'] as String,
          userId: json['user_id'] as String,
          price: (json['price'] as num).toDouble(),
          unitId: json['unit_id'] as String?,
          unitSymbol: json['units']?['symbol'] as String?,
          quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
          currency: json['currency'] as String? ?? 'TND',
          isPromotion: json['is_promotion'] as bool? ?? false,
          photoUrl: json['photo_url'] as String?,
          notes: json['notes'] as String?,
          confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
          upvotes: json['upvotes'] as int? ?? 0,
          downvotes: json['downvotes'] as int? ?? 0,
          isVerified: json['is_verified'] as bool? ?? false,
          isActive: json['is_active'] as bool? ?? true,
          expiresAt: DateTime.parse(json['expires_at'] as String),
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw MapRepositoryException('Erreur lors de la récupération des prix: $e');
    }
  }

  /// Récupère les détails d'un commerce.
  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      final response = await _client
          .from('vendors')
          .select('''
            *,
            categories:category_id (name_fr, slug)
          ''')
          .eq('id', vendorId)
          .single();

      // Extraire lat/lng depuis le format PostGIS
      double lat = 36.8065; // Par défaut Tunis
      double lng = 10.1815;
      
      if (response['location'] != null) {
        // Le format peut varier selon la config Supabase
        // Format possible: {type: "Point", coordinates: [lng, lat]}
        final loc = response['location'];
        if (loc is Map && loc['coordinates'] != null) {
          final coords = loc['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }

      return Vendor(
        id: response['id'] as String,
        googlePlaceId: response['google_place_id'] as String?,
        name: response['name'] as String,
        nameAr: response['name_ar'] as String?,
        description: response['description'] as String?,
        categoryId: response['category_id'] as String?,
        categoryName: response['categories']?['name_fr'] as String?,
        location: LatLng(lat, lng),
        address: response['address'] as String?,
        city: response['city'] as String?,
        governorate: response['governorate'] as String?,
        phone: response['phone'] as String?,
        website: response['website'] as String?,
        photoUrls: (response['photo_urls'] as List?)?.cast<String>() ?? [],
        openingHours: response['opening_hours'] as Map<String, dynamic>?,
        ownerId: response['owner_id'] as String?,
        isVerified: response['is_verified'] as bool? ?? false,
        isActive: response['is_active'] as bool? ?? true,
        ratingAvg: (response['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: response['rating_count'] as int? ?? 0,
        priceReportCount: response['price_report_count'] as int? ?? 0,
        lastPriceUpdate: response['last_price_update'] != null
            ? DateTime.parse(response['last_price_update'] as String)
            : null,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      throw MapRepositoryException('Erreur lors de la récupération du commerce: $e');
    }
  }

  /// Récupère les catégories de commerces.
  Future<List<Map<String, dynamic>>> getVendorCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('type', 'vendor')
          .eq('is_active', true)
          .order('sort_order');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw MapRepositoryException('Erreur lors de la récupération des catégories: $e');
    }
  }
}

/// Exception personnalisée pour les erreurs du repository.
class MapRepositoryException implements Exception {
  final String message;
  MapRepositoryException(this.message);

  @override
  String toString() => message;
}
