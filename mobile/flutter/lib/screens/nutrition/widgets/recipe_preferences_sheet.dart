import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/recipe_suggestion_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    // Fire-and-forget. The provider returns a bool today but we don't gate
    // the pop on it — failure surfaces via a toast below, and any UI that
    // depends on the saved prefs reads from the recipe feed which re-fetches
    // after this completes. Sheet pops in the same frame as the tap.
    unawaited(() async {
      try {
        final success = await ref
            .read(recipeSuggestionProvider.notifier)
            .updatePreferences(
              userId: user.id,
              bodyType: _selectedBodyType.value,
              favoriteCuisines: _selectedCuisines.toList(),
              spiceTolerance: _selectedSpiceTolerance.value,
            );
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't save recipe preferences.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }());

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)
            .recipePreferencesPreferencesSaved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final accent = tc.accent;

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
                        AppLocalizations.of(context).recipePreferencesRecipePreferences,
                        style: ZType.disp(22, color: textPrimary),
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
                              AppLocalizations.of(context).buttonSave,
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
                      AppLocalizations.of(context).recipePreferencesYourBodyTypeHelps,
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
                        final emoji = _getSpiceEmoji(spice);
                        return ZealovaChip(
                          label: spice.displayName,
                          emoji: emoji.isNotEmpty ? emoji : null,
                          selected: isSelected,
                          onTap: () {
                            setState(() => _selectedSpiceTolerance = spice);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Favorite Cuisines Section
                    _buildSectionHeader('Favorite Cuisines', textPrimary),
                    Text(
                      AppLocalizations.of(context).recipePreferencesSelectCuisinesYouEnjoy,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CuisineType.values.map((cuisine) {
                        final isSelected = _selectedCuisines.contains(cuisine.value);
                        return ZealovaChip(
                          label: cuisine.displayName,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCuisines.remove(cuisine.value);
                              } else {
                                _selectedCuisines.add(cuisine.value);
                              }
                            });
                          },
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
      child: ZealovaSectionKicker(title),
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
    final cardBorder = Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedBodyType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : cardBorder,
              width: isSelected ? 1.5 : 1,
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
                    ? Icon(Icons.check, size: 14, color: ThemeColors.of(context).accentContrast)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: ZType.lbl(
                        14,
                        color: isSelected ? accent : textPrimary,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
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
