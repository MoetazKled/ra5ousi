import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/theme_config.dart';

/// Widget de sélection du rayon de recherche.
/// 
/// Affiche un slider compact permettant de choisir le rayon
/// de recherche entre 500m et 20km.
class RadiusSliderWidget extends StatefulWidget {
  final int currentRadius;
  final ValueChanged<int> onRadiusChanged;

  const RadiusSliderWidget({
    super.key,
    required this.currentRadius,
    required this.onRadiusChanged,
  });

  @override
  State<RadiusSliderWidget> createState() => _RadiusSliderWidgetState();
}

class _RadiusSliderWidgetState extends State<RadiusSliderWidget> {
  late double _currentValue;
  bool _isExpanded = false;

  // Valeurs de rayon prédéfinies (en mètres)
  static const List<int> _radiusValues = [
    500, 1000, 2000, 3000, 5000, 7500, 10000, 15000, 20000
  ];

  @override
  void initState() {
    super.initState();
    _currentValue = _getSliderValue(widget.currentRadius);
  }

  @override
  void didUpdateWidget(RadiusSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRadius != widget.currentRadius) {
      _currentValue = _getSliderValue(widget.currentRadius);
    }
  }

  /// Convertit un rayon en valeur de slider (0 à 1).
  double _getSliderValue(int radius) {
    final index = _radiusValues.indexWhere((r) => r >= radius);
    if (index == -1) return 1.0;
    return index / (_radiusValues.length - 1);
  }

  /// Convertit une valeur de slider en rayon.
  int _getRadius(double value) {
    final index = (value * (_radiusValues.length - 1)).round();
    return _radiusValues[index.clamp(0, _radiusValues.length - 1)];
  }

  /// Formate le rayon pour l'affichage.
  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: _isExpanded ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec le rayon actuel
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rayon : ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  _formatRadius(_getRadius(_currentValue)),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            
            // Slider (visible quand expanded)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.divider,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _currentValue,
                      onChanged: (value) {
                        setState(() {
                          _currentValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        widget.onRadiusChanged(_getRadius(value));
                      },
                    ),
                  ),
                  // Labels de rayon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatRadius(_radiusValues.first),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        _formatRadius(_radiusValues.last),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
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

/// Chips de rayons rapides.
class QuickRadiusChipsWidget extends StatelessWidget {
  final int currentRadius;
  final ValueChanged<int> onRadiusChanged;

  const QuickRadiusChipsWidget({
    super.key,
    required this.currentRadius,
    required this.onRadiusChanged,
  });

  static const _quickRadii = [1000, 3000, 5000, 10000];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _quickRadii.map((radius) {
        final isSelected = currentRadius == radius;
        return ChoiceChip(
          label: Text(_formatRadius(radius)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onRadiusChanged(radius);
            }
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.15),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(0)} km';
  }
}
