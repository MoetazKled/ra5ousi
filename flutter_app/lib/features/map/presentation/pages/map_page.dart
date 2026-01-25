import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  
  // Pour le drag du bottom sheet
  double _sheetHeight = 220;
  final double _minSheetHeight = 120;
  final double _maxSheetHeight = 450;
  
  // Cache pour les markers personnalisés
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  @override
  void initState() {
    super.initState();
    
    // Initialiser la carte après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).initialize();
      _preloadMarkerIcons();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Précharge les icônes de markers.
  Future<void> _preloadMarkerIcons() async {
    // Précharger les icônes pour chaque couleur de prix
    await Future.wait([
      _createCustomMarker(AppTheme.priceGreen, 'green'),
      _createCustomMarker(AppTheme.priceOrange, 'orange'),
      _createCustomMarker(AppTheme.priceRed, 'red'),
      _createCustomMarker(AppTheme.secondaryColor, 'default'),
      _createCustomMarker(AppTheme.accentColor, 'verified'),
    ]);
  }

  /// Crée un marker personnalisé avec une couleur.
  Future<void> _createCustomMarker(Color color, String key) async {
    const size = 100.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Dessiner le marker
    final paint = Paint()..color = color;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
    
    // Ombre
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), size / 3, shadowPaint);
    
    // Cercle principal
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3, paint);
    
    // Bordure blanche
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3, borderPaint);
    
    // Point central blanc
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 10, centerPaint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (bytes != null) {
      _markerIconCache[key] = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    }
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
          
          // Bouton rafraîchir
          _buildRefreshButton(mapState),
          
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
        _setMapStyle(controller);
      },
      onCameraMove: (position) {
        ref.read(mapProvider.notifier).onCameraMoved(position.target);
      },
      markers: _buildMarkers(mapState),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 160,
        bottom: _sheetHeight + 20,
      ),
    );
  }

  /// Construit les markers pour la carte.
  Set<Marker> _buildMarkers(MapState mapState) {
    final markers = <Marker>{};

    if (mapState.isSearchMode) {
      // Mode recherche: afficher les prix avec couleurs
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
    final iconKey = vendor.isVerified ? 'verified' : 'default';
    final icon = _markerIconCache[iconKey] ?? BitmapDescriptor.defaultMarker;
    
    return Marker(
      markerId: MarkerId(vendor.id),
      position: vendor.location,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: vendor.name,
        snippet: '${vendor.priceReportCount} prix • ${vendor.categoryName ?? "Commerce"}',
      ),
      onTap: () {
        ref.read(mapProvider.notifier).selectVendor(vendor);
        _showVendorDetails(vendor);
      },
    );
  }

  /// Crée un marker pour un prix (avec code couleur).
  Marker _createPriceMarker(PriceReport price) {
    String iconKey;
    switch (price.priceColor?.toLowerCase()) {
      case 'green':
        iconKey = 'green';
        break;
      case 'orange':
        iconKey = 'orange';
        break;
      case 'red':
        iconKey = 'red';
        break;
      default:
        iconKey = 'default';
    }

    final icon = _markerIconCache[iconKey] ?? BitmapDescriptor.defaultMarker;

    return Marker(
      markerId: MarkerId(price.id),
      position: price.vendorLocation!,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: price.vendorName ?? 'Commerce',
        snippet: price.formattedPriceWithUnit,
      ),
      onTap: () => _showPriceDetails(price),
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
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 12),
            
            // Chips de catégories (visible uniquement hors recherche)
            if (!mapState.isSearchMode)
              const CategoryChipsWidget()
                  .animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0),
            
            const SizedBox(height: 8),
            
            // Slider de rayon
            RadiusSliderWidget(
              currentRadius: mapState.radiusMeters,
              onRadiusChanged: (radius) {
                ref.read(mapProvider.notifier).setRadius(radius);
              },
            ).animate().fadeIn(delay: 200.ms),
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
          duration: const Duration(milliseconds: 150),
          height: _sheetHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: mapState.isSearchMode 
                            ? AppTheme.priceGreen.withOpacity(0.1)
                            : AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mapState.isSearchMode ? Icons.local_offer : Icons.store,
                            size: 16,
                            color: mapState.isSearchMode 
                                ? AppTheme.priceGreen 
                                : AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$itemCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: mapState.isSearchMode 
                                  ? AppTheme.priceGreen 
                                  : AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      mapState.isSearchMode
                          ? 'prix trouvés'
                          : 'commerces',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (mapState.isSearchMode)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(mapProvider.notifier).clearSearch();
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Effacer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Liste des résultats
              Expanded(
                child: itemCount == 0
                    ? _buildEmptyResults(mapState)
                    : ListView.builder(
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
                            ).animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn()
                              .slideX(begin: 0.2, end: 0);
                          } else {
                            final vendor = mapState.vendors[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: VendorCardWidget(
                                vendor: vendor,
                                onTap: () => _focusOnVendor(vendor),
                              ),
                            ).animate(delay: Duration(milliseconds: 50 * index))
                              .fadeIn()
                              .slideX(begin: 0.2, end: 0);
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

  /// État vide des résultats.
  Widget _buildEmptyResults(MapState mapState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mapState.isSearchMode ? Icons.search_off : Icons.store_mall_directory_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            mapState.isSearchMode 
                ? 'Aucun prix trouvé'
                : 'Aucun commerce à proximité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mapState.isSearchMode 
                ? 'Essayez d\'élargir le rayon'
                : 'Déplacez la carte ou élargissez le rayon',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Bouton pour centrer sur la position de l'utilisateur.
  Widget _buildLocationButton() {
    return Positioned(
      right: 16,
      bottom: _sheetHeight + 70,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.small(
          heroTag: 'location_btn',
          onPressed: _centerOnUser,
          backgroundColor: Colors.white,
          elevation: 0,
          child: const Icon(
            Icons.my_location,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  /// Bouton pour rafraîchir les résultats.
  Widget _buildRefreshButton(MapState mapState) {
    return Positioned(
      right: 16,
      bottom: _sheetHeight + 130,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.small(
          heroTag: 'refresh_btn',
          onPressed: () {
            ref.read(mapProvider.notifier).reloadForCurrentPosition();
          },
          backgroundColor: Colors.white,
          elevation: 0,
          child: Icon(
            Icons.refresh,
            color: mapState.isLoading ? AppTheme.textMuted : AppTheme.secondaryColor,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }

  /// Indicateur de chargement.
  Widget _buildLoadingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 180,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recherche en cours...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: -0.3, end: 0),
    );
  }

  /// Applique un style personnalisé à la carte.
  Future<void> _setMapStyle(GoogleMapController controller) async {
    const style = '''[
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.icon",
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
        initialChildSize: 0.6,
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
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');
    
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
            const SizedBox(height: 24),
            
            // Header avec prix
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prix avec badge couleur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: priceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: priceColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        price.formattedPrice,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: priceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        price.unitSymbol ?? 'unité',
                        style: TextStyle(
                          color: priceColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.productName ?? 'Produit',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              price.vendorName ?? 'Commerce',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Badge niveau de prix
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: priceColor,
                          borderRadius: BorderRadius.circular(12),
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
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Métadonnées
            Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: price.ageText,
                ),
                if (price.distanceMeters != null) ...[
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.near_me,
                    label: price.formattedDistance,
                  ),
                ],
                if (price.isVerified) ...[
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.verified,
                    label: 'Vérifié',
                    color: AppTheme.accentColor,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Votes
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppTheme.priceGreen),
                const SizedBox(width: 4),
                Text('${price.upvotes}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                const Icon(Icons.thumb_down_alt_outlined, size: 16, color: AppTheme.priceRed),
                const SizedBox(width: 4),
                Text('${price.downvotes}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  'Confiance: ${(price.confidenceScore * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Confirmer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Ouvrir l'itinéraire
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Y aller'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip d'information.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.textMuted).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          const SizedBox(height: 24),
          
          // Header avec info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar/icône
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(vendor.categoryId),
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (vendor.isVerified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: AppTheme.accentColor,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.categoryName ?? 'Commerce',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.price_change,
                          label: '${vendor.priceReportCount} prix',
                          color: AppTheme.priceGreen,
                        ),
                        if (vendor.distanceMeters != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.near_me,
                            label: vendor.formattedDistance,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Adresse et contact
          if (vendor.address != null)
            _ContactRow(
              icon: Icons.location_on,
              text: vendor.address!,
            ),
          if (vendor.phone != null)
            _ContactRow(
              icon: Icons.phone,
              text: vendor.phone!,
            ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Section produits/prix
          Row(
            children: [
              Text(
                'Articles disponibles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Ajouter un prix
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          pricesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.priceRed)),
            ),
            data: (prices) {
              if (prices.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun article signalé',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Soyez le premier à ajouter un prix !',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                );
              }
              
              // Grouper les prix par catégorie/produit
              return Column(
                children: prices.map((price) => _PriceListItem(price: price)).toList(),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Appeler
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Ouvrir itinéraire
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Y aller'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryId) {
    // Mapper les IDs de catégorie aux icônes
    return Icons.store;
  }
}

/// Ligne de contact.
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de liste pour un prix dans les détails du vendor.
class _PriceListItem extends StatelessWidget {
  final PriceReport price;

  const _PriceListItem({required this.price});

  @override
  Widget build(BuildContext context) {
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicateur couleur prix
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priceColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.productName ?? 'Produit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price.ageText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (price.isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 14, color: AppTheme.accentColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price.formattedPrice,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: priceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price.unitSymbol ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
