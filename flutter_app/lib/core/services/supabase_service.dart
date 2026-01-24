import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../models/vendor.dart';
import '../models/product.dart';
import '../models/price_report.dart';

/// Provider pour le service Supabase.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(supabase);
});

/// Service centralisé pour les opérations Supabase.
/// 
/// Gère toutes les interactions avec la base de données PostgreSQL
/// via l'API Supabase.
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // ============================================================================
  // AUTHENTIFICATION
  // ============================================================================

  /// Utilisateur actuellement connecté.
  User? get currentUser => _client.auth.currentUser;

  /// Stream des changements d'état d'authentification.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Connexion avec email et mot de passe.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Inscription avec email et mot de passe.
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? displayName}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
      },
    );

    // Créer l'entrée dans la table users
    if (response.user != null) {
      await _client.from('users').upsert({
        'id': response.user!.id,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'role': 'user',
        'points': 0,
        'level': 1,
      });
    }

    return response;
  }

  /// Connexion avec Google OAuth.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.pricemaptunisia://login-callback/',
    );
  }

  /// Déconnexion.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Réinitialisation du mot de passe.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ============================================================================
  // UTILISATEURS
  // ============================================================================

  /// Récupère le profil de l'utilisateur connecté.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  /// Met à jour le profil utilisateur.
  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? phone,
    String? preferredLanguage,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (phone != null) updates['phone'] = phone;
    if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;

    if (updates.isNotEmpty) {
      await _client.from('users').update(updates).eq('id', user.id);
    }
  }

  /// Récupère les statistiques de l'utilisateur.
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final response = await _client
        .from('users')
        .select('points, level')
        .eq('id', userId)
        .single();

    // Compter les contributions
    final priceCount = await _client
        .from('price_reports')
        .select('id')
        .eq('user_id', userId)
        .count();

    final voteCount = await _client
        .from('price_votes')
        .select('id')
        .eq('user_id', userId)
        .count();

    return {
      ...response,
      'price_reports_count': priceCount.count,
      'votes_count': voteCount.count,
    };
  }

  // ============================================================================
  // CATÉGORIES
  // ============================================================================

  /// Récupère toutes les catégories de commerces.
  Future<List<Map<String, dynamic>>> getVendorCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('type', 'vendor')
        .eq('is_active', true)
        .order('sort_order');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Récupère toutes les catégories de produits.
  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('type', 'product')
        .eq('is_active', true)
        .order('sort_order');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // UNITÉS
  // ============================================================================

  /// Récupère toutes les unités de mesure.
  Future<List<Map<String, dynamic>>> getUnits() async {
    final response = await _client
        .from('units')
        .select()
        .order('type');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Récupère les unités par type.
  Future<List<Map<String, dynamic>>> getUnitsByType(String type) async {
    final response = await _client
        .from('units')
        .select()
        .eq('type', type);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // PRODUITS
  // ============================================================================

  /// Recherche des produits par nom.
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    final response = await _client
        .from('products')
        .select('''
          *,
          categories:category_id (name_fr, slug),
          units:unit_id (symbol, name_fr)
        ''')
        .or('name_fr.ilike.%$query%,name_ar.ilike.%$query%')
        .eq('is_active', true)
        .limit(limit);

    return (response as List).map((json) {
      json['category_name'] = json['categories']?['name_fr'];
      json['unit_symbol'] = json['units']?['symbol'];
      return Product.fromJson(json);
    }).toList();
  }

  /// Récupère les produits populaires (les plus signalés).
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    final response = await _client
        .from('products')
        .select('''
          *,
          categories:category_id (name_fr),
          units:unit_id (symbol)
        ''')
        .eq('is_active', true)
        .limit(limit);

    return (response as List).map((json) {
      json['category_name'] = json['categories']?['name_fr'];
      json['unit_symbol'] = json['units']?['symbol'];
      return Product.fromJson(json);
    }).toList();
  }

  /// Récupère un produit par son ID.
  Future<Product?> getProductById(String productId) async {
    final response = await _client
        .from('products')
        .select('''
          *,
          categories:category_id (name_fr),
          units:unit_id (symbol)
        ''')
        .eq('id', productId)
        .maybeSingle();

    if (response == null) return null;

    response['category_name'] = response['categories']?['name_fr'];
    response['unit_symbol'] = response['units']?['symbol'];
    return Product.fromJson(response);
  }

  // ============================================================================
  // COMMERCES (VENDORS)
  // ============================================================================

  /// Recherche des commerces par nom.
  Future<List<Vendor>> searchVendors(String query, {int limit = 20}) async {
    final response = await _client
        .from('vendors')
        .select('''
          *,
          categories:category_id (name_fr, slug)
        ''')
        .or('name.ilike.%$query%,name_ar.ilike.%$query%')
        .eq('is_active', true)
        .limit(limit);

    return (response as List).map((json) {
      json['category_name'] = json['categories']?['name_fr'];
      return Vendor.fromJson(json);
    }).toList();
  }

  /// Récupère un commerce par son ID.
  Future<Vendor?> getVendorById(String vendorId) async {
    final response = await _client
        .from('vendors')
        .select('''
          *,
          categories:category_id (name_fr, slug)
        ''')
        .eq('id', vendorId)
        .maybeSingle();

    if (response == null) return null;

    response['category_name'] = response['categories']?['name_fr'];
    return Vendor.fromJson(response);
  }

  /// Ajoute un nouveau commerce.
  Future<Vendor> addVendor({
    required String name,
    String? nameAr,
    String? description,
    required String categoryId,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? governorate,
    String? phone,
    String? website,
    String? googlePlaceId,
  }) async {
    final response = await _client.from('vendors').insert({
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'category_id': categoryId,
      'location': 'POINT($longitude $latitude)',
      'address': address,
      'city': city,
      'governorate': governorate,
      'phone': phone,
      'website': website,
      'google_place_id': googlePlaceId,
      'is_active': true,
      'is_verified': false,
    }).select().single();

    // Attribuer les points à l'utilisateur
    final user = currentUser;
    if (user != null) {
      await _client.rpc('award_points', params: {
        'p_user_id': user.id,
        'p_action': 'vendor_add',
        'p_reference_id': response['id'],
      });
    }

    return Vendor.fromJson(response);
  }

  // ============================================================================
  // PRIX
  // ============================================================================

  /// Récupère les prix pour un commerce.
  Future<List<PriceReport>> getPricesForVendor(String vendorId) async {
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
      json['product_name'] = json['products']?['name_fr'];
      json['unit_symbol'] = json['units']?['symbol'];
      return PriceReport.fromJson(json);
    }).toList();
  }

  /// Récupère les prix pour un produit.
  Future<List<PriceReport>> getPricesForProduct(String productId) async {
    final response = await _client
        .from('price_reports')
        .select('''
          *,
          vendors:vendor_id (name, address),
          units:unit_id (symbol)
        ''')
        .eq('product_id', productId)
        .eq('is_active', true)
        .order('price');

    return (response as List).map((json) {
      json['vendor_name'] = json['vendors']?['name'];
      json['vendor_address'] = json['vendors']?['address'];
      json['unit_symbol'] = json['units']?['symbol'];
      return PriceReport.fromJson(json);
    }).toList();
  }

  /// Ajoute un nouveau signalement de prix.
  Future<PriceReport> addPriceReport({
    required String productId,
    required String vendorId,
    required double price,
    String? unitId,
    double quantity = 1,
    bool isPromotion = false,
    DateTime? promoEndDate,
    String? photoUrl,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _client.from('price_reports').insert({
      'product_id': productId,
      'vendor_id': vendorId,
      'user_id': user.id,
      'price': price,
      'unit_id': unitId,
      'quantity': quantity,
      'currency': 'TND',
      'is_promotion': isPromotion,
      'promo_end_date': promoEndDate?.toIso8601String(),
      'photo_url': photoUrl,
      'notes': notes,
      'confidence_score': 0.5,
      'is_active': true,
    }).select().single();

    // Attribuer les points
    await _client.rpc('award_points', params: {
      'p_user_id': user.id,
      'p_action': 'price_report',
      'p_reference_id': response['id'],
      'p_metadata': {'has_photo': photoUrl != null},
    });

    return PriceReport.fromJson(response);
  }

  /// Vote sur un prix (confirmer ou infirmer).
  Future<void> voteOnPrice(String priceReportId, bool isValid) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await _client.from('price_votes').upsert({
      'price_report_id': priceReportId,
      'user_id': user.id,
      'is_valid': isValid,
    }, onConflict: 'price_report_id,user_id');

    // Attribuer les points pour le vote
    await _client.rpc('award_points', params: {
      'p_user_id': user.id,
      'p_action': 'price_vote',
      'p_reference_id': priceReportId,
    });
  }

  // ============================================================================
  // FAVORIS
  // ============================================================================

  /// Ajoute un commerce aux favoris.
  Future<void> addFavoriteVendor(String vendorId) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await _client.from('favorites').insert({
      'user_id': user.id,
      'vendor_id': vendorId,
    });
  }

  /// Retire un commerce des favoris.
  Future<void> removeFavoriteVendor(String vendorId) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('vendor_id', vendorId);
  }

  /// Récupère les commerces favoris.
  Future<List<String>> getFavoriteVendorIds() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _client
        .from('favorites')
        .select('vendor_id')
        .eq('user_id', user.id)
        .not('vendor_id', 'is', null);

    return (response as List)
        .map((row) => row['vendor_id'] as String)
        .toList();
  }

  // ============================================================================
  // HISTORIQUE DE RECHERCHE
  // ============================================================================

  /// Enregistre une recherche.
  Future<void> saveSearchHistory(String query, int resultCount, {double? lat, double? lng}) async {
    final user = currentUser;

    await _client.from('search_history').insert({
      'user_id': user?.id,
      'query': query,
      'result_count': resultCount,
      'location': lat != null && lng != null ? 'POINT($lng $lat)' : null,
    });
  }

  /// Récupère l'historique de recherche de l'utilisateur.
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _client
        .from('search_history')
        .select('query')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => row['query'] as String)
        .toSet() // Éliminer les doublons
        .toList();
  }

  // ============================================================================
  // STORAGE (PHOTOS)
  // ============================================================================

  /// Upload une photo de prix.
  Future<String> uploadPricePhoto(Uint8List bytes, String fileName) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final path = 'price_photos/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('price-photos').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    return _client.storage.from('price-photos').getPublicUrl(path);
  }

  /// Upload un avatar utilisateur.
  Future<String> uploadAvatar(Uint8List bytes, String fileName) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final path = 'avatars/${user.id}/$fileName';

    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    final url = _client.storage.from('avatars').getPublicUrl(path);
    
    // Mettre à jour le profil
    await updateUserProfile(avatarUrl: url);

    return url;
  }
}
