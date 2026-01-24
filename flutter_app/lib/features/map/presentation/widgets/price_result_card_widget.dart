import 'package:flutter/material.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/models/price_report.dart';

/// Carte pour afficher un résultat de prix dans la liste horizontale.
/// 
/// Affiche le produit, le commerce, le prix avec code couleur
/// et la distance.
class PriceResultCardWidget extends StatelessWidget {
  final PriceReport price;
  final VoidCallback? onTap;

  const PriceResultCardWidget({
    super.key,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: priceColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec couleur de prix
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: priceColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Indicateur de couleur
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTheme.getPriceLabel(price.priceColor ?? 'orange'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: priceColor,
                      ),
                    ),
                  ),
                  if (price.isVerified)
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.accentColor,
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
                    // Nom du produit
                    Text(
                      price.productName ?? 'Produit',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Commerce
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
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
                    
                    const Spacer(),
                    
                    // Prix
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        price.formattedPriceWithUnit,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: priceColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Footer avec distance et âge
                    Row(
                      children: [
                        if (price.distanceMeters != null) ...[
                          const Icon(
                            Icons.near_me,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price.formattedDistance,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            price.ageText,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
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
}

/// Version liste (verticale) de la carte prix.
class PriceResultListItem extends StatelessWidget {
  final PriceReport price;
  final VoidCallback? onTap;
  final VoidCallback? onVote;

  const PriceResultListItem({
    super.key,
    required this.price,
    this.onTap,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Indicateur de couleur
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: priceColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Infos produit/commerce
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price.productName ?? 'Produit',
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price.vendorName ?? 'Commerce',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (price.distanceMeters != null) ...[
                                const Icon(
                                  Icons.near_me,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  price.formattedDistance,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(width: 12),
                              ],
                              const Icon(
                                Icons.schedule,
                                size: 12,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                price.ageText,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Prix et actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: priceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: priceColor, width: 1),
                          ),
                          child: Text(
                            price.formattedPriceWithUnit,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: priceColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Votes
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _VoteButton(
                              icon: Icons.thumb_up_outlined,
                              count: price.upvotes,
                              color: AppTheme.priceGreen,
                              onTap: onVote,
                            ),
                            const SizedBox(width: 8),
                            _VoteButton(
                              icon: Icons.thumb_down_outlined,
                              count: price.downvotes,
                              color: AppTheme.priceRed,
                              onTap: onVote,
                            ),
                          ],
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
}

/// Bouton de vote.
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
