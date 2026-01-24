import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/theme_config.dart';
import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../../core/services/location_service.dart';
import '../providers/map_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/radius_slider_widget.dart';
import '../widgets/vendor_card_widget.dart';
import '../widgets/price_result_card_widget.dart';
import '../widgets/category_chips_widget.dart';

/// Page principale de la carte interactive.
/// 
/// Affiche les commerces/prix sur une Google Map avec possibilité
/// de rechercher, filtrer par rayon et catégorie.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  
  // Animation pour le bottom sheet des résultats
  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetAnimation;
  
  // Pour le drag du bottom sheet
  double _sheetHeight = 200;
  final double _minSheetHeight = 100;
  final double _maxSheetHeight = 400;

  @override
  void initState() {
    super.initState();
    
    // Initialiser l'animation du sheet
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Initialiser la carte après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final locationState = ref.watch(locationServiceProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          _buildMap(mapState, locationState),
          
          // Overlay de recherche en haut
          _buildSearchOverlay(mapState),
          
          // Bottom sheet avec résultats
          _buildResultsSheet(mapState),
          
          // Bouton de localisation
          _buildLocationButton(),
          
          // Indicateur de chargement
          if (mapState.isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  /// Construit la carte Google Maps.
  Widget _buildMap(MapState mapState, LocationState locationState) {
    final initialPosition = mapState.cameraPosition ?? locationState.position;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: AppConfig.defaultZoom,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
        // Appliquer le style de carte personnalisé
        _setMapStyle(controller);
      },
      onCameraMove: (position) {
        ref.read(mapProvider.notifier).onCameraMoved(position.target);
      },
      onCameraIdle: () {
        // Optionnel: recharger les données après déplacement
        // ref.read(mapProvider.notifier).reloadForCurrentPosition();
      },
      markers: _buildMarkers(mapState),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 140,
        bottom: _sheetHeight + 20,
      ),
    );
  }

  /// Construit les markers pour la carte.
  Set<Marker> _buildMarkers(MapState mapState) {
    final markers = <Marker>{};

    if (mapState.isSearchMode) {
      // Mode recherche: afficher les prix
      for (final price in mapState.searchResults) {
        if (price.vendorLocation != null) {
          markers.add(_createPriceMarker(price));
        }
      }
    } else {
      // Mode exploration: afficher les commerces
      for (final vendor in mapState.vendors) {
        markers.add(_createVendorMarker(vendor));
      }
    }

    return markers;
  }

  /// Crée un marker pour un commerce.
  Marker _createVendorMarker(Vendor vendor) {
    return Marker(
      markerId: MarkerId(vendor.id),
      position: vendor.location,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        vendor.isVerified 
            ? BitmapDescriptor.hueAzure 
            : BitmapDescriptor.hueRed,
      ),
      infoWindow: InfoWindow(
        title: vendor.name,
        snippet: vendor.categoryName ?? vendor.address,
      ),
      onTap: () {
        ref.read(mapProvider.notifier).selectVendor(vendor);
        _showVendorDetails(vendor);
      },
    );
  }

  /// Crée un marker pour un prix (avec code couleur).
  Marker _createPriceMarker(PriceReport price) {
    // Déterminer la couleur du marker
    double hue;
    switch (price.priceColor?.toLowerCase()) {
      case 'green':
        hue = BitmapDescriptor.hueGreen;
        break;
      case 'orange':
        hue = BitmapDescriptor.hueOrange;
        break;
      case 'red':
        hue = BitmapDescriptor.hueRed;
        break;
      default:
        hue = BitmapDescriptor.hueRose;
    }

    return Marker(
      markerId: MarkerId(price.id),
      position: price.vendorLocation!,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: InfoWindow(
        title: price.vendorName ?? 'Commerce',
        snippet: price.formattedPriceWithUnit,
      ),
      onTap: () {
        _showPriceDetails(price);
      },
    );
  }

  /// Overlay de recherche et filtres.
  Widget _buildSearchOverlay(MapState mapState) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barre de recherche
            SearchBarWidget(
              initialQuery: mapState.searchQuery,
              onSearch: (query) {
                ref.read(mapProvider.notifier).searchProducts(query);
              },
              onClear: () {
                ref.read(mapProvider.notifier).clearSearch();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Chips de catégories (visible uniquement hors recherche)
            if (!mapState.isSearchMode)
              const CategoryChipsWidget(),
            
            const SizedBox(height: 8),
            
            // Slider de rayon
            RadiusSliderWidget(
              currentRadius: mapState.radiusMeters,
              onRadiusChanged: (radius) {
                ref.read(mapProvider.notifier).setRadius(radius);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet avec les résultats.
  Widget _buildResultsSheet(MapState mapState) {
    final itemCount = mapState.isSearchMode 
        ? mapState.searchResults.length 
        : mapState.vendors.length;

    if (itemCount == 0 && !mapState.isLoading) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _sheetHeight -= details.delta.dy;
            _sheetHeight = _sheetHeight.clamp(_minSheetHeight, _maxSheetHeight);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: _sheetHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppTheme.modalShadow,
          ),
          child: Column(
            children: [
              // Handle de drag
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header avec le nombre de résultats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      mapState.isSearchMode
                          ? '$itemCount prix trouvés'
                          : '$itemCount commerces',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (mapState.isSearchMode)
                      TextButton(
                        onPressed: () {
                          ref.read(mapProvider.notifier).clearSearch();
                        },
                        child: const Text('Effacer'),
                      ),
                  ],
                ),
              ),
              
              // Liste des résultats
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (mapState.isSearchMode) {
                      final price = mapState.searchResults[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: PriceResultCardWidget(
                          price: price,
                          onTap: () => _focusOnPrice(price),
                        ),
                      );
                    } else {
                      final vendor = mapState.vendors[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: VendorCardWidget(
                          vendor: vendor,
                          onTap: () => _focusOnVendor(vendor),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton pour centrer sur la position de l'utilisateur.
  Widget _buildLocationButton() {
    return Positioned(
      right: 16,
      bottom: _sheetHeight + 16,
      child: FloatingActionButton.small(
        heroTag: 'location_btn',
        onPressed: _centerOnUser,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  /// Indicateur de chargement.
  Widget _buildLoadingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Text('Chargement...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Applique un style personnalisé à la carte.
  Future<void> _setMapStyle(GoogleMapController controller) async {
    // Style minimaliste inspiré de Uber/Airbnb
    const style = '''[
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "stylers": [{"visibility": "off"}]
      }
    ]''';
    
    await controller.setMapStyle(style);
  }

  /// Centre la carte sur la position de l'utilisateur.
  Future<void> _centerOnUser() async {
    await ref.read(mapProvider.notifier).centerOnUser();
    
    final mapState = ref.read(mapProvider);
    if (mapState.cameraPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(mapState.cameraPosition!, AppConfig.defaultZoom),
      );
    }
  }

  /// Focus sur un commerce et affiche ses détails.
  Future<void> _focusOnVendor(Vendor vendor) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(vendor.location, 16),
    );
    ref.read(mapProvider.notifier).selectVendor(vendor);
    _showVendorDetails(vendor);
  }

  /// Focus sur un prix.
  Future<void> _focusOnPrice(PriceReport price) async {
    if (price.vendorLocation != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(price.vendorLocation!, 16),
      );
      _showPriceDetails(price);
    }
  }

  /// Affiche les détails d'un commerce en bottom sheet.
  void _showVendorDetails(Vendor vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: _VendorDetailSheet(vendor: vendor),
          ),
        ),
      ),
    );
  }

  /// Affiche les détails d'un prix en bottom sheet.
  void _showPriceDetails(PriceReport price) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Nom du produit
            Text(
              price.productName ?? 'Produit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            
            // Commerce
            Row(
              children: [
                const Icon(Icons.store, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    price.vendorName ?? 'Commerce',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Prix avec couleur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getPriceColor(price.priceColor ?? 'orange')
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getPriceColor(price.priceColor ?? 'orange'),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price.formattedPriceWithUnit,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.getPriceColor(price.priceColor ?? 'orange'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getPriceColor(price.priceColor ?? 'orange'),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppTheme.getPriceLabel(price.priceColor ?? 'orange'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Métadonnées
            Row(
              children: [
                if (price.distanceMeters != null) ...[
                  const Icon(Icons.near_me, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    price.formattedDistance,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.schedule, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  price.ageText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (price.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Vérifié',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Bouton Y aller
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Ouvrir l'itinéraire dans Google Maps
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Y aller'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de détails pour un commerce.
class _VendorDetailSheet extends ConsumerWidget {
  final Vendor vendor;

  const _VendorDetailSheet({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(vendorPricesProvider(vendor.id));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header avec photo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: vendor.primaryPhoto != null
                    ? Image.network(
                        vendor.primaryPhoto!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (vendor.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (vendor.categoryName != null)
                      Text(
                        vendor.categoryName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (vendor.distanceMeters != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.formattedDistance,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Adresse
          if (vendor.address != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vendor.address!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Téléphone
          if (vendor.phone != null) ...[
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  vendor.phone!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Section prix
          Text(
            'Prix signalés',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          
          pricesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Text(
              'Erreur: $error',
              style: const TextStyle(color: AppTheme.priceRed),
            ),
            data: (prices) {
              if (prices.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.price_change_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aucun prix signalé',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Ouvrir le formulaire d'ajout de prix
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un prix'),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: prices.map((price) => _PriceListItem(price: price)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppTheme.backgroundLight,
      child: const Icon(
        Icons.store,
        size: 40,
        color: AppTheme.textMuted,
      ),
    );
  }
}

/// Item de liste pour un prix.
class _PriceListItem extends StatelessWidget {
  final PriceReport price;

  const _PriceListItem({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.productName ?? 'Produit',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  price.ageText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            price.formattedPriceWithUnit,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
