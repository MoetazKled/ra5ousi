import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/theme_config.dart';
import '../../../../core/models/product.dart';
import '../../../../core/models/vendor.dart';
import '../providers/contribute_provider.dart';

/// Formulaire modal pour ajouter un nouveau prix.
/// 
/// Permet de sélectionner un produit, un commerce, entrer le prix
/// et optionnellement ajouter une photo.
class AddPriceFormWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String? preselectedVendorId;
  final String? preselectedProductId;

  const AddPriceFormWidget({
    super.key,
    required this.scrollController,
    this.preselectedVendorId,
    this.preselectedProductId,
  });

  @override
  ConsumerState<AddPriceFormWidget> createState() => _AddPriceFormWidgetState();
}

class _AddPriceFormWidgetState extends ConsumerState<AddPriceFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final _priceController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _vendorSearchController = TextEditingController();
  final _notesController = TextEditingController();
  
  // État du formulaire
  Product? _selectedProduct;
  Vendor? _selectedVendor;
  String? _selectedUnitId;
  bool _isPromotion = false;
  DateTime? _promoEndDate;
  String? _photoPath;
  
  // État de l'UI
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _priceController.dispose();
    _productSearchController.dispose();
    _vendorSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Header avec handle et titre
          _buildHeader(),
          
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu scrollable
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Étape 1: Sélection du produit
                _buildProductSection(),
                
                const SizedBox(height: 24),
                
                // Étape 2: Sélection du commerce
                _buildVendorSection(),
                
                const SizedBox(height: 24),
                
                // Étape 3: Prix et détails
                _buildPriceSection(),
                
                const SizedBox(height: 24),
                
                // Options supplémentaires
                _buildOptionsSection(),
                
                const SizedBox(height: 32),
                
                // Bouton de soumission
                _buildSubmitButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Titre et bouton fermer
          Row(
            children: [
              Expanded(
                child: Text(
                  'Signaler un prix',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppTheme.primaryColor
                          : AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductSection() {
    return _FormSection(
      title: '1. Quel produit ou service ?',
      icon: Icons.inventory_2_outlined,
      isCompleted: _selectedProduct != null,
      child: Column(
        children: [
          // Champ de recherche
          TextFormField(
            controller: _productSearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _productSearchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _productSearchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
              // TODO: Déclencher la recherche
            },
          ),
          
          // Produit sélectionné
          if (_selectedProduct != null) ...[
            const SizedBox(height: 12),
            _SelectedItemChip(
              label: _selectedProduct!.nameFr,
              onRemove: () {
                setState(() {
                  _selectedProduct = null;
                  _selectedUnitId = null;
                });
              },
            ),
          ],
          
          // Suggestions de produits populaires
          if (_selectedProduct == null) ...[
            const SizedBox(height: 16),
            Text(
              'Produits populaires',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Viande de bœuf',
                'Poulet',
                'Lait',
                'Pain',
                'Huile d\'olive',
                'Coupe homme',
              ].map((name) => ActionChip(
                label: Text(name),
                onPressed: () {
                  // TODO: Sélectionner le produit
                  setState(() {
                    _currentStep = 1;
                  });
                },
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorSection() {
    return _FormSection(
      title: '2. Dans quel commerce ?',
      icon: Icons.store_outlined,
      isCompleted: _selectedVendor != null,
      child: Column(
        children: [
          // Champ de recherche
          TextFormField(
            controller: _vendorSearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un commerce...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_vendorSearchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _vendorSearchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    onPressed: () {
                      // TODO: Utiliser la localisation pour trouver les commerces proches
                    },
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Commerces à proximité',
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          
          // Commerce sélectionné
          if (_selectedVendor != null) ...[
            const SizedBox(height: 12),
            _SelectedItemChip(
              label: _selectedVendor!.name,
              sublabel: _selectedVendor!.address,
              onRemove: () {
                setState(() {
                  _selectedVendor = null;
                });
              },
            ),
          ],
          
          // Option pour ajouter un nouveau commerce
          if (_selectedVendor == null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Ouvrir le formulaire d'ajout de commerce
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Ajouter un nouveau commerce'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return _FormSection(
      title: '3. Quel prix ?',
      icon: Icons.attach_money,
      isCompleted: _priceController.text.isNotEmpty,
      child: Column(
        children: [
          // Champ de prix
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prix
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Prix',
                    hintText: '0.000',
                    suffixText: AppConfig.currencySymbol,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez un prix';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty) {
                        _currentStep = 2;
                      }
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Unité
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnitId,
                  decoration: const InputDecoration(
                    labelText: 'Par',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'L', child: Text('L')),
                    DropdownMenuItem(value: 'unité', child: Text('unité')),
                    DropdownMenuItem(value: 'séance', child: Text('séance')),
                    DropdownMenuItem(value: 'm²', child: Text('m²')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnitId = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options supplémentaires',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Promotion
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: SwitchListTile(
            title: const Text('Prix promotionnel'),
            subtitle: const Text('Ce prix est temporaire'),
            value: _isPromotion,
            onChanged: (value) {
              setState(() {
                _isPromotion = value;
                if (!value) {
                  _promoEndDate = null;
                }
              });
            },
            secondary: Icon(
              Icons.local_offer,
              color: _isPromotion ? AppTheme.priceGreen : AppTheme.textMuted,
            ),
          ),
        ),
        
        // Date de fin de promo
        if (_isPromotion) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _promoEndDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() {
                  _promoEndDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _promoEndDate != null
                          ? 'Fin le ${_formatDate(_promoEndDate!)}'
                          : 'Date de fin de promotion',
                      style: TextStyle(
                        color: _promoEndDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Photo
        InkWell(
          onTap: () {
            // TODO: Ouvrir le sélecteur de photo
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _photoPath != null ? AppTheme.priceGreen : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _photoPath != null ? Icons.check_circle : Icons.camera_alt,
                  color: _photoPath != null ? AppTheme.priceGreen : AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _photoPath != null ? 'Photo ajoutée' : 'Ajouter une photo',
                        style: TextStyle(
                          color: _photoPath != null
                              ? AppTheme.priceGreen
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '+5 points bonus',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.priceGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Notes
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            hintText: 'Ex: Prix affiché en vitrine, valable le matin...',
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _selectedProduct != null &&
        _selectedVendor != null &&
        _priceController.text.isNotEmpty;

    return Column(
      children: [
        // Récapitulatif des points
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.priceGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppTheme.priceGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Vous gagnerez ${_calculatePoints()} points',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.priceGreen,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid && !_isSubmitting ? _submitForm : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Soumettre le prix'),
          ),
        ),
      ],
    );
  }

  int _calculatePoints() {
    int points = AppConfig.pointsForPriceReport; // 10
    if (_photoPath != null) {
      points += AppConfig.pointsForPhoto; // +5
    }
    return points;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Appeler le repository pour soumettre le prix
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Prix ajouté ! +${_calculatePoints()} points'),
              ],
            ),
            backgroundColor: AppTheme.priceGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.priceRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/// Section du formulaire avec titre et icône.
class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isCompleted;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.isCompleted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.priceGreen
                    : AppTheme.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: 18,
                color: isCompleted ? Colors.white : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: child,
        ),
      ],
    );
  }
}

/// Chip pour un élément sélectionné.
class _SelectedItemChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final VoidCallback onRemove;

  const _SelectedItemChip({
    required this.label,
    this.sublabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
