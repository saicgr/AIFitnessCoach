import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

/// Pause duration option
class PauseDuration {
  final int days;
  final String label;
  final String description;
  final IconData icon;

  const PauseDuration({
    required this.days,
    required this.label,
    required this.description,
    required this.icon,
  });

  DateTime get resumeDate =>
      DateTime.now().add(Duration(days: days));
}

/// Pause Subscription Sheet
/// Allows users to pause their subscription for a specified duration
class PauseSubscriptionSheet extends StatefulWidget {
  final String planName;
  final Function(int durationDays) onPauseConfirmed;

  const PauseSubscriptionSheet({
    super.key,
    required this.planName,
    required this.onPauseConfirmed,
  });

  @override
  State<PauseSubscriptionSheet> createState() => _PauseSubscriptionSheetState();
}

class _PauseSubscriptionSheetState extends State<PauseSubscriptionSheet> {
  static const List<PauseDuration> _pauseOptions = [
    PauseDuration(
      days: 7,
      label: '1 Week',
      description: 'Short break',
      icon: Icons.timer_outlined,
    ),
    PauseDuration(
      days: 14,
      label: '2 Weeks',
      description: 'Vacation mode',
      icon: Icons.beach_access_outlined,
    ),
    PauseDuration(
      days: 30,
      label: '1 Month',
      description: 'Extended break',
      icon: Icons.calendar_month_outlined,
    ),
    PauseDuration(
      days: 60,
      label: '2 Months',
      description: 'Long pause',
      icon: Icons.event_busy_outlined,
    ),
    PauseDuration(
      days: 90,
      label: '3 Months',
      description: 'Maximum pause',
      icon: Icons.hourglass_top_outlined,
    ),
  ];

  PauseDuration? _selectedDuration;
  bool _isProcessing = false;

  void _confirmPause() {
    if (_selectedDuration == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    widget.onPauseConfirmed(_selectedDuration!.days);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pause_circle_outlined,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pause ${widget.planName}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Take a break without losing your data',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What happens when you pause',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          'Billing is paused',
                          'You won\'t be charged during the pause',
                          Icons.money_off,
                          AppColors.green,
                          textSecondary,
                        ),
                        _buildInfoItem(
                          'Data is preserved',
                          'Your workout history & progress remain safe',
                          Icons.save_alt,
                          AppColors.cyan,
                          textSecondary,
                        ),
                        _buildInfoItem(
                          'Limited access',
                          'Premium features are temporarily unavailable',
                          Icons.lock_outline,
                          Colors.amber.shade700,
                          textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Duration selector
                  Text(
                    'How long do you need?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._pauseOptions.map((option) => _buildDurationOption(
                        option,
                        isDark,
                        textPrimary,
                        textSecondary,
                        cardBorder,
                      )),

                  // Resume date preview
                  if (_selectedDuration != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_available,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-resume date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy')
                                      .format(_selectedDuration!.resumeDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedDuration != null && !_isProcessing
                          ? _confirmPause
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.amber.shade700.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedDuration != null
                                  ? 'Pause for ${_selectedDuration!.label}'
                                  : 'Select a duration',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _buildDurationOption(
    PauseDuration option,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    final isSelected = _selectedDuration == option;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDuration = option);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.amber.withValues(alpha: 0.2)
                    : (isDark
                        ? AppColors.pureBlack.withValues(alpha: 0.3)
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.amber.shade700 : textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.amber.shade700 : textPrimary,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorder, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
