import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

// =============================================================================
// Tracking pills visibility state + provider
// =============================================================================

class TrackingPillsState {
  final bool showGoals;
  final bool showCalories;
  final bool showWater;
  final bool showBurned;
  final bool isLoaded;

  const TrackingPillsState({
    this.showGoals = true,
    this.showCalories = true,
    this.showWater = true,
    this.showBurned = true,
    this.isLoaded = false,
  });

  TrackingPillsState copyWith({
    bool? showGoals,
    bool? showCalories,
    bool? showWater,
    bool? showBurned,
    bool? isLoaded,
  }) {
    return TrackingPillsState(
      showGoals: showGoals ?? this.showGoals,
      showCalories: showCalories ?? this.showCalories,
      showWater: showWater ?? this.showWater,
      showBurned: showBurned ?? this.showBurned,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  int get visibleCount =>
      (showGoals ? 1 : 0) +
      (showCalories ? 1 : 0) +
      (showWater ? 1 : 0) +
      (showBurned ? 1 : 0);
}

class TrackingPillsNotifier extends StateNotifier<TrackingPillsState> {
  TrackingPillsNotifier() : super(const TrackingPillsState()) {
    _load();
  }

  static const _prefix = 'tracking_pill_';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TrackingPillsState(
      showGoals: prefs.getBool('${_prefix}goals') ?? true,
      showCalories: prefs.getBool('${_prefix}calories') ?? true,
      showWater: prefs.getBool('${_prefix}water') ?? true,
      showBurned: prefs.getBool('${_prefix}burned') ?? true,
      isLoaded: true,
    );
  }

  Future<void> toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
    switch (key) {
      case 'goals':
        state = state.copyWith(showGoals: value);
        break;
      case 'calories':
        state = state.copyWith(showCalories: value);
        break;
      case 'water':
        state = state.copyWith(showWater: value);
        break;
      case 'burned':
        state = state.copyWith(showBurned: value);
        break;
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}goals');
    await prefs.remove('${_prefix}calories');
    await prefs.remove('${_prefix}water');
    await prefs.remove('${_prefix}burned');
    state = const TrackingPillsState(isLoaded: true);
  }
}

final trackingPillsProvider =
    StateNotifierProvider<TrackingPillsNotifier, TrackingPillsState>(
  (ref) => TrackingPillsNotifier(),
);

// =============================================================================
// Edit Tracking Sheet
// =============================================================================

class EditTrackingSheet extends ConsumerWidget {
  const EditTrackingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillsState = ref.watch(trackingPillsProvider);
    final notifier = ref.read(trackingPillsProvider.notifier);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final pills = [
      _PillOption(
        key: 'goals',
        title: 'Daily Goals',
        subtitle: 'Login, weight, meal & workout check',
        icon: Icons.flag_outlined,
        color: const Color(0xFF22C55E),
        enabled: pillsState.showGoals,
      ),
      _PillOption(
        key: 'calories',
        title: 'Calories & Macros',
        subtitle: 'Total kcal with P/C/F breakdown',
        icon: Icons.local_fire_department_outlined,
        color: AppColors.orange,
        enabled: pillsState.showCalories,
      ),
      _PillOption(
        key: 'water',
        title: 'Water Intake',
        subtitle: 'Daily hydration vs goal',
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF3B82F6),
        enabled: pillsState.showWater,
      ),
      _PillOption(
        key: 'burned',
        title: 'Calories Burned',
        subtitle: 'From connected health devices',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF6B35),
        enabled: pillsState.showBurned,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  notifier.resetToDefaults();
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which stats to show in your tracking bar',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),

          // Pill toggles
          for (int i = 0; i < pills.length; i++) ...[
            _buildPillToggle(
              context,
              pills[i],
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              isLastEnabled: pillsState.visibleCount <= 1 && pills[i].enabled,
              onChanged: (value) {
                HapticService.light();
                notifier.toggle(pills[i].key, value);
              },
            ),
            if (i < pills.length - 1) const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          // Info
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'At least one stat must remain visible',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillToggle(
    BuildContext context,
    _PillOption pill, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required bool isLastEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pill.color.withValues(alpha: pill.enabled ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pill.icon,
              size: 20,
              color: pill.enabled ? pill.color : textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pill.enabled ? textPrimary : textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pill.subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: pill.enabled,
            onChanged: isLastEnabled ? null : onChanged,
            activeTrackColor: AppColors.cyan,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PillOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;

  const _PillOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
  });
}

/// Helper to show the edit tracking sheet
void showEditTrackingSheet(BuildContext context) {
  showGlassSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => const GlassSheet(
      child: EditTrackingSheet(),
    ),
  );
}
