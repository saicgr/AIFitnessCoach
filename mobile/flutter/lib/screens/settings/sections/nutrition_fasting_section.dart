import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/fasting_repository.dart';
import '../../../data/services/api_client.dart';
import '../widgets/section_header.dart';

/// Provider for fasting settings state
final fastingSettingsProvider =
    StateNotifierProvider<FastingSettingsNotifier, FastingSettingsState>((ref) {
  return FastingSettingsNotifier(ref);
});

/// State for fasting settings
class FastingSettingsState {
  final bool isLoading;
  final bool interestedInFasting;
  final String? fastingProtocol;
  final String wakeTime;
  final String sleepTime;
  final FastingPreferences? fastingPreferences;

  const FastingSettingsState({
    this.isLoading = true,
    this.interestedInFasting = false,
    this.fastingProtocol,
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.fastingPreferences,
  });

  FastingSettingsState copyWith({
    bool? isLoading,
    bool? interestedInFasting,
    String? fastingProtocol,
    String? wakeTime,
    String? sleepTime,
    FastingPreferences? fastingPreferences,
  }) {
    return FastingSettingsState(
      isLoading: isLoading ?? this.isLoading,
      interestedInFasting: interestedInFasting ?? this.interestedInFasting,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      fastingPreferences: fastingPreferences ?? this.fastingPreferences,
    );
  }
}

/// Notifier for fasting settings
class FastingSettingsNotifier extends StateNotifier<FastingSettingsState> {
  final Ref _ref;

  FastingSettingsNotifier(this._ref) : super(const FastingSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Load fasting preferences from backend
      final fastingRepo = _ref.read(fastingRepositoryProvider);
      final prefs = await fastingRepo.getPreferences(user.id);

      // Parse user preferences JSON for wake/sleep times
      Map<String, dynamic> userPrefs = {};
      final prefsString = user.preferences;
      if (prefsString != null && prefsString.isNotEmpty) {
        userPrefs = _parseJson(prefsString);
      }

      final interestedInFasting =
          userPrefs['interested_in_fasting'] as bool? ?? false;
      final fastingProtocol = userPrefs['fasting_protocol'] as String?;
      final wakeTime = userPrefs['wake_time'] as String? ?? '07:00';
      final sleepTime = userPrefs['sleep_time'] as String? ?? '23:00';

      state = FastingSettingsState(
        isLoading: false,
        interestedInFasting: interestedInFasting,
        fastingProtocol: fastingProtocol ?? prefs?.defaultProtocol,
        wakeTime: wakeTime,
        sleepTime: sleepTime,
        fastingPreferences: prefs,
      );
    } catch (e) {
      debugPrint('❌ Error loading fasting settings: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      if (jsonStr.isEmpty) return {};
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> setInterestedInFasting(bool interested) async {
    state = state.copyWith(interestedInFasting: interested);
    await _saveToBackend();
  }

  Future<void> setFastingProtocol(String protocol) async {
    state = state.copyWith(fastingProtocol: protocol);
    await _saveToBackend();
  }

  Future<void> setWakeTime(String time) async {
    state = state.copyWith(wakeTime: time);
    await _saveToBackend();
  }

  Future<void> setSleepTime(String time) async {
    state = state.copyWith(sleepTime: time);
    await _saveToBackend();
  }

  Future<void> _saveToBackend() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) return;

      // Save via API - use the user preferences endpoint
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put(
        '/users/${user.id}/preferences',
        data: {
          'interested_in_fasting': state.interestedInFasting,
          'fasting_protocol': state.fastingProtocol,
          'wake_time': state.wakeTime,
          'sleep_time': state.sleepTime,
        },
      );

      debugPrint('✅ Fasting settings saved');

      // Refresh user data
      await _ref.read(authStateProvider.notifier).refreshUser();
    } catch (e) {
      debugPrint('❌ Error saving fasting settings: $e');
    }
  }

  /// Refresh settings from backend (call after onboarding or user data update)
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadSettings();
  }
}

/// The nutrition and fasting settings section.
///
/// Allows users to configure:
/// - Interest in fasting (toggle)
/// - Fasting protocol (12:12, 14:10, 16:8, etc.)
/// - Sleep schedule (wake time, sleep time)
class NutritionFastingSection extends ConsumerWidget {
  const NutritionFastingSection({super.key});

  /// Help items explaining each nutrition/fasting preference
  /// Note: Colors will be resolved at build time based on theme
  static List<Map<String, dynamic>> _getNutritionHelpItems(bool isDark) {
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    return [
      {
        'icon': Icons.restaurant_outlined,
        'title': 'Intermittent Fasting',
        'description':
            'Time-restricted eating where you cycle between periods of fasting and eating. Popular protocols include 16:8, 18:6, and OMAD.',
        'color': accentColor,
      },
      {
        'icon': Icons.schedule,
        'title': 'Fasting Protocol',
        'description':
            'The ratio of fasting to eating hours. 16:8 means 16 hours fasting, 8 hours eating window.',
        'color': accentColor,
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'title': 'Wake Time',
        'description':
            'Your typical wake-up time. Used to calculate optimal eating windows that align with your circadian rhythm.',
        'color': accentColor,
      },
      {
        'icon': Icons.bedtime_outlined,
        'title': 'Sleep Time',
        'description':
            'Your typical bedtime. Helps optimize your eating window to end 2-3 hours before sleep for better digestion.',
        'color': accentColor,
      },
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(fastingSettingsProvider);
    final helpItems = _getNutritionHelpItems(isDark);

    if (settingsState.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'NUTRITION & FASTING',
            subtitle: 'Configure your eating schedule',
            helpTitle: 'Nutrition & Fasting Explained',
            helpItems: helpItems,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'NUTRITION & FASTING',
          subtitle: 'Configure your eating schedule',
          helpTitle: 'Nutrition & Fasting Explained',
          helpItems: helpItems,
        ),
        const SizedBox(height: 12),
        _NutritionFastingCard(settingsState: settingsState),
      ],
    );
  }
}

