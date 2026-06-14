import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/pill_app_bar.dart';
import '../components/ai_split_preset_detail_sheet.dart';
import '../widgets/compact_split_card.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Full-screen route showing all training split presets in a 2-column grid
/// with category filter chips.
class AllSplitsScreen extends ConsumerStatefulWidget {
  /// Optional category for deep-linking (e.g. 'classic', 'ai_powered', 'specialty').
  final String? initialCategory;

  const AllSplitsScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AllSplitsScreen> createState() => _AllSplitsScreenState();
}

class _AllSplitsScreenState extends ConsumerState<AllSplitsScreen> {
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
    ref.read(posthogServiceProvider).capture(
      eventName: 'splits_library_viewed',
    );
  }

  List<AISplitPreset> get _filteredPresets {
    if (_selectedCategory == 'all') return aiSplitPresets;
    return getPresetsByCategory(_selectedCategory);
  }

  void _onPresetTap(AISplitPreset preset) {
    HapticService.light();
    ref.read(posthogServiceProvider).capture(
      eventName: 'split_selected',
      properties: {'split_name': preset.name},
    );
    showGlassSheet(
      context: context,
      builder: (_) => AISplitPresetDetailSheet(preset: preset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final backgroundColor = tc.background;

    final presets = _filteredPresets;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(title: AppLocalizations.of(context).netflixExercisesTabTrainingSplits),
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
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ZealovaChip(
                      label: entry.value,
                      selected: isSelected,
                      onTap: () {
                        HapticService.light();
                        setState(() => _selectedCategory = entry.key);
                      },
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
