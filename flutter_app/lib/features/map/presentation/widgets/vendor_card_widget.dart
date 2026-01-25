import 'package:flutter/material.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/models/vendor.dart';

/// Carte moderne pour afficher un commerce.
/// 
/// Utilisé dans le bottom sheet de résultats pour afficher
/// les commerces à proximité avec leurs informations clés.
class VendorCardWidget extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;

  const VendorCardWidget({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec image/icône
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(vendor.categoryId).withOpacity(0.15),
                    _getCategoryColor(vendor.categoryId).withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(vendor.categoryId),
                      size: 32,
                      color: _getCategoryColor(vendor.categoryId).withOpacity(0.5),
                    ),
                  ),
                  // Badge vérifié
                  if (vendor.isVerified)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  // Badge nombre de prix
                  if (vendor.priceReportCount > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.priceGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${vendor.priceReportCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      vendor.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Catégorie
                    Text(
                      vendor.categoryName ?? 'Commerce',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getCategoryColor(vendor.categoryId),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                    
                    const Spacer(),
                    
                    // Infos bas
                    Row(
                      children: [
                        if (vendor.distanceMeters != null) ...[
                          Icon(
                            Icons.near_me,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.formattedDistance,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retourne l'icône pour une catégorie.
  IconData _getCategoryIcon(String? categoryId) {
    // Mapper basé sur les ID standards ou utiliser une icône par défaut
    switch (categoryId) {
      case '22222222-0000-0000-0000-000000000002': // Boucherie
        return Icons.restaurant;
      case '22222222-0000-0000-0000-000000000005': // Boulangerie
        return Icons.bakery_dining;
      case '22222222-0000-0000-0000-000000000004': // Épicerie
        return Icons.shopping_basket;
      case '22222222-0000-0000-0000-000000000006': // Primeur
        return Icons.eco;
      case '22222222-0000-0000-0000-000000000011': // Coiffeur
        return Icons.content_cut;
      case '22222222-0000-0000-0000-000000000021': // Quincaillerie
        return Icons.hardware;
      case '22222222-0000-0000-0000-000000000031': // Pharmacie
        return Icons.local_pharmacy;
      default:
        return Icons.store;
    }
  }

  /// Retourne la couleur pour une catégorie.
  Color _getCategoryColor(String? categoryId) {
    switch (categoryId) {
      case '22222222-0000-0000-0000-000000000002': // Boucherie
        return AppTheme.primaryColor;
      case '22222222-0000-0000-0000-000000000005': // Boulangerie
        return const Color(0xFFD97706);
      case '22222222-0000-0000-0000-000000000004': // Épicerie
        return AppTheme.secondaryColor;
      case '22222222-0000-0000-0000-000000000006': // Primeur
        return AppTheme.priceGreen;
      case '22222222-0000-0000-0000-000000000011': // Coiffeur
        return const Color(0xFF8B5CF6);
      case '22222222-0000-0000-0000-000000000021': // Quincaillerie
        return const Color(0xFF78716C);
      case '22222222-0000-0000-0000-000000000031': // Pharmacie
        return const Color(0xFF059669);
      default:
        return AppTheme.secondaryColor;
    }
  }
}
