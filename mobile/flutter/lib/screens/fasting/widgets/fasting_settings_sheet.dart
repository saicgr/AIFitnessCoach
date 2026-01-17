import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for editing fasting settings/preferences
class FastingSettingsSheet extends ConsumerStatefulWidget {
  final FastingPreferences preferences;

  const FastingSettingsSheet({
    super.key,
    required this.preferences,
  });

  @override
  ConsumerState<FastingSettingsSheet> createState() => _FastingSettingsSheetState();
}

class _FastingSettingsSheetState extends ConsumerState<FastingSettingsSheet> {
  late FastingProtocol _selectedProtocol;
  late int _customHours;
  late int _fastStartHour;
  late int _eatingStartHour;
  late bool _notifyZoneTransitions;
  late bool _notifyGoalReached;
  late bool _notifyEatingWindowEnd;
  late bool _notifyFastStartReminder;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.preferences;
    _selectedProtocol = FastingProtocol.fromString(prefs.defaultProtocol);
    _customHours = prefs.customFastingHours ?? 16;
    _fastStartHour = prefs.typicalFastStartHour;
    _eatingStartHour = prefs.typicalEatingStartHour;
    _notifyZoneTransitions = prefs.notifyZoneTransitions;
    _notifyGoalReached = prefs.notifyGoalReached;
    _notifyEatingWindowEnd = prefs.notifyEatingWindowEnd;
    _notifyFastStartReminder = prefs.notifyFastStartReminder;
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    HapticService.medium();

    try {
      final updatedPrefs = widget.preferences.copyWith(
        defaultProtocol: _selectedProtocol.displayName,
        customFastingHours: _selectedProtocol == FastingProtocol.custom ? _customHours : null,
        typicalFastStartHour: _fastStartHour,
        typicalEatingStartHour: _eatingStartHour,
        notifyZoneTransitions: _notifyZoneTransitions,
        notifyGoalReached: _notifyGoalReached,
        notifyEatingWindowEnd: _notifyEatingWindowEnd,
        notifyFastStartReminder: _notifyFastStartReminder,
      );

      await ref.read(fastingProvider.notifier).savePreferences(
            userId: userId,
            preferences: updatedPrefs,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fasting settings saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  Future<void> _selectTime(bool isFastStart) async {
    final initialHour = isFastStart ? _fastStartHour : _eatingStartHour;

    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isFastStart) {
          _fastStartHour = result.hour;
        } else {
          _eatingStartHour = result.hour;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar and header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                  children: [
                    Icon(Icons.settings, color: accentColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Fasting Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Protocol Section
                  _buildSectionHeader('Default Protocol', textPrimary),
                  const SizedBox(height: 12),
                  _buildProtocolSelector(
                    isDark: isDark,
                    accentColor: accentColor,
                    accentContrast: accentContrast,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                  ),
                  const SizedBox(height: 24),

                  // Typical Schedule Section
                  _buildSectionHeader('Typical Schedule', textPrimary),
                  const SizedBox(height: 12),
                  _buildScheduleSection(
                    isDark: isDark,
                    accentColor: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                  ),
                  const SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionHeader('Notifications', textPrimary),
                  const SizedBox(height: 12),
                  _buildNotificationsSection(
                    isDark: isDark,
                    accentColor: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: accentContrast,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: accentContrast,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Bottom safe area padding
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildProtocolSelector({
    required bool isDark,
    required Color accentColor,
    required Color accentContrast,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
  }) {
    // Common protocols for quick selection
    final protocols = [
      FastingProtocol.twelve12,
      FastingProtocol.fourteen10,
      FastingProtocol.sixteen8,
      FastingProtocol.eighteen6,
      FastingProtocol.twenty4,
      FastingProtocol.omad,
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Protocol chips in a wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: protocols.map((protocol) {
              final isSelected = _selectedProtocol == protocol;
              return GestureDetector(
                onTap: () {
                  HapticService.light();
                  setState(() => _selectedProtocol = protocol);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    protocol.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentContrast : textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Custom option
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() => _selectedProtocol = FastingProtocol.custom);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedProtocol == FastingProtocol.custom
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedProtocol == FastingProtocol.custom
                      ? accentColor
                      : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: _selectedProtocol == FastingProtocol.custom ? accentColor : textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (_selectedProtocol == FastingProtocol.custom) ...[
                    Text(
                      '${_customHours}h fasting',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Custom hours slider (shown when custom is selected)
          if (_selectedProtocol == FastingProtocol.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Fasting hours:',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                Expanded(
                  child: Slider(
                    value: _customHours.toDouble(),
                    min: 12,
                    max: 23,
                    divisions: 11,
                    activeColor: accentColor,
                    inactiveColor: accentColor.withValues(alpha: 0.2),
                    onChanged: (value) {
                      setState(() => _customHours = value.round());
                    },
                  ),
                ),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '${_customHours}h',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection({
    required bool isDark,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Fast Start Time
          _buildTimeRow(
            icon: Icons.nights_stay,
            label: 'Start fasting at',
            time: _formatHour(_fastStartHour),
            onTap: () => _selectTime(true),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          Divider(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            height: 24,
          ),

          // Eating Start Time
          _buildTimeRow(
            icon: Icons.restaurant,
            label: 'Start eating at',
            time: _formatHour(_eatingStartHour),
            onTap: () => _selectTime(false),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required String time,
    required VoidCallback onTap,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection({
    required bool isDark,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildNotificationToggle(
            icon: Icons.swap_horiz,
            label: 'Zone transitions',
            subtitle: 'Notify when entering new fasting zones',
            value: _notifyZoneTransitions,
            onChanged: (v) => setState(() => _notifyZoneTransitions = v),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildNotificationToggle(
            icon: Icons.flag,
            label: 'Goal reached',
            subtitle: 'Notify when you reach your fasting goal',
            value: _notifyGoalReached,
            onChanged: (v) => setState(() => _notifyGoalReached = v),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildNotificationToggle(
            icon: Icons.restaurant_menu,
            label: 'Eating window end',
            subtitle: 'Remind before eating window closes',
            value: _notifyEatingWindowEnd,
            onChanged: (v) => setState(() => _notifyEatingWindowEnd = v),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          _buildNotificationToggle(
            icon: Icons.alarm,
            label: 'Fast start reminder',
            subtitle: 'Remind when it\'s time to start fasting',
            value: _notifyFastStartReminder,
            onChanged: (v) => setState(() => _notifyFastStartReminder = v),
            accentColor: accentColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: accentColor,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 48,
            endIndent: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardBorder
                : AppColorsLight.cardBorder,
          ),
      ],
    );
  }
}
