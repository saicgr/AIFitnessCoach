part of 'coach_selection_screen.dart';

/// UI builder methods extracted from _CoachSelectionScreenState
extension _CoachSelectionScreenStateUI on _CoachSelectionScreenState {

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, Color textPrimary, Color textSecondary, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCoachSummary(bool isDark, Color textPrimary, Color textSecondary) {
    final coach = _selectedCoach!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coach avatar + name row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coach.primaryColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: coach.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: coach.imagePath != null
                    ? Image.asset(
                        coach.imagePath!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          coach.icon,
                          color: coach.primaryColor,
                          size: 24,
                        ),
                      )
                    : Icon(
                        coach.icon,
                        color: coach.primaryColor,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingPresetName)
                    // Inline rename — preserves persona, only changes display name.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _renameController,
                            autofocus: true,
                            maxLength: 24,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              final v = _renameController.text.trim();
                              setState(() {
                                _renamedSelectedName = v.isEmpty ? null : v;
                                _editingPresetName = false;
                              });
                            },
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: coach.primaryColor,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              hintText: coach.name,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              filled: true,
                              fillColor:
                                  coach.primaryColor.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: coach.primaryColor
                                        .withValues(alpha: 0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: coach.primaryColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check,
                              color: coach.primaryColor, size: 22),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final v = _renameController.text.trim();
                            setState(() {
                              _renamedSelectedName = v.isEmpty ? null : v;
                              _editingPresetName = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: textSecondary, size: 22),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _editingPresetName = false;
                              _renameController.text =
                                  _renamedSelectedName ?? coach.name;
                            });
                          },
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _renameController.text =
                              _renamedSelectedName ?? coach.name;
                          _editingPresetName = true;
                        });
                      },
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _renamedSelectedName ?? coach.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: coach.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 14,
                              color: coach.primaryColor.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  Text(
                    coach.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Specialization
        Row(
          children: [
            Icon(Icons.star_rounded, size: 16, color: coach.primaryColor),
            const SizedBox(width: 6),
            Text(
              coach.specialization,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Personality badge
        Row(
          children: [
            Icon(Icons.psychology_rounded, size: 16, color: coach.primaryColor),
            const SizedBox(width: 6),
            Text(
              coach.personalityBadge,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Personality traits as chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: coach.personalityTraits.map((trait) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: coach.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: coach.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                trait,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: coach.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Encouragement level bar
        Row(
          children: [
            Text(
              'Energy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: coach.encouragementLevel,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(coach.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(coach.encouragementLevel * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: coach.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Sample message
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'How they talk',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                coach.sampleMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildHeaderOverlay(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassBackButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (widget.fromSettings) {
                    context.pop();
                  } else {
                    context.pop();
                  }
                },
              ),
              // Skip button (only during onboarding, not from settings)
              if (!widget.fromSettings)
                GestureDetector(
                  onTap: _skip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (!widget.fromSettings) _buildProgressIndicator(isDark),
        ],
      ),
    );
  }


  Widget _buildProgressIndicator(bool isDark) {
    final accentColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    const currentStep = 4; // Coach is step 5 (0-based: 4), all complete

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, accentColor, isDark, 0),
          _buildProgressLine(0, currentStep, accentColor, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, accentColor, isDark, 2),
          _buildProgressLine(1, currentStep, accentColor, inactiveColor, 3),
          _buildStepDot(3, 'Split', true, accentColor, isDark, 4),
          _buildProgressLine(2, currentStep, accentColor, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', true, accentColor, isDark, 6),
          _buildProgressLine(3, currentStep, accentColor, inactiveColor, 7),
          _buildStepDot(5, 'Coach', true, accentColor, isDark, 8),
        ],
      ),
    );
  }


  Widget _buildProgressLine(int segmentIndex, int currentStep, Color activeColor, Color inactiveColor, int animOrder) {
    final isComplete = segmentIndex < currentStep;
    final delay = 100 + (animOrder * 80);

    return Expanded(
      child: Container(
        height: 2,
        color: inactiveColor,
        child: isComplete
            ? Container(height: 2, color: activeColor)
                .animate()
                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft,
                    delay: Duration(milliseconds: delay), duration: 300.ms,
                    curve: Curves.easeOut)
            : null,
      ),
    );
  }


  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark, int animOrder) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final delay = 100 + (animOrder * 80);

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? activeColor : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? activeColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ).animate()
         .scaleXY(begin: 0, end: 1, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }


  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon or coach avatar (back button is in headerOverlay)
            if (!widget.fromSettings) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: coachColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fromSettings ? 'Change Coach' : 'Meet Your Coach',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.fromSettings
                        ? 'Select a new AI coach persona'
                        : 'You can always change this later',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }


  /// Compact custom coach toggle for use below the PageView
  Widget _buildCompactCustomToggle(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);

    return GestureDetector(
      onTap: _showCustomCoachPreview,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: coachColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Create Your Own Coach',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }


  Widget _buildContinueButton(bool isDark, bool canContinue) {
    final isEnabled = canContinue && !_isLoading;
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite).withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isEnabled ? _continue : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? coachColor : (isDark ? AppColors.elevated : AppColorsLight.elevated),
              borderRadius: BorderRadius.circular(14),
              border: isEnabled
                  ? null
                  : Border.all(
                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    ),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.fromSettings ? 'Save Coach' : 'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? Colors.white
                                : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          widget.fromSettings ? Icons.check : Icons.arrow_forward,
                          size: 20,
                          color: isEnabled
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ),
    );
  }

}
