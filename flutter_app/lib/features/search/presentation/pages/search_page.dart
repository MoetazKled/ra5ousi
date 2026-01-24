import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme_config.dart';
import '../../../map/presentation/widgets/search_bar_widget.dart';
import '../../../map/presentation/widgets/price_result_card_widget.dart';
import '../../../map/presentation/providers/map_provider.dart';

/// Page de recherche dédiée.
/// 
/// Offre une expérience de recherche plus complète avec
/// historique, suggestions et résultats détaillés.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showHistory = true;

  // Historique de recherche fictif pour la démo
  final List<String> _searchHistory = [
    'Viande de bœuf',
    'Lait',
    'Coupe homme',
    'Ciment',
    'Huile d\'olive',
  ];

  // Recherches populaires
  final List<String> _popularSearches = [
    'Pain',
    'Poulet',
    'Essence',
    'Fruits',
    'Légumes',
    'Coiffeur',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec barre de recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rechercher',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SearchBarWidget(
                    initialQuery: mapState.searchQuery,
                    onSearch: (query) {
                      setState(() {
                        _showHistory = false;
                      });
                      ref.read(mapProvider.notifier).searchProducts(query);
                    },
                    onClear: () {
                      setState(() {
                        _showHistory = true;
                      });
                      ref.read(mapProvider.notifier).clearSearch();
                    },
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: _showHistory && !mapState.isSearchMode
                  ? _buildHistoryAndSuggestions()
                  : _buildSearchResults(mapState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Historique de recherche
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recherches récentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchHistory.clear();
                  });
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((query) {
              return InputChip(
                label: Text(query),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _searchHistory.remove(query);
                  });
                },
                onPressed: () {
                  ref.read(mapProvider.notifier).searchProducts(query);
                  setState(() {
                    _showHistory = false;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        
        // Recherches populaires
        Text(
          'Recherches populaires',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(_popularSearches.map((query) {
          return ListTile(
            leading: const Icon(Icons.trending_up, color: AppTheme.primaryColor),
            title: Text(query),
            trailing: const Icon(Icons.north_east, size: 18, color: AppTheme.textMuted),
            onTap: () {
              ref.read(mapProvider.notifier).searchProducts(query);
              setState(() {
                _showHistory = false;
              });
            },
          );
        })),
        
        const SizedBox(height: 24),
        
        // Catégories rapides
        Text(
          'Explorer par catégorie',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Alimentation', 'icon': Icons.restaurant, 'color': AppTheme.priceRed},
      {'name': 'Services', 'icon': Icons.miscellaneous_services, 'color': AppTheme.secondaryColor},
      {'name': 'Bricolage', 'icon': Icons.hardware, 'color': AppTheme.priceOrange},
      {'name': 'Santé', 'icon': Icons.health_and_safety, 'color': AppTheme.priceGreen},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return InkWell(
          onTap: () {
            // TODO: Filtrer par catégorie
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (cat['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (cat['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: cat['color'] as Color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cat['name'] as String,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(MapState mapState) {
    if (mapState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (mapState.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres termes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${mapState.searchResults.length} résultats',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              // TODO: Ajouter des options de tri
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sort, size: 18),
                label: const Text('Trier'),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: mapState.searchResults.length,
            itemBuilder: (context, index) {
              final price = mapState.searchResults[index];
              return PriceResultListItem(
                price: price,
                onTap: () {
                  // TODO: Afficher les détails du prix
                },
                onVote: () {
                  // TODO: Voter sur le prix
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
