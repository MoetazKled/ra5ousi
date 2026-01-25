import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../providers/home_provider.dart';

/// Page d'accueil moderne et attractive.
/// 
/// Affiche les statistiques, catégories populaires, tendances de prix,
/// et permet une recherche rapide des produits.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeDataProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header avec recherche
            _buildHeader(context),
            
            // Contenu principal
            SliverToBoxAdapter(
              child: homeData.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
                data: (data) => _buildContent(context, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header avec gradient et barre de recherche
  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                Color(0xFFFF6B6B),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tunisie',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trouvez les meilleurs prix',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'autour de vous',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          transform: Matrix4.translationValues(0, 25, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchBar(context),
        ),
      ),
    );
  }

  /// Barre de recherche flottante
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit ou service...',
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textSecondary),
            onPressed: () {
              // Ouvrir les filtres
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            context.go('/explore');
            ref.read(mapProvider.notifier).searchProducts(query);
          }
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0);
  }

  /// Contenu principal de la page
  Widget _buildContent(BuildContext context, HomeData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        
        // Stats rapides
        _buildQuickStats(context, data),
        
        const SizedBox(height: 28),
        
        // Catégories populaires
        _buildSectionTitle(context, 'Catégories', onSeeAll: () {}),
        const SizedBox(height: 12),
        _buildCategoryGrid(context, data.categories),
        
        const SizedBox(height: 28),
        
        // Derniers prix signalés
        _buildSectionTitle(
          context, 
          'Derniers prix signalés',
          onSeeAll: () => context.go('/explore'),
        ),
        const SizedBox(height: 12),
        _buildRecentPrices(context, data.recentPrices),
        
        const SizedBox(height: 28),
        
        // Commerces à proximité
        _buildSectionTitle(
          context,
          'Commerces populaires',
          onSeeAll: () => context.go('/explore'),
        ),
        const SizedBox(height: 12),
        _buildPopularVendors(context, data.popularVendors),
        
        const SizedBox(height: 28),
        
        // Conseils / Tips
        _buildTipsSection(context),
        
        const SizedBox(height: 100),
      ],
    );
  }

  /// Stats rapides en haut de page
  Widget _buildQuickStats(BuildContext context, HomeData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.store,
              value: '${data.totalVendors}',
              label: 'Commerces',
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.price_change,
              value: '${data.totalPrices}',
              label: 'Prix signalés',
              color: AppTheme.priceGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.people,
              value: '${data.totalContributors}',
              label: 'Contributeurs',
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  /// Titre de section avec bouton "Voir tout"
  Widget _buildSectionTitle(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                children: [
                  Text('Voir tout'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Grille de catégories
  Widget _buildCategoryGrid(BuildContext context, List<Map<String, dynamic>> categories) {
    final displayCategories = categories.take(8).toList();
    
    return SizedBox(
      height: 200,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return _CategoryCard(
            name: category['name_fr'] ?? 'Catégorie',
            icon: _getCategoryIcon(category['slug'] ?? ''),
            color: _getCategoryColor(index),
            onTap: () {
              context.go('/explore');
              ref.read(mapProvider.notifier).setCategory(category['slug']);
            },
          ).animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
        },
      ),
    );
  }

  /// Liste horizontale des derniers prix
  Widget _buildRecentPrices(BuildContext context, List<PriceReport> prices) {
    if (prices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.price_change_outlined,
        message: 'Aucun prix signalé récemment',
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: prices.length,
        itemBuilder: (context, index) {
          final price = prices[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _RecentPriceCard(price: price),
          ).animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  /// Liste horizontale des commerces populaires
  Widget _buildPopularVendors(BuildContext context, List<Vendor> vendors) {
    if (vendors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        message: 'Aucun commerce à proximité',
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PopularVendorCard(
              vendor: vendor,
              onTap: () => context.go('/vendor/${vendor.id}'),
            ),
          ).animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  /// Section conseils
  Widget _buildTipsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagnez des points !',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signalez des prix et aidez la communauté. Chaque contribution compte !',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.go('/contribute'),
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              color: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0);
  }

  /// État vide
  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppTheme.textMuted),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            children: List.generate(3, (index) => 
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(3, (index) => 
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3));
  }

  /// État d'erreur
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Oups ! Une erreur est survenue',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(homeDataProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Retourne l'icône pour une catégorie
  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'boucherie':
        return Icons.restaurant;
      case 'boulangerie':
        return Icons.bakery_dining;
      case 'epicerie':
      case 'supermarche':
        return Icons.shopping_cart;
      case 'primeur':
        return Icons.eco;
      case 'poissonnerie':
        return Icons.set_meal;
      case 'coiffeur':
        return Icons.content_cut;
      case 'pharmacie':
        return Icons.local_pharmacy;
      case 'quincaillerie':
        return Icons.hardware;
      case 'station-service':
        return Icons.local_gas_station;
      default:
        return Icons.store;
    }
  }

  /// Retourne une couleur pour l'index
  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.priceGreen,
      AppTheme.accentColor,
      AppTheme.priceOrange,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    return colors[index % colors.length];
  }
}

/// Carte de statistique
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Carte de catégorie
class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de prix récent
class _RecentPriceCard extends StatelessWidget {
  final PriceReport price;

  const _RecentPriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: priceColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  price.formattedPrice,
                  style: TextStyle(
                    color: priceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              if (price.isVerified)
                Icon(Icons.verified, color: AppTheme.accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price.productName ?? 'Produit',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.store, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  price.vendorName ?? 'Commerce',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price.ageText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de commerce populaire
class _PopularVendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;

  const _PopularVendorCard({
    required this.vendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  Icons.store,
                  size: 36,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendor.isVerified)
                        const Icon(Icons.verified, size: 14, color: AppTheme.accentColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor.categoryName ?? 'Commerce',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.price_change, size: 12, color: AppTheme.priceGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor.priceReportCount} prix',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (vendor.distanceMeters != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.near_me, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          vendor.formattedDistance,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
