import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/models/vendor.dart';
import '../../../../core/models/price_report.dart';
import '../../../map/presentation/providers/map_provider.dart';

/// Page de détail d'un commerce.
/// 
/// Affiche toutes les informations d'un commerce ainsi que
/// les prix signalés pour ce commerce.
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
        data: (vendor) {
          if (vendor == null) {
            return const Center(child: Text('Commerce non trouvé'));
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
        // App bar avec image
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: vendor.primaryPhoto != null
                ? CachedNetworkImage(
                    imageUrl: vendor.primaryPhoto!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
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
                backgroundColor: Colors.white,
                child: IconButton(
                  onPressed: () {
                    // TODO: Partager le commerce
                  },
                  icon: const Icon(Icons.share),
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        
        // Contenu
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (vendor.categoryName != null)
                            Text(
                              vendor.categoryName!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (vendor.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
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
                
                const SizedBox(height: 20),
                
                // Stats
                Row(
                  children: [
                    if (vendor.ratingAvg > 0) ...[
                      _StatChip(
                        icon: Icons.star_rounded,
                        label: vendor.ratingAvg.toStringAsFixed(1),
                        sublabel: '(${vendor.ratingCount})',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                    ],
                    _StatChip(
                      icon: Icons.price_change,
                      label: '${vendor.priceReportCount}',
                      sublabel: 'prix',
                      color: AppTheme.priceGreen,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Informations de contact
                _buildInfoSection(context),
                
                const SizedBox(height: 24),
                
                // Actions rapides
                _buildActions(context),
              ],
            ),
          ),
        ),
        
        // Section prix
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix signalés',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Ajouter un prix
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ),
        
        // Liste des prix
        pricesAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Erreur: $error'),
              ),
            ),
          ),
          data: (prices) {
            if (prices.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.price_change_outlined,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun prix signalé',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Soyez le premier à ajouter un prix !',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PriceItem(price: prices[index]),
                  childCount: prices.length,
                ),
              ),
            );
          },
        ),
        
        // Espace en bas
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.backgroundLight,
      child: const Center(
        child: Icon(
          Icons.store,
          size: 64,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
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
            _InfoRow(
              icon: Icons.location_on,
              text: vendor.address!,
              onTap: () => _openMaps(),
            ),
          if (vendor.phone != null) ...[
            if (vendor.address != null) const Divider(height: 24),
            _InfoRow(
              icon: Icons.phone,
              text: vendor.phone!,
              onTap: () => _callPhone(),
            ),
          ],
          if (vendor.website != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.language,
              text: vendor.website!,
              onTap: () => _openWebsite(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openMaps(),
            icon: const Icon(Icons.directions),
            label: const Text('Y aller'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Ouvrir le formulaire d'ajout de prix
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter prix'),
          ),
        ),
      ],
    );
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  final PriceReport price;

  const _PriceItem({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
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
                Row(
                  children: [
                    Text(
                      price.ageText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    if (price.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Vérifié',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price.formattedPriceWithUnit,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_up_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${price.upvotes}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.thumb_down_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${price.downvotes}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
