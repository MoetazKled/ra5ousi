import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../map/presentation/providers/map_provider.dart';

/// Page de détail d'un commerce.
/// 
/// Affiche toutes les informations d'un commerce ainsi que
/// tous les produits/prix signalés pour ce commerce,
/// groupés par catégorie.
class VendorDetailPage extends ConsumerWidget {
  final String vendorId;

  const VendorDetailPage({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailsProvider(vendorId));
    final pricesAsync = ref.watch(vendorPricesProvider(vendorId));

    return Scaffold(
      body: vendorAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(error: error.toString()),
        data: (vendor) {
          if (vendor == null) {
            return const _ErrorState(error: 'Commerce non trouvé');
          }
          return _VendorDetailContent(
            vendor: vendor,
            pricesAsync: pricesAsync,
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorDetailContent extends StatelessWidget {
  final Vendor vendor;
  final AsyncValue<List<PriceReport>> pricesAsync;

  const _VendorDetailContent({
    required this.vendor,
    required this.pricesAsync,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar avec gradient
        _buildSliverAppBar(context),
        
        // Contenu principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                _buildHeader(context),
                
                const SizedBox(height: 20),
                
                // Stats rapides
                _buildQuickStats(context),
                
                const SizedBox(height: 24),
                
                // Informations de contact
                _buildContactSection(context),
                
                const SizedBox(height: 24),
                
                // Actions rapides
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
        
        // Titre section produits
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.priceGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppTheme.priceGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles disponibles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Prix signalés par la communauté',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Ajouter un prix
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ),
        
        // Liste des produits/prix
        _buildPricesList(context),
        
        // Espace en bas
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getCategoryColor(vendor.categoryId),
                _getCategoryColor(vendor.categoryId).withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern décoratif
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Icône centrale
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _getCategoryIcon(vendor.categoryId),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              onPressed: () {
                // TODO: Partager
              },
              icon: const Icon(Icons.share),
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              onPressed: () {
                // TODO: Favoris
              },
              icon: const Icon(Icons.favorite_border),
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vendor.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (vendor.isVerified)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: AppTheme.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Vérifié',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(vendor.categoryId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vendor.categoryName ?? 'Commerce',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getCategoryColor(vendor.categoryId),
                      ),
                    ),
                  ),
                  if (vendor.city != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      vendor.city!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_offer,
            value: '${vendor.priceReportCount}',
            label: 'Prix signalés',
            color: AppTheme.priceGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            value: vendor.ratingAvg > 0 
                ? vendor.ratingAvg.toStringAsFixed(1) 
                : '-',
            label: vendor.ratingCount > 0 
                ? '${vendor.ratingCount} avis' 
                : 'Pas d\'avis',
            color: Colors.amber,
          ),
        ),
        if (vendor.distanceMeters != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.near_me,
              value: vendor.formattedDistance,
              label: 'Distance',
              color: AppTheme.secondaryColor,
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildContactSection(BuildContext context) {
    if (vendor.address == null && vendor.phone == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          if (vendor.address != null)
            _ContactRow(
              icon: Icons.location_on,
              text: vendor.address!,
              onTap: _openMaps,
            ),
          if (vendor.phone != null) ...[
            if (vendor.address != null) const Divider(height: 20),
            _ContactRow(
              icon: Icons.phone,
              text: vendor.phone!,
              onTap: _callPhone,
            ),
          ],
          if (vendor.website != null) ...[
            const Divider(height: 20),
            _ContactRow(
              icon: Icons.language,
              text: vendor.website!,
              onTap: _openWebsite,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.directions),
            label: const Text('Y aller'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Ajouter un prix
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter prix'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPricesList(BuildContext context) {
    return pricesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'Erreur: $error',
              style: const TextStyle(color: AppTheme.priceRed),
            ),
          ),
        ),
      ),
      data: (prices) {
        if (prices.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyPrices(context),
          );
        }
        
        // Grouper les prix par produit
        final groupedPrices = _groupPricesByProduct(prices);
        
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = groupedPrices.entries.elementAt(index);
                return _ProductPriceGroup(
                  productName: entry.key,
                  prices: entry.value,
                ).animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0);
              },
              childCount: groupedPrices.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPrices(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun article signalé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à ajouter un prix\npour ce commerce !',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Ajouter un prix
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter le premier prix'),
          ),
        ],
      ),
    );
  }

  /// Groupe les prix par nom de produit.
  Map<String, List<PriceReport>> _groupPricesByProduct(List<PriceReport> prices) {
    final grouped = <String, List<PriceReport>>{};
    for (final price in prices) {
      final key = price.productName ?? 'Produit inconnu';
      grouped.putIfAbsent(key, () => []).add(price);
    }
    return grouped;
  }

  void _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${vendor.location.latitude},${vendor.location.longitude}'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone() async {
    if (vendor.phone != null) {
      final url = Uri.parse('tel:${vendor.phone}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  void _openWebsite() async {
    if (vendor.website != null) {
      final url = Uri.parse(vendor.website!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  IconData _getCategoryIcon(String? categoryId) {
    switch (categoryId) {
      case '22222222-0000-0000-0000-000000000002':
        return Icons.restaurant;
      case '22222222-0000-0000-0000-000000000005':
        return Icons.bakery_dining;
      case '22222222-0000-0000-0000-000000000004':
        return Icons.shopping_basket;
      case '22222222-0000-0000-0000-000000000006':
        return Icons.eco;
      case '22222222-0000-0000-0000-000000000011':
        return Icons.content_cut;
      case '22222222-0000-0000-0000-000000000021':
        return Icons.hardware;
      case '22222222-0000-0000-0000-000000000031':
        return Icons.local_pharmacy;
      default:
        return Icons.store;
    }
  }

  Color _getCategoryColor(String? categoryId) {
    switch (categoryId) {
      case '22222222-0000-0000-0000-000000000002':
        return AppTheme.primaryColor;
      case '22222222-0000-0000-0000-000000000005':
        return const Color(0xFFD97706);
      case '22222222-0000-0000-0000-000000000004':
        return AppTheme.secondaryColor;
      case '22222222-0000-0000-0000-000000000006':
        return AppTheme.priceGreen;
      case '22222222-0000-0000-0000-000000000011':
        return const Color(0xFF8B5CF6);
      case '22222222-0000-0000-0000-000000000021':
        return const Color(0xFF78716C);
      case '22222222-0000-0000-0000-000000000031':
        return const Color(0xFF059669);
      default:
        return AppTheme.primaryColor;
    }
  }
}

/// Carte de statistique.
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Ligne de contact.
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Groupe de prix pour un produit.
class _ProductPriceGroup extends StatelessWidget {
  final String productName;
  final List<PriceReport> prices;

  const _ProductPriceGroup({
    required this.productName,
    required this.prices,
  });

  @override
  Widget build(BuildContext context) {
    // Prendre le prix le plus récent/fiable
    final mainPrice = prices.first;
    final priceColor = AppTheme.getPriceColor(mainPrice.priceColor ?? 'orange');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header du produit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: priceColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Indicateur couleur
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: priceColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Infos produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppTheme.getPriceLabel(mainPrice.priceColor ?? 'orange'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${prices.length} signalement${prices.length > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Prix principal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mainPrice.formattedPrice,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: priceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mainPrice.unitSymbol ?? 'unité',
                      style: TextStyle(
                        color: priceColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Détails (si plusieurs prix ou métadonnées importantes)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date
                _InfoChip(
                  icon: Icons.schedule,
                  text: mainPrice.ageText,
                ),
                const SizedBox(width: 10),
                
                // Confiance
                _InfoChip(
                  icon: Icons.verified_user_outlined,
                  text: '${(mainPrice.confidenceScore * 100).toInt()}% confiance',
                ),
                
                const Spacer(),
                
                // Votes
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppTheme.priceGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${mainPrice.upvotes}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.thumb_down_alt_outlined, size: 16, color: AppTheme.priceRed),
                    const SizedBox(width: 4),
                    Text(
                      '${mainPrice.downvotes}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip d'info compact.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
