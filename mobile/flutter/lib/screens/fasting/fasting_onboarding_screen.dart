import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';

/// Onboarding screen for fasting feature with safety screening
class FastingOnboardingScreen extends ConsumerStatefulWidget {
  const FastingOnboardingScreen({super.key});

  @override
  ConsumerState<FastingOnboardingScreen> createState() =>
      _FastingOnboardingScreenState();
}

class _FastingOnboardingScreenState
    extends ConsumerState<FastingOnboardingScreen> {
  int _currentStep = 0;
  final Map<String, bool> _safetyResponses = {};
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  int _fastingStartHour = 20; // 8 PM
  int _eatingStartHour = 12; // 12 PM
  bool _notificationsEnabled = true;
  bool _isSubmitting = false;
  String? _blockReason;

  static const int _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? purple
                            : textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(_currentStep, isDark, textPrimary, textMuted, purple),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(color: purple),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _blockReason != null
                          ? null
                          : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: purple.withValues(alpha: 0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    int step,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    switch (step) {
      case 0:
        return _buildWelcomeStep(isDark, textPrimary, textMuted, purple);
      case 1:
        return _buildSafetyStep(isDark, textPrimary, textMuted, purple);
      case 2:
        return _buildProtocolStep(isDark, textPrimary, textMuted, purple);
      case 3:
        return _buildScheduleStep(isDark, textPrimary, textMuted, purple);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    return Column(
      key: const ValueKey('welcome'),
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [purple.withValues(alpha: 0.3), purple.withValues(alpha: 0.1)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.timer_outlined, size: 50, color: purple),
        ),
        const SizedBox(height: 32),
        Text(
          'Intermittent Fasting',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Track your fasting windows, monitor metabolic zones, and build healthy habits.',
          style: TextStyle(
            fontSize: 16,
            color: textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildFeatureRow(Icons.schedule, 'Popular protocols (16:8, 18:6, OMAD)', textMuted, purple),
        const SizedBox(height: 12),
        _buildFeatureRow(Icons.local_fire_department, 'Track metabolic zones', textMuted, purple),
        const SizedBox(height: 12),
        _buildFeatureRow(Icons.notifications_active, 'Smart reminders', textMuted, purple),
        const SizedBox(height: 12),
        _buildFeatureRow(Icons.insights, 'Progress analytics', textMuted, purple),
      ],
    );
  }

  Widget _buildSafetyStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    return Column(
      key: const ValueKey('safety'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Check',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please answer honestly to ensure fasting is safe for you.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),
        ...fastingSafetyQuestions.map((q) => _buildSafetyQuestion(
              q,
              isDark,
              textPrimary,
              textMuted,
              purple,
            )),
        if (_blockReason != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.coral),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _blockReason!,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSafetyQuestion(
    FastingSafetyQuestion question,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    final response = _safetyResponses[question.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: response == true && question.blocksIfTrue
              ? AppColors.coral.withValues(alpha: 0.5)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  'Yes',
                  response == true,
                  () => _setSafetyResponse(question, true),
                  isDark,
                  purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionButton(
                  'No',
                  response == false,
                  () => _setSafetyResponse(question, false),
                  isDark,
                  purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color purple,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? purple.withValues(alpha: 0.15)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? purple
                  : (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    final protocols = [
      FastingProtocol.twelve12,
      FastingProtocol.fourteen10,
      FastingProtocol.sixteen8,
      FastingProtocol.eighteen6,
      FastingProtocol.twenty4,
    ];

    return Column(
      key: const ValueKey('protocol'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Protocol',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We recommend 16:8 for most people.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),
        ...protocols.map((p) => _buildProtocolOption(p, isDark, textPrimary, textMuted, purple)),
      ],
    );
  }

  Widget _buildProtocolOption(
    FastingProtocol protocol,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    final isSelected = _selectedProtocol == protocol;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _selectedProtocol = protocol);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? purple.withValues(alpha: 0.1)
              : (isDark ? AppColors.elevated : AppColorsLight.elevated),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? purple
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  protocol.displayName.split(' ').first,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protocol.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '${protocol.fastingHours}h fasting, ${protocol.eatingHours}h eating',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: purple),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    return Column(
      key: const ValueKey('schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Your Schedule',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When do you typically start fasting?',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),

        // Fasting start time
        _buildTimeSelector(
          'Last meal ends at',
          _fastingStartHour,
          (hour) => setState(() => _fastingStartHour = hour),
          isDark,
          textPrimary,
          textMuted,
          purple,
        ),
        const SizedBox(height: 16),

        // Eating start time
        _buildTimeSelector(
          'Eating window opens at',
          _eatingStartHour,
          (hour) => setState(() => _eatingStartHour = hour),
          isDark,
          textPrimary,
          textMuted,
          purple,
        ),
        const SizedBox(height: 24),

        // Notifications toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : AppColorsLight.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_active, color: purple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fasting Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Get notified about zone transitions',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    int selectedHour,
    ValueChanged<int> onChanged,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(24, (hour) {
                final isSelected = hour == selectedHour;
                final displayHour = hour == 0
                    ? '12 AM'
                    : hour < 12
                        ? '$hour AM'
                        : hour == 12
                            ? '12 PM'
                            : '${hour - 12} PM';
                return GestureDetector(
                  onTap: () {
                    HapticService.light();
                    onChanged(hour);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? purple.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? purple
                            : textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      displayHour,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? purple : textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String text,
    Color textColor,
    Color accentColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ),
      ],
    );
  }

  void _setSafetyResponse(FastingSafetyQuestion question, bool value) {
    HapticService.light();
    setState(() {
      _safetyResponses[question.id] = value;
      // Check if this blocks the user
      if (value && question.blocksIfTrue) {
        _blockReason = question.blockMessage;
      } else {
        // Check if any other blocking condition is active
        _blockReason = null;
        for (final q in fastingSafetyQuestions) {
          if (_safetyResponses[q.id] == true && q.blocksIfTrue) {
            _blockReason = q.blockMessage;
            break;
          }
        }
      }
    });
  }

  void _previousStep() {
    HapticService.light();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _nextStep() async {
    HapticService.light();

    // Validate current step
    if (_currentStep == 1) {
      // Safety step - ensure all questions answered
      if (_safetyResponses.length < fastingSafetyQuestions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all safety questions')),
        );
        return;
      }
      if (_blockReason != null) {
        return; // Can't proceed if blocked
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final preferences = FastingPreferences(
        userId: userId,
        defaultProtocol: _selectedProtocol.displayName,
        typicalFastStartHour: _fastingStartHour,
        typicalEatingStartHour: _eatingStartHour,
        notificationsEnabled: _notificationsEnabled,
        notifyZoneTransitions: _notificationsEnabled,
        notifyGoalReached: _notificationsEnabled,
        notifyEatingWindowEnd: _notificationsEnabled,
        safetyScreeningCompleted: true,
        safetyWarningsAcknowledged:
            _safetyResponses.entries.map((e) => '${e.key}:${e.value}').toList(),
        fastingOnboardingCompleted: true,
      );

      await ref.read(fastingProvider.notifier).completeOnboarding(
            userId: userId,
            preferences: preferences,
            safetyAcknowledgments: _safetyResponses.keys.toList(),
          );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
