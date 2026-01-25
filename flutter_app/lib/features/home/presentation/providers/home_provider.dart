import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../map/data/repositories/map_repository.dart';
import '../../../../main.dart';

/// Données pour la page d'accueil.
class HomeData {
  final List<Map<String, dynamic>> categories;
  final List<PriceReport> recentPrices;
  final List<Vendor> popularVendors;
  final int totalVendors;
  final int totalPrices;
  final int totalContributors;

  const HomeData({
    required this.categories,
    required this.recentPrices,
    required this.popularVendors,
    required this.totalVendors,
    required this.totalPrices,
    required this.totalContributors,
  });

  factory HomeData.empty() => const HomeData(
    categories: [],
    recentPrices: [],
    popularVendors: [],
    totalVendors: 0,
    totalPrices: 0,
    totalContributors: 0,
  );
}

/// Provider pour les données de la page d'accueil.
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final locationState = ref.watch(locationServiceProvider);
  
  try {
    // Charger les données en parallèle
    final results = await Future.wait([
      supabaseService.getVendorCategories(),
      _getRecentPrices(),
      _getPopularVendors(ref, locationState.position.latitude, locationState.position.longitude),
      _getStats(),
    ]);

    final categories = results[0] as List<Map<String, dynamic>>;
    final recentPrices = results[1] as List<PriceReport>;
    final popularVendors = results[2] as List<Vendor>;
    final stats = results[3] as Map<String, int>;

    return HomeData(
      categories: categories,
      recentPrices: recentPrices,
      popularVendors: popularVendors,
      totalVendors: stats['vendors'] ?? 0,
      totalPrices: stats['prices'] ?? 0,
      totalContributors: stats['contributors'] ?? 0,
    );
  } catch (e) {
    // En cas d'erreur, retourner des données vides
    print('Erreur HomeData: $e');
    return HomeData.empty();
  }
});

/// Récupère les derniers prix signalés.
Future<List<PriceReport>> _getRecentPrices() async {
  try {
    final response = await supabase
        .from('price_reports')
        .select('''
          *,
          products:product_id (name_fr, name_ar),
          vendors:vendor_id (name, address),
          units:unit_id (symbol)
        ''')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List).map((json) {
      json['product_name'] = json['products']?['name_fr'];
      json['vendor_name'] = json['vendors']?['name'];
      json['unit_symbol'] = json['units']?['symbol'];
      return PriceReport.fromJson(json);
    }).toList();
  } catch (e) {
    print('Erreur getRecentPrices: $e');
    return [];
  }
}

/// Récupère les commerces populaires à proximité.
Future<List<Vendor>> _getPopularVendors(Ref ref, double lat, double lng) async {
  try {
    final mapRepository = ref.read(mapRepositoryProvider);
    return await mapRepository.getVendorsInRadius(
      latitude: lat,
      longitude: lng,
      radiusMeters: 10000, // 10km
    );
  } catch (e) {
    print('Erreur getPopularVendors: $e');
    return [];
  }
}

/// Récupère les statistiques globales.
Future<Map<String, int>> _getStats() async {
  try {
    final vendorCount = await supabase
        .from('vendors')
        .select()
        .eq('is_active', true)
        .count();

    final priceCount = await supabase
        .from('price_reports')
        .select()
        .eq('is_active', true)
        .count();

    final contributorCount = await supabase
        .from('users')
        .select()
        .count();

    return {
      'vendors': vendorCount.count,
      'prices': priceCount.count,
      'contributors': contributorCount.count,
    };
  } catch (e) {
    print('Erreur getStats: $e');
    return {'vendors': 0, 'prices': 0, 'contributors': 0};
  }
}
