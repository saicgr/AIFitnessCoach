/// Rest Suggestion Card Widget
///
/// Displays an AI-powered rest time suggestion during the rest period.
/// Features a glassmorphic design matching the app's futuristic aesthetic.
/// Shows suggested rest time, reasoning, and quick option buttons.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/rest_suggestion.dart';

/// Glassmorphic card displaying AI rest time suggestion
class RestSuggestionCard extends StatelessWidget {
  /// The rest suggestion from AI
  final RestSuggestion suggestion;

  /// Callback when user accepts the suggested rest time
  final ValueChanged<int> onAcceptSuggestion;

  /// Callback when user chooses the quick rest option
  final ValueChanged<int> onQuickRest;

  /// Callback when user dismisses the suggestion
  final VoidCallback? onDismiss;

  /// Whether the card is in a compact mode (for small screens)
  final bool isCompact;

  const RestSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAcceptSuggestion,
    required this.onQuickRest,
    this.onDismiss,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    // Determine accent color based on rest category
    final accentColor = _getCategoryColor(suggestion.category, isDark);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AI badge and dismiss button
              _buildHeader(isDark, accentColor),

              SizedBox(height: isCompact ? 8 : 12),

              // Main suggestion display
              _buildSuggestionDisplay(isDark, accentColor, isSmallScreen),

              SizedBox(height: isCompact ? 8 : 12),

              // Reasoning text
              _buildReasoning(isDark),

              SizedBox(height: isCompact ? 12 : 16),

              // Action buttons
              _buildActionButtons(isDark, accentColor, isSmallScreen),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildHeader(bool isDark, Color accentColor) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final bgOpacity = isDark ? 0.2 : 0.15;
    return Row(
      children: [
        // Timer icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.timer_outlined,
            color: accentColor,
            size: isCompact ? 18 : 20,
          ),
        ),
        const SizedBox(width: 10),
        // Title and AI badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI REST COACH',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                  if (suggestion.aiPowered) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: purple.withOpacity(bgOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: purple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                suggestion.categoryLabel,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Dismiss button
        if (onDismiss != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDismiss?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionDisplay(
    bool isDark,
    Color accentColor,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Suggested time
          Column(
            children: [
              Text(
                suggestion.suggestedDisplay,
                style: TextStyle(
                  fontSize: isSmallScreen ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SUGGESTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          // Time saved indicator (if quick option available)
          if (suggestion.hasQuickOption) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 1,
                height: 50,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
            ),
            Column(
              children: [
                Text(
                  suggestion.quickOptionDisplay,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'QUICK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasoning(bool isDark) {
    return Text(
      suggestion.reasoning,
      style: TextStyle(
        fontSize: isCompact ? 13 : 14,
        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButtons(
    bool isDark,
    Color accentColor,
    bool isSmallScreen,
  ) {
    return Row(
      children: [
        // Quick Rest button (if available)
        if (suggestion.hasQuickOption)
          Expanded(
            child: _buildActionButton(
              label: 'Quick Rest',
              sublabel: 'Save ${suggestion.timeSavedDisplay}',
              icon: Icons.fast_forward,
              color: isDark ? Colors.white24 : Colors.black12,
              textColor: isDark ? Colors.white70 : Colors.black54,
              onTap: () {
                HapticFeedback.mediumImpact();
                onQuickRest(suggestion.quickOptionSeconds);
              },
              isOutlined: true,
              isDark: isDark,
              isSmallScreen: isSmallScreen,
            ),
          ),
        if (suggestion.hasQuickOption)
          SizedBox(width: isCompact ? 8 : 12),
        // Use Suggested button
        Expanded(
          flex: suggestion.hasQuickOption ? 1 : 2,
          child: _buildActionButton(
            label: 'Use Suggested',
            sublabel: suggestion.suggestedDisplay,
            icon: Icons.check,
            color: accentColor,
            textColor: Colors.white,
            onTap: () {
              HapticFeedback.mediumImpact();
              onAcceptSuggestion(suggestion.suggestedSeconds);
            },
            isOutlined: false,
            isDark: isDark,
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    required bool isOutlined,
    required bool isDark,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1.5,
                )
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 16 : 18,
              color: textColor,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: textColor.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(RestCategory category, bool isDark) {
    Color baseColor;
    switch (category) {
      case RestCategory.short:
        baseColor = AppColors.cyan;
      case RestCategory.moderate:
        baseColor = AppColors.success;
      case RestCategory.long:
        baseColor = AppColors.orange;
      case RestCategory.extended:
        baseColor = AppColors.purple;
    }
    return isDark ? baseColor : _darkenColor(baseColor);
  }

  /// Darken a color for better visibility in light mode
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}

/// Loading state for rest suggestion card
class RestSuggestionLoadingCard extends StatelessWidget {
  final bool isCompact;

  const RestSuggestionLoadingCard({
    super.key,
    this.isCompact = false,
  });

  /// Darken a color for better visibility in light mode
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
    final bgOpacity = isDark ? 0.2 : 0.15;
    final borderOpacity = isDark ? 0.3 : 0.4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cyan.withOpacity(borderOpacity),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(bgOpacity),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(cyan),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI REST COACH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cyan,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculating optimal rest time...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
