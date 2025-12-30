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
  final Set<String> _acknowledgedWarnings = {};
  FastingProtocol _selectedProtocol = FastingProtocol.sixteen8;
  int _fastingStartHour = 20; // 8 PM
  int _eatingStartHour = 12; // 12 PM
  bool _notificationsEnabled = true;
  bool _mealRemindersEnabled = true;
  int _lunchReminderHour = 12;
  int _dinnerReminderHour = 18;
  int _customFastingHours = 16;
  int _customEatingHours = 8;
  bool _isSubmitting = false;
  bool _showingExtendedProtocols = false;

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
            // Header with skip button and progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button (only show after step 0)
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _previousStep,
                      icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 8),
                  // Progress indicator
                  Expanded(
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
                  const SizedBox(width: 8),
                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(_currentStep, isDark, textPrimary, textMuted, purple),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
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
                            fontSize: 16,
                          ),
                        ),
                ),
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
    final hasWarning = response == true && question.allowContinueWithWarning;
    final isAcknowledged = _acknowledgedWarnings.contains(question.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasWarning && !isAcknowledged
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
                child: _buildColoredOptionButton(
                  'Yes',
                  response == true,
                  () => _setSafetyResponse(question, true),
                  isDark,
                  isYes: true,
                  hasWarning: question.warnMessage != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildColoredOptionButton(
                  'No',
                  response == false,
                  () => _setSafetyResponse(question, false),
                  isDark,
                  isYes: false,
                  hasWarning: false,
                ),
              ),
            ],
          ),
          // Show acknowledged warning badge
          if (hasWarning && isAcknowledged) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Acknowledged',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColoredOptionButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark, {
    required bool isYes,
    required bool hasWarning,
  }) {
    // Colors based on selection and type
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      if (isYes && hasWarning) {
        // Yes with warning - orange/coral
        backgroundColor = AppColors.coral.withValues(alpha: 0.15);
        borderColor = AppColors.coral;
        textColor = AppColors.coral;
      } else if (isYes) {
        // Yes selected (no warning)
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.green;
        textColor = Colors.green;
      } else {
        // No selected
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.green;
        textColor = Colors.green;
      }
    } else {
      // Unselected state
      backgroundColor = (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
          .withValues(alpha: 0.5);
      borderColor = Colors.transparent;
      textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: textColor,
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
    // Standard protocols (TRE)
    final standardProtocols = [
      FastingProtocol.twelve12,
      FastingProtocol.fourteen10,
      FastingProtocol.sixteen8,
      FastingProtocol.eighteen6,
      FastingProtocol.twenty4,
      FastingProtocol.omad,
    ];

    // Extended/Advanced protocols
    final extendedProtocols = [
      FastingProtocol.waterFast24,
      FastingProtocol.waterFast48,
      FastingProtocol.waterFast72,
      FastingProtocol.waterFast7Day,
      FastingProtocol.fiveTwo,
      FastingProtocol.adf,
      FastingProtocol.custom,
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
          'We recommend 16:8 for most people starting out.',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),

        // Standard protocols section
        Text(
          'Time-Restricted Eating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ...standardProtocols.map((p) => _buildProtocolOption(p, isDark, textPrimary, textMuted, purple)),

        const SizedBox(height: 20),

        // Extended protocols toggle
        GestureDetector(
          onTap: () => setState(() => _showingExtendedProtocols = !_showingExtendedProtocols),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showingExtendedProtocols
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extended & Custom Protocols',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Advanced',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Extended protocols (collapsible)
        if (_showingExtendedProtocols) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.coral, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extended fasts require medical supervision. Consult your doctor first.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...extendedProtocols.map((p) => _buildProtocolOption(p, isDark, textPrimary, textMuted, purple)),
        ],

        // Custom protocol settings
        if (_selectedProtocol == FastingProtocol.custom) ...[
          const SizedBox(height: 20),
          _buildCustomProtocolSettings(isDark, textPrimary, textMuted, purple),
        ],
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
    final isDangerous = protocol.isDangerous;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        if (isDangerous) {
          _showDangerousProtocolWarning(protocol);
        } else {
          setState(() => _selectedProtocol = protocol);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDangerous
                  ? AppColors.coral.withValues(alpha: 0.1)
                  : purple.withValues(alpha: 0.1))
              : (isDark ? AppColors.elevated : AppColorsLight.elevated),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDangerous ? AppColors.coral : purple)
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
                color: (isDangerous ? AppColors.coral : purple).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: protocol == FastingProtocol.custom
                    ? Icon(Icons.tune, size: 24, color: purple)
                    : Text(
                        _getProtocolShortName(protocol),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDangerous ? AppColors.coral : purple,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          protocol.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (isDangerous)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CAUTION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (protocol != FastingProtocol.custom)
                    Text(
                      '${protocol.fastingHours}h fasting${protocol.eatingHours > 0 ? ', ${protocol.eatingHours}h eating' : ''}',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  if (protocol.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      protocol.description!,
                      style: TextStyle(fontSize: 11, color: textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(protocol.difficulty).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      protocol.difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getDifficultyColor(protocol.difficulty),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                color: isDangerous ? AppColors.coral : purple),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomProtocolSettings(
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
          Text(
            'Custom Protocol Settings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Fasting hours slider
          Text(
            'Fasting Hours: $_customFastingHours',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          Slider(
            value: _customFastingHours.toDouble(),
            min: 12,
            max: 72,
            divisions: 60,
            activeColor: purple,
            onChanged: (value) {
              setState(() {
                _customFastingHours = value.round();
                // Ensure eating hours + fasting hours = 24 for daily protocols
                if (_customFastingHours + _customEatingHours > 24 &&
                    _customFastingHours <= 24) {
                  _customEatingHours = 24 - _customFastingHours;
                }
              });
            },
          ),

          // Eating hours slider (only for protocols <= 24h)
          if (_customFastingHours <= 24) ...[
            const SizedBox(height: 8),
            Text(
              'Eating Hours: $_customEatingHours',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
            Slider(
              value: _customEatingHours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              activeColor: purple,
              onChanged: (value) {
                setState(() {
                  _customEatingHours = value.round();
                });
              },
            ),
          ],
        ],
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
          child: Column(
            children: [
              Row(
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Meal reminders
        Container(
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
              Row(
                children: [
                  Icon(Icons.restaurant, color: purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal Reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Get reminded when to eat during your eating window',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _mealRemindersEnabled,
                    onChanged: (v) => setState(() => _mealRemindersEnabled = v),
                    activeColor: purple,
                  ),
                ],
              ),
              if (_mealRemindersEnabled) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Lunch reminder time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lunch reminder',
                        style: TextStyle(fontSize: 14, color: textPrimary),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _lunchReminderHour,
                      dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                      style: TextStyle(color: purple, fontWeight: FontWeight.w600),
                      underline: const SizedBox(),
                      items: List.generate(6, (i) => i + 11).map((hour) {
                        return DropdownMenuItem(
                          value: hour,
                          child: Text(_formatHour(hour)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _lunchReminderHour = v ?? 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dinner reminder time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dinner reminder',
                        style: TextStyle(fontSize: 14, color: textPrimary),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _dinnerReminderHour,
                      dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                      style: TextStyle(color: purple, fontWeight: FontWeight.w600),
                      underline: const SizedBox(),
                      items: List.generate(6, (i) => i + 17).map((hour) {
                        return DropdownMenuItem(
                          value: hour,
                          child: Text(_formatHour(hour)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _dinnerReminderHour = v ?? 18),
                    ),
                  ],
                ),
              ],
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
                final displayHour = _formatHour(hour);
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

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getProtocolShortName(FastingProtocol protocol) {
    switch (protocol) {
      case FastingProtocol.twelve12:
        return '12:12';
      case FastingProtocol.fourteen10:
        return '14:10';
      case FastingProtocol.sixteen8:
        return '16:8';
      case FastingProtocol.eighteen6:
        return '18:6';
      case FastingProtocol.twenty4:
        return '20:4';
      case FastingProtocol.omad:
        return 'OMAD';
      case FastingProtocol.waterFast24:
        return '24h';
      case FastingProtocol.waterFast48:
        return '48h';
      case FastingProtocol.waterFast72:
        return '72h';
      case FastingProtocol.waterFast7Day:
        return '7-day';
      case FastingProtocol.fiveTwo:
        return '5:2';
      case FastingProtocol.adf:
        return 'ADF';
      case FastingProtocol.custom:
        return '';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      case 'expert':
        return AppColors.coral;
      default:
        return Colors.grey;
    }
  }

  void _setSafetyResponse(FastingSafetyQuestion question, bool value) {
    HapticService.light();
    setState(() {
      _safetyResponses[question.id] = value;
    });

    // Show warning popup if answering Yes to a sensitive question
    if (value && question.allowContinueWithWarning &&
        question.detailedExplanation != null) {
      _showSafetyWarningDialog(question);
    }
  }

  void _showSafetyWarningDialog(FastingSafetyQuestion question) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.coral, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Important Warning',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.detailedExplanation!,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (question.potentialRisks != null &&
                  question.potentialRisks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Potential Risks:',
                  style: TextStyle(
                    color: AppColors.coral,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...question.potentialRisks!.map((risk) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(color: AppColors.coral, fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          risk,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We strongly recommend consulting a healthcare provider before starting any fasting protocol.',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Go back and change answer to No
              setState(() {
                _safetyResponses[question.id] = false;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Go Back',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Acknowledge and continue
              setState(() {
                _acknowledgedWarnings.add(question.id);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
            ),
            child: const Text(
              'I Understand, Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDangerousProtocolWarning(FastingProtocol protocol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.coral, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Extended Fast Warning',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${protocol.displayName} is an advanced fasting protocol that requires careful medical supervision.',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before starting this protocol:',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWarningItem('Consult your doctor first'),
                  _buildWarningItem('Have experience with shorter fasts'),
                  _buildWarningItem('Monitor your health closely'),
                  _buildWarningItem('Stay hydrated with electrolytes'),
                  _buildWarningItem('Stop immediately if you feel unwell'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedProtocol = protocol);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
            ),
            child: const Text(
              'I Understand the Risks',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: AppColors.coral, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _skipOnboarding() {
    HapticService.light();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final purple = isDark ? AppColors.purple : AppColorsLight.purple;

        return AlertDialog(
          backgroundColor: elevated,
          title: Text(
            'Skip Setup?',
            style: TextStyle(color: textPrimary),
          ),
          content: Text(
            'You can always customize your fasting settings later in the app.',
            style: TextStyle(color: textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeOnboardingWithDefaults();
              },
              style: ElevatedButton.styleFrom(backgroundColor: purple),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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

      // Check if user has warnings that need acknowledgment
      for (final q in fastingSafetyQuestions) {
        if (_safetyResponses[q.id] == true &&
            q.allowContinueWithWarning &&
            !_acknowledgedWarnings.contains(q.id)) {
          _showSafetyWarningDialog(q);
          return;
        }
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboardingWithDefaults() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final preferences = FastingPreferences(
        userId: userId,
        defaultProtocol: '16:8',
        typicalFastStartHour: 20,
        typicalEatingStartHour: 12,
        notificationsEnabled: true,
        notifyZoneTransitions: true,
        notifyGoalReached: true,
        notifyEatingWindowEnd: true,
        notifyFastStartReminder: true,
        safetyScreeningCompleted: false,
        fastingOnboardingCompleted: true,
      );

      await ref.read(fastingProvider.notifier).completeOnboarding(
            userId: userId,
            preferences: preferences,
            safetyAcknowledgments: [],
          );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      // Determine protocol name
      String protocolName;
      int? customFasting;
      int? customEating;

      if (_selectedProtocol == FastingProtocol.custom) {
        protocolName = 'custom';
        customFasting = _customFastingHours;
        customEating = _customEatingHours;
      } else {
        protocolName = _selectedProtocol.displayName;
      }

      final preferences = FastingPreferences(
        userId: userId,
        defaultProtocol: protocolName,
        customFastingHours: customFasting,
        customEatingHours: customEating,
        typicalFastStartHour: _fastingStartHour,
        typicalEatingStartHour: _eatingStartHour,
        notificationsEnabled: _notificationsEnabled,
        notifyZoneTransitions: _notificationsEnabled,
        notifyGoalReached: _notificationsEnabled,
        notifyEatingWindowEnd: _notificationsEnabled,
        notifyFastStartReminder: _mealRemindersEnabled,
        safetyScreeningCompleted: true,
        safetyWarningsAcknowledged:
            _safetyResponses.entries.map((e) => '${e.key}:${e.value}').toList(),
        hasMedicalConditions: _acknowledgedWarnings.isNotEmpty,
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
