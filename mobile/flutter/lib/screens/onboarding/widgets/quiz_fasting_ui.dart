part of 'quiz_fasting.dart';

/// UI builder methods extracted from _QuizFastingState
extension _QuizFastingStateUI on _QuizFastingState {

  Widget _buildCompactChoiceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required OnboardingTheme t,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? t.borderSelected : t.borderDefault,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: t.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMealDistributionInfo(OnboardingTheme t) {
    final meals = widget.mealsPerDay ?? 3;
    final eatingHours = _getEatingHours(widget.selectedProtocol);
    final maxMeals = _getMaxMealsForProtocol(widget.selectedProtocol);
    final isValid = meals <= maxMeals;

    // Calculate time between meals
    final hoursBetweenMeals = meals > 1 ? (eatingHours / (meals - 1)).toStringAsFixed(1) : eatingHours.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid
                  ? t.cardFill
                  : AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isValid
                    ? t.borderDefault
                    : AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isValid ? Icons.restaurant_menu : Icons.warning_amber_rounded,
                      color: isValid
                          ? t.textPrimary
                          : AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isValid
                            ? 'Meal schedule in ${eatingHours}h window'
                            : 'Too many meals for this window',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isValid
                              ? t.textPrimary
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isValid) ...[
                  Text(
                    '$meals meals spaced ~$hoursBetweenMeals hours apart',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                  if (eatingHours <= 4) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tip: Consider larger, nutrient-dense meals',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'A ${eatingHours}h eating window fits max $maxMeals meals.',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onMealsPerDayChanged?.call(maxMeals);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.cardFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high, size: 14, color: t.textPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Adjust to $maxMeals meals',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }


  Widget _buildSleepScheduleSection(OnboardingTheme t) {
    final wakeTime = widget.wakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    final sleepTime = widget.sleepTime ?? const TimeOfDay(hour: 23, minute: 0);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.cardFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bedtime_outlined, color: t.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your sleep schedule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'Helps optimize your fasting window',
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Wake and Sleep time pickers
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Wake up',
                        icon: Icons.wb_sunny_outlined,
                        time: wakeTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: wakeTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: AppColors.accent,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            widget.onWakeTimeChanged?.call(picked);
                          }
                        },
                        t: t,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Bedtime',
                        icon: Icons.nightlight_outlined,
                        time: sleepTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: sleepTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                    primary: AppColors.accent,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            widget.onSleepTimeChanged?.call(picked);
                          }
                        },
                        t: t,
                      ),
                    ),
                  ],
                ),

                // Suggestion based on sleep schedule
                if (widget.selectedProtocol != null) ...[
                  const SizedBox(height: 16),
                  _buildFastingWindowSuggestion(wakeTime, sleepTime, t),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1);
  }


  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
    required OnboardingTheme t,
  }) {
    final formattedTime = time.format(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: t.cardFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, color: t.textPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textSecondary,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFastingWindowSuggestion(
    TimeOfDay wakeTime,
    TimeOfDay sleepTime,
    OnboardingTheme t,
  ) {
    // Calculate suggested eating window based on wake time
    final protocol = widget.selectedProtocol;
    int eatingHours = 8;

    if (protocol?.startsWith('custom:') == true) {
      final parts = protocol!.split(':');
      if (parts.length >= 3) {
        eatingHours = int.tryParse(parts[2]) ?? 8;
      }
    } else {
      final protocolData = _QuizFastingState.allFastingProtocols.firstWhere(
        (p) => p['id'] == protocol,
        orElse: () => {'fastingHours': 16, 'eatingHours': 8},
      );
      eatingHours = (protocolData['eatingHours'] as num).toInt();
    }

    // Suggest eating window starting 1-2 hours after wake
    final eatingStartHour = (wakeTime.hour + 1) % 24;
    final eatingEndHour = (eatingStartHour + eatingHours) % 24;

    String formatHour(int hour) {
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final period = hour < 12 ? 'AM' : 'PM';
      return '$h $period';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: t.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggested eating window: ${formatHour(eatingStartHour)} - ${formatHour(eatingEndHour)}',
              style: TextStyle(
                fontSize: 12,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
