import 'package:flutter/material.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/models/price_report.dart';

/// Carte moderne pour afficher un résultat de prix.
/// 
/// Utilisé dans le bottom sheet de résultats après une recherche
/// pour afficher les prix avec code couleur (vert/orange/rouge).
class PriceResultCardWidget extends StatelessWidget {
  final PriceReport price;
  final VoidCallback onTap;

  const PriceResultCardWidget({
    super.key,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = AppTheme.getPriceColor(price.priceColor ?? 'orange');
    final priceLabel = AppTheme.getPriceLabel(price.priceColor ?? 'orange');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: priceColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: priceColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec prix
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    priceColor.withOpacity(0.1),
                    priceColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  // Prix
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price.formattedPrice,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: priceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                price.unitSymbol ?? '',
                                style: TextStyle(
                                  color: priceColor.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Badge niveau
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            priceLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Icône confiance
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              value: price.confidenceScore,
                              strokeWidth: 3,
                              backgroundColor: priceColor.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(priceColor),
                            ),
                          ),
                          Text(
                            '${(price.confidenceScore * 100).toInt()}',
                            style: TextStyle(
                              color: priceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'confiance',
                        style: TextStyle(
                          color: priceColor.withOpacity(0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom produit
                    Text(
                      price.productName ?? 'Produit',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Commerce
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            price.vendorName ?? 'Commerce',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Footer avec métadonnées
                    Row(
                      children: [
                        // Temps
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          price.ageText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        
                        // Distance
                        if (price.distanceMeters != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.near_me,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price.formattedDistance,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Badge vérifié
                        if (price.isVerified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.accentColor,
                            ),
                          )
                        else
                          // Votes
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_up_alt_outlined,
                                size: 12,
                                color: AppTheme.priceGreen,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${price.upvotes}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
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
