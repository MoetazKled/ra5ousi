import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme_config.dart';

/// Barre de recherche "Omnibox" moderne.
/// 
/// Permet la recherche de produits et services avec debounce
/// pour éviter les requêtes trop fréquentes.
class SearchBarWidget extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    this.initialQuery,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        widget.onSearch(value.trim());
      }
    });
  }

  void _onSubmitted(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isNotEmpty) {
      widget.onSearch(value.trim());
    }
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppTheme.cardShadow,
        border: Border.all(
          color: _isFocused ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _onSubmitted,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un produit ou service...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.textMuted,
            fontSize: 15,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFocused ? Icons.search : Icons.search_rounded,
              key: ValueKey(_isFocused),
              color: _isFocused ? AppTheme.primaryColor : AppTheme.textMuted,
            ),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textMuted,
                ).animate().fadeIn(duration: 150.ms)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

/// Widget de suggestions de recherche.
class SearchSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const SearchSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((suggestion) {
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.history,
              size: 20,
              color: AppTheme.textMuted,
            ),
            title: Text(
              suggestion,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            onTap: () => onSuggestionTap(suggestion),
          );
        }).toList(),
      ),
    );
  }
}

/// Chips de recherches populaires.
class PopularSearchesWidget extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onSearchTap;

  const PopularSearchesWidget({
    super.key,
    required this.searches,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recherches populaires',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches.map((search) {
            return ActionChip(
              label: Text(search),
              onPressed: () => onSearchTap(search),
              backgroundColor: AppTheme.backgroundLight,
              side: BorderSide.none,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
