import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/recipe_suggestion_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';

/// Bottom sheet for editing recipe preferences (body type, cuisines, spice tolerance)
class RecipePreferencesSheet extends ConsumerStatefulWidget {
  const RecipePreferencesSheet({super.key});

  @override
  ConsumerState<RecipePreferencesSheet> createState() => _RecipePreferencesSheetState();
}

class _RecipePreferencesSheetState extends ConsumerState<RecipePreferencesSheet> {
  BodyType _selectedBodyType = BodyType.balanced;
  SpiceTolerance _selectedSpiceTolerance = SpiceTolerance.medium;
  final Set<String> _selectedCuisines = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (user != null) {
        final repo = ref.read(nutritionPreferencesRepositoryProvider);
        final prefs = await repo.getPreferences(user.id);
        if (prefs != null && mounted) {
          setState(() {
            _selectedBodyType = prefs.bodyTypeEnum;
            _selectedSpiceTolerance = prefs.spiceToleranceEnum;
            _selectedCuisines.addAll(prefs.favoriteCuisines);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (user != null) {
        final success = await ref.read(recipeSuggestionProvider.notifier).updatePreferences(
          userId: user.id,
          bodyType: _selectedBodyType.value,
          favoriteCuisines: _selectedCuisines.toList(),
          spiceTolerance: _selectedSpiceTolerance.value,
        );

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences saved!')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.background : AppColorsLight.background;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recipe Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Body Type Section
                    _buildSectionHeader('Body Type', textPrimary),
                    Text(
                      'Your body type helps us suggest recipes optimized for your metabolism',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...BodyType.values.map((type) => _buildBodyTypeOption(
                      type: type,
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accent: accent,
                    )),
                    const SizedBox(height: 24),

                    // Spice Tolerance Section
                    _buildSectionHeader('Spice Tolerance', textPrimary),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpiceTolerance.values.map((spice) {
                        final isSelected = spice == _selectedSpiceTolerance;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getSpiceEmoji(spice)),
                              const SizedBox(width: 4),
                              Text(spice.displayName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSpiceTolerance = spice);
                            }
                          },
                          selectedColor: accent.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? accent : textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Favorite Cuisines Section
                    _buildSectionHeader('Favorite Cuisines', textPrimary),
                    Text(
                      'Select cuisines you enjoy (tap to toggle)',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CuisineType.values.map((cuisine) {
                        final isSelected = _selectedCuisines.contains(cuisine.value);
                        return FilterChip(
                          label: Text(cuisine.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCuisines.add(cuisine.value);
                              } else {
                                _selectedCuisines.remove(cuisine.value);
                              }
                            });
                          },
                          selectedColor: accent.withValues(alpha: 0.2),
                          checkmarkColor: accent,
                          labelStyle: TextStyle(
                            color: isSelected ? accent : textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildBodyTypeOption({
    required BodyType type,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    final isSelected = type == _selectedBodyType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedBodyType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.1) : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accent : textSecondary,
                    width: 2,
                  ),
                  color: isSelected ? accent : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? accent : textPrimary,
                      ),
                    ),
                    Text(
                      type.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSpiceEmoji(SpiceTolerance spice) {
    switch (spice) {
      case SpiceTolerance.none:
        return '';
      case SpiceTolerance.mild:
        return '';
      case SpiceTolerance.medium:
        return '';
      case SpiceTolerance.hot:
        return '';
      case SpiceTolerance.extreme:
        return '';
    }
  }
}
