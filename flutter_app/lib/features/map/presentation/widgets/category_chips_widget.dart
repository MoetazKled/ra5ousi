import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme_config.dart';
import '../providers/map_provider.dart';

/// Widget affichant les chips de catégories pour filtrer les commerces.
/// 
/// Affiche une liste horizontale scrollable de catégories.
/// La première option "Tout" permet de retirer le filtre.
class CategoryChipsWidget extends ConsumerWidget {
  const CategoryChipsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(vendorCategoriesProvider);
    final mapState = ref.watch(mapProvider);

    return categoriesAsync.when(
      loading: () => const _LoadingChips(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        // Filtrer uniquement les catégories parent (sans parent_id)
        final parentCategories = categories
            .where((c) => c['parent_id'] == null)
            .toList();

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parentCategories.length + 1, // +1 pour "Tout"
            itemBuilder: (context, index) {
              // Premier item: "Tout"
              if (index == 0) {
                final isSelected = mapState.selectedCategorySlug == null;
                return _CategoryChip(
                  label: 'Tout',
                  icon: Icons.apps_rounded,
                  color: AppTheme.primaryColor,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(mapProvider.notifier).setCategory(null);
                  },
                );
              }

              final category = parentCategories[index - 1];
              final slug = category['slug'] as String;
              final isSelected = mapState.selectedCategorySlug == slug;

              return _CategoryChip(
                label: category['name_fr'] as String,
                icon: _getIconData(category['icon'] as String?),
                color: _parseColor(category['color'] as String?),
                isSelected: isSelected,
                onTap: () {
                  ref.read(mapProvider.notifier).setCategory(slug);
                },
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    // Mapper les noms d'icônes Material
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'lunch_dining':
        return Icons.lunch_dining_rounded;
      case 'set_meal':
        return Icons.set_meal_rounded;
      case 'local_grocery_store':
        return Icons.local_grocery_store_rounded;
      case 'bakery_dining':
        return Icons.bakery_dining_rounded;
      case 'nutrition':
        return Icons.eco_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'miscellaneous_services':
        return Icons.miscellaneous_services_rounded;
      case 'content_cut':
        return Icons.content_cut_rounded;
      case 'local_laundry_service':
        return Icons.local_laundry_service_rounded;
      case 'car_repair':
        return Icons.car_repair_rounded;
      case 'hardware':
        return Icons.hardware_rounded;
      case 'construction':
        return Icons.construction_rounded;
      case 'foundation':
        return Icons.foundation_rounded;
      case 'format_paint':
        return Icons.format_paint_rounded;
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      case 'local_pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'devices':
        return Icons.devices_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppTheme.primaryColor;
    }
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }
}

/// Chip de catégorie individuelle.
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected ? [] : AppTheme.cardShadow,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder de chargement pour les chips.
class _LoadingChips extends StatelessWidget {
  const _LoadingChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
