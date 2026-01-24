import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../../core/services/location_service.dart';
import '../../data/repositories/map_repository.dart';

/// État de la carte.
class MapState {
  final List<Vendor> vendors;
  final List<PriceReport> searchResults;
  final String? searchQuery;
  final int radiusMeters;
  final String? selectedCategorySlug;
  final Vendor? selectedVendor;
  final bool isLoading;
  final String? error;
  final LatLng? cameraPosition;

  const MapState({
    this.vendors = const [],
    this.searchResults = const [],
    this.searchQuery,
    this.radiusMeters = AppConfig.defaultSearchRadiusMeters,
    this.selectedCategorySlug,
    this.selectedVendor,
    this.isLoading = false,
    this.error,
    this.cameraPosition,
  });

  MapState copyWith({
    List<Vendor>? vendors,
    List<PriceReport>? searchResults,
    String? searchQuery,
    int? radiusMeters,
    String? selectedCategorySlug,
    Vendor? selectedVendor,
    bool? isLoading,
    String? error,
    LatLng? cameraPosition,
    bool clearSelectedVendor = false,
    bool clearSearchQuery = false,
    bool clearError = false,
  }) {
    return MapState(
      vendors: vendors ?? this.vendors,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      radiusMeters: radiusMeters ?? this.radiusMeters,
      selectedCategorySlug: selectedCategorySlug ?? this.selectedCategorySlug,
      selectedVendor: clearSelectedVendor ? null : (selectedVendor ?? this.selectedVendor),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      cameraPosition: cameraPosition ?? this.cameraPosition,
    );
  }

  /// Indique si on est en mode recherche de produits.
  bool get isSearchMode => searchQuery != null && searchQuery!.isNotEmpty;

  /// Retourne les résultats à afficher sur la carte.
  /// En mode recherche, retourne les prix trouvés.
  /// Sinon, retourne les commerces.
  List<dynamic> get displayItems => isSearchMode ? searchResults : vendors;
}

/// Provider principal pour la gestion de la carte.
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final mapRepository = ref.watch(mapRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider.notifier);
  return MapNotifier(mapRepository, locationService, ref);
});

/// Notifier pour la gestion de l'état de la carte.
class MapNotifier extends StateNotifier<MapState> {
  final MapRepository _repository;
  final LocationService _locationService;
  final Ref _ref;

  MapNotifier(this._repository, this._locationService, this._ref) 
      : super(const MapState());

  /// Position actuelle ou par défaut.
  LatLng get currentPosition {
    final locationState = _ref.read(locationServiceProvider);
    return locationState.position;
  }

  /// Initialise la carte en chargeant les commerces autour de l'utilisateur.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Récupérer la position actuelle
      await _locationService.getCurrentPosition();
      final position = currentPosition;

      state = state.copyWith(cameraPosition: position);

      // Charger les commerces
      await loadVendorsInRadius();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible d\'initialiser la carte: $e',
      );
    }
  }

  /// Charge les commerces dans le rayon actuel.
  Future<void> loadVendorsInRadius() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final position = state.cameraPosition ?? currentPosition;
      
      final vendors = await _repository.getVendorsInRadius(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: state.radiusMeters,
        categorySlug: state.selectedCategorySlug,
      );

      state = state.copyWith(
        vendors: vendors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des commerces: $e',
      );
    }
  }

  /// Recherche des produits avec leurs prix.
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        clearSearchQuery: true,
        searchResults: [],
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      clearError: true,
    );

    try {
      final position = state.cameraPosition ?? currentPosition;

      final results = await _repository.searchProductsWithPrices(
        query: query,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: state.radiusMeters,
      );

      state = state.copyWith(
        searchResults: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche: $e',
      );
    }
  }

  /// Efface la recherche et revient à l'affichage des commerces.
  void clearSearch() {
    state = state.copyWith(
      clearSearchQuery: true,
      searchResults: [],
    );
  }

  /// Met à jour le rayon de recherche.
  Future<void> setRadius(int radiusMeters) async {
    state = state.copyWith(radiusMeters: radiusMeters);
    
    // Recharger les données avec le nouveau rayon
    if (state.isSearchMode) {
      await searchProducts(state.searchQuery!);
    } else {
      await loadVendorsInRadius();
    }
  }

  /// Met à jour la catégorie sélectionnée.
  Future<void> setCategory(String? categorySlug) async {
    state = state.copyWith(selectedCategorySlug: categorySlug);
    await loadVendorsInRadius();
  }

  /// Met à jour la position de la caméra (après déplacement).
  Future<void> onCameraMoved(LatLng newPosition) async {
    state = state.copyWith(cameraPosition: newPosition);
  }

  /// Recharge les données pour la position actuelle de la caméra.
  Future<void> reloadForCurrentPosition() async {
    if (state.isSearchMode) {
      await searchProducts(state.searchQuery!);
    } else {
      await loadVendorsInRadius();
    }
  }

  /// Sélectionne un commerce pour afficher ses détails.
  void selectVendor(Vendor vendor) {
    state = state.copyWith(selectedVendor: vendor);
  }

  /// Désélectionne le commerce.
  void clearSelectedVendor() {
    state = state.copyWith(clearSelectedVendor: true);
  }

  /// Centre la carte sur la position de l'utilisateur.
  Future<void> centerOnUser() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      state = state.copyWith(cameraPosition: position);
    }
  }
}

/// Provider pour les catégories de commerces.
final vendorCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.getVendorCategories();
});

/// Provider pour les détails d'un commerce.
final vendorDetailsProvider = FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.getVendorById(vendorId);
});

/// Provider pour les prix d'un commerce.
final vendorPricesProvider = FutureProvider.family<List<PriceReport>, String>((ref, vendorId) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.getPricesForVendor(vendorId);
});
