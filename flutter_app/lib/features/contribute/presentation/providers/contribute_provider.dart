import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/product.dart';
import '../../../../core/models/vendor.dart';
import '../../../../main.dart';

/// État du formulaire de contribution.
class ContributeState {
  final List<Product> productSuggestions;
  final List<Vendor> vendorSuggestions;
  final bool isSearchingProducts;
  final bool isSearchingVendors;
  final bool isSubmitting;
  final String? error;

  const ContributeState({
    this.productSuggestions = const [],
    this.vendorSuggestions = const [],
    this.isSearchingProducts = false,
    this.isSearchingVendors = false,
    this.isSubmitting = false,
    this.error,
  });

  ContributeState copyWith({
    List<Product>? productSuggestions,
    List<Vendor>? vendorSuggestions,
    bool? isSearchingProducts,
    bool? isSearchingVendors,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ContributeState(
      productSuggestions: productSuggestions ?? this.productSuggestions,
      vendorSuggestions: vendorSuggestions ?? this.vendorSuggestions,
      isSearchingProducts: isSearchingProducts ?? this.isSearchingProducts,
      isSearchingVendors: isSearchingVendors ?? this.isSearchingVendors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider pour la gestion des contributions.
final contributeProvider = StateNotifierProvider<ContributeNotifier, ContributeState>((ref) {
  return ContributeNotifier(supabase);
});

/// Notifier pour les contributions.
class ContributeNotifier extends StateNotifier<ContributeState> {
  final SupabaseClient _client;

  ContributeNotifier(this._client) : super(const ContributeState());

  /// Recherche des produits par nom.
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(productSuggestions: []);
      return;
    }

    state = state.copyWith(isSearchingProducts: true, clearError: true);

    try {
      final response = await _client
          .from('products')
          .select()
          .or('name_fr.ilike.%$query%,name_ar.ilike.%$query%')
          .eq('is_active', true)
          .limit(10);

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();

      state = state.copyWith(
        productSuggestions: products,
        isSearchingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearchingProducts: false,
        error: 'Erreur lors de la recherche de produits',
      );
    }
  }

  /// Recherche des commerces par nom ou proximité.
  Future<void> searchVendors(String query, {double? lat, double? lng}) async {
    if (query.trim().isEmpty && lat == null) {
      state = state.copyWith(vendorSuggestions: []);
      return;
    }

    state = state.copyWith(isSearchingVendors: true, clearError: true);

    try {
      dynamic response;
      
      if (lat != null && lng != null && query.isEmpty) {
        // Recherche par proximité
        response = await _client.rpc(
          'find_vendors_in_radius',
          params: {
            'p_lat': lat,
            'p_lng': lng,
            'p_radius_meters': 1000,
            'p_limit': 10,
          },
        );
      } else {
        // Recherche par nom
        response = await _client
            .from('vendors')
            .select()
            .ilike('name', '%$query%')
            .eq('is_active', true)
            .limit(10);
      }

      // Adapter le parsing selon le type de réponse
      List<Vendor> vendors = [];
      if (response != null) {
        vendors = (response as List).map((json) {
          if (json.containsKey('vendor_id')) {
            // Format RPC
            return Vendor(
              id: json['vendor_id'] as String,
              name: json['name'] as String,
              address: json['address'] as String?,
              location: const LatLng(0, 0), // Sera mis à jour
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return Vendor.fromJson(json);
        }).toList();
      }

      state = state.copyWith(
        vendorSuggestions: vendors,
        isSearchingVendors: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearchingVendors: false,
        error: 'Erreur lors de la recherche de commerces',
      );
    }
  }

  /// Soumet un nouveau signalement de prix.
  Future<bool> submitPriceReport({
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
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Insérer le signalement de prix
      await _client.from('price_reports').insert({
        'product_id': productId,
        'vendor_id': vendorId,
        'user_id': user.id,
        'price': price,
        'unit_id': unitId,
        'quantity': quantity,
        'is_promotion': isPromotion,
        'promo_end_date': promoEndDate?.toIso8601String(),
        'photo_url': photoUrl,
        'notes': notes,
      });

      // Attribuer les points
      final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
      await _client.rpc(
        'award_points',
        params: {
          'p_user_id': user.id,
          'p_action': 'price_report',
          'p_metadata': {'has_photo': hasPhoto},
        },
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Erreur lors de la soumission: $e',
      );
      return false;
    }
  }

  /// Efface les suggestions.
  void clearSuggestions() {
    state = state.copyWith(
      productSuggestions: [],
      vendorSuggestions: [],
    );
  }
}

// Import manquant pour LatLng
import 'package:google_maps_flutter/google_maps_flutter.dart';
