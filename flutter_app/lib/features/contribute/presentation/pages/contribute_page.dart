import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme_config.dart';
import '../widgets/add_price_form_widget.dart';

/// Page de contribution pour ajouter des prix.
/// 
/// Permet aux utilisateurs de signaler un nouveau prix
/// pour un produit dans un commerce.
class ContributePage extends ConsumerStatefulWidget {
  const ContributePage({super.key});

  @override
  ConsumerState<ContributePage> createState() => _ContributePageState();
}

class _ContributePageState extends ConsumerState<ContributePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribuer',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aidez la communauté en signalant les prix que vous trouvez.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Options de contribution
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Ajouter un prix
                  _ContributionCard(
                    icon: Icons.price_change_rounded,
                    iconColor: AppTheme.priceGreen,
                    title: 'Signaler un prix',
                    subtitle: 'Ajoutez le prix d\'un produit ou service',
                    points: '+10 points',
                    onTap: () => _showAddPriceSheet(context),
                  ),
                  const SizedBox(height: 12),
                  
                  // Ajouter un commerce
                  _ContributionCard(
                    icon: Icons.add_business_rounded,
                    iconColor: AppTheme.accentColor,
                    title: 'Ajouter un commerce',
                    subtitle: 'Référencez un nouveau commerce',
                    points: '+20 points',
                    onTap: () {
                      // TODO: Implémenter l'ajout de commerce
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité bientôt disponible'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Scanner un code-barres
                  _ContributionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: AppTheme.secondaryColor,
                    title: 'Scanner un produit',
                    subtitle: 'Scannez le code-barres pour identifier le produit',
                    points: '+5 points',
                    onTap: () {
                      // TODO: Implémenter le scanner
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scanner bientôt disponible'),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section classement
                  Text(
                    'Classement des contributeurs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Placeholder pour le classement
                  _LeaderboardPlaceholder(),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Espace pour la bottom nav
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPriceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: AddPriceFormWidget(scrollController: scrollController),
        ),
      ),
    );
  }
}

/// Carte d'option de contribution.
class _ContributionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String points;
  final VoidCallback onTap;

  const _ContributionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Points
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.priceGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  points,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.priceGreen,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder pour le classement.
class _LeaderboardPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Top 3 placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LeaderboardPosition(
                position: 2,
                name: 'Ahmed',
                points: 1250,
                color: Colors.grey,
              ),
              _LeaderboardPosition(
                position: 1,
                name: 'Sana',
                points: 2100,
                color: Colors.amber,
                isFirst: true,
              ),
              _LeaderboardPosition(
                position: 3,
                name: 'Mohamed',
                points: 980,
                color: Colors.brown.shade300,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          
          // Position de l'utilisateur
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '42',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vous',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '320 points',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget de position dans le classement.
class _LeaderboardPosition extends StatelessWidget {
  final int position;
  final String name;
  final int points;
  final Color color;
  final bool isFirst;

  const _LeaderboardPosition({
    required this.position,
    required this.name,
    required this.points,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isFirst)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: isFirst ? 32 : 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            name[0],
            style: TextStyle(
              fontSize: isFirst ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          '$points pts',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