class _NutritionFastingCard extends ConsumerWidget {
  final FastingSettingsState settingsState;

  const _NutritionFastingCard({required this.settingsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Interested in Fasting toggle - compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.restaurant_outlined, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Intermittent Fasting',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: settingsState.interestedInFasting,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(fastingSettingsProvider.notifier)
                          .setInterestedInFasting(value);
                    },
                    activeTrackColor: accentColor.withValues(alpha: 0.5),
                    activeThumbColor: accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Show protocol and sleep settings only if interested in fasting
          if (settingsState.interestedInFasting) ...[
            Divider(height: 1, color: cardBorder, indent: 14, endIndent: 14),

            // Fasting Protocol selector - compact
            InkWell(
              onTap: () => _showProtocolSelector(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Protocol',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _getProtocolDisplayName(settingsState.fastingProtocol),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: textMuted, size: 18),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: cardBorder, indent: 14, endIndent: 14),

            // Sleep Schedule - compact inline row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.bedtime_outlined, color: accentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Sleep',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Compact time pickers in a row
                  _CompactTimePicker(
                    label: 'Wake',
                    time: settingsState.wakeTime,
                    onTap: () => _showTimePicker(
                      context,
                      ref,
                      settingsState.wakeTime,
                      (time) => ref
                          .read(fastingSettingsProvider.notifier)
                          .setWakeTime(time),
                    ),
                    color: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  Text('→', style: TextStyle(color: textMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  _CompactTimePicker(
                    label: 'Sleep',
                    time: settingsState.sleepTime,
                    onTap: () => _showTimePicker(
                      context,
                      ref,
                      settingsState.sleepTime,
                      (time) => ref
                          .read(fastingSettingsProvider.notifier)
                          .setSleepTime(time),
                    ),
                    color: accentColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
    void Function(String) onTimeChanged,
  ) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeChanged(timeStr);
    }
  }

  String _getProtocolDisplayName(String? protocol) {
    if (protocol == null) return '16:8';

    // Match protocol names
    switch (protocol.toLowerCase()) {
      case '12:12':
      case 'twelve12':
        return '12:12';
      case '14:10':
      case 'fourteen10':
        return '14:10';
      case '16:8':
      case 'sixteen8':
        return '16:8';
      case '18:6':
      case 'eighteen6':
        return '18:6';
      case '20:4':
      case 'twenty4':
        return '20:4';
      case 'omad':
        return 'OMAD';
      case '5:2':
      case 'fiveTwo':
        return '5:2';
      case 'custom':
        return 'Custom';
      default:
        return protocol;
    }
  }

  void _showProtocolSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProtocolSelectorSheet(
        currentProtocol: settingsState.fastingProtocol,
        onSelect: (protocol) {
          ref.read(fastingSettingsProvider.notifier).setFastingProtocol(protocol);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Compact time picker button
class _CompactTimePicker extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _CompactTimePicker({
    required this.label,
    required this.time,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Format time for display (7:00 AM format)
    String formatTime(String time) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: textMuted),
            ),
            Text(
              formatTime(time),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting fasting protocol - compact version
class _ProtocolSelectorSheet extends StatelessWidget {
  final String? currentProtocol;
  final ValueChanged<String> onSelect;

  const _ProtocolSelectorSheet({
    required this.currentProtocol,
    required this.onSelect,
  });

  static const _protocols = [
    (id: '12:12', name: '12:12', desc: '12h fast'),
    (id: '14:10', name: '14:10', desc: '14h fast'),
    (id: '16:8', name: '16:8', desc: '16h fast ★'),
    (id: '18:6', name: '18:6', desc: '18h fast'),
    (id: '20:4', name: '20:4', desc: '20h fast'),
    (id: 'omad', name: 'OMAD', desc: '23h fast'),
    (id: '5:2', name: '5:2', desc: '2 days/wk'),
    (id: 'custom', name: 'Custom', desc: 'Your schedule'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fasting Protocol',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Grid of protocols - 4 columns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _protocols.map((protocol) {
                  final isSelected = _isProtocolSelected(protocol.id);
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(protocol.id);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 48) / 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? accentColor : cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            protocol.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? accentColor
                                  : (isDark
                                      ? Colors.white
                                      : AppColorsLight.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            protocol.desc,
                            style: TextStyle(
                              fontSize: 9,
                              color: textMuted,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isProtocolSelected(String protocolId) {
    if (currentProtocol == null) return protocolId == '16:8';
    return currentProtocol!.toLowerCase() == protocolId.toLowerCase() ||
        currentProtocol == protocolId;
  }
}
