import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/pill_app_bar.dart';
import '../components/ai_split_preset_detail_sheet.dart';
import '../widgets/compact_split_card.dart';

/// Full-screen route showing all training split presets in a 2-column grid
/// with category filter chips.
class AllSplitsScreen extends StatefulWidget {
  /// Optional category for deep-linking (e.g. 'classic', 'ai_powered', 'specialty').
  final String? initialCategory;

  const AllSplitsScreen({super.key, this.initialCategory});

  @override
  State<AllSplitsScreen> createState() => _AllSplitsScreenState();
}

class _AllSplitsScreenState extends State<AllSplitsScreen> {
  late String _selectedCategory;

  static const _categories = <String, String>{
    'all': 'All',
    'classic': 'Classic',
    'ai_powered': 'AI-Powered',
    'specialty': 'Specialty',
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  List<AISplitPreset> get _filteredPresets {
    if (_selectedCategory == 'all') return aiSplitPresets;
    return getPresetsByCategory(_selectedCategory);
  }

  void _onPresetTap(AISplitPreset preset) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (_) => AISplitPresetDetailSheet(preset: preset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor =
        isDark ? AppColors.orange : AppColorsLight.orange;

    final presets = _filteredPresets;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(title: 'Training Splits'),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.light();
                        setState(() => _selectedCategory = entry.key);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: textMuted.withValues(alpha: 0.2),
                                ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2-column grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 140 / 110,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                return CompactSplitCard(
                  preset: preset,
                  onTap: () => _onPresetTap(preset),
                  animationIndex: index,
                )
                    .animate()
                    .fadeIn(
                      duration: 300.ms,
                      delay: (50 * index).ms,
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 300.ms,
                      delay: (50 * index).ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
