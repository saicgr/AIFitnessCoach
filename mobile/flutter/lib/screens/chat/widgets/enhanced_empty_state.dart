import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';

class EnhancedEmptyState extends StatelessWidget {
  final CoachPersona coach;
  final void Function(String prompt) onSuggestionTap;

  const EnhancedEmptyState({
    super.key,
    required this.coach,
    required this.onSuggestionTap,
  });

  static const _suggestions = <(String, IconData, Color)>[
    ('Quick 15-min workout', Icons.flash_on_outlined, Color(0xFF06B6D4)),
    ('Pre-workout meal ideas', Icons.restaurant_outlined, Color(0xFF22C55E)),
    ('Improve my squat form', Icons.self_improvement_outlined, Color(0xFFF97316)),
    ('High-protein meal prep', Icons.lunch_dining_outlined, Color(0xFFA855F7)),
    ('Should I work out tired?', Icons.bedtime_outlined, Color(0xFF3B82F6)),
    ('Lower back pain help', Icons.healing_outlined, Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Coach avatar with glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CoachAvatar(
              coach: coach,
              size: 88,
              showBorder: true,
              borderWidth: 3,
              showShadow: false,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            coach.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            coach.tagline.isNotEmpty ? coach.tagline : 'Your personal fitness assistant',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Suggestion chips section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TRY ASKING...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              final (text, icon, color) = s;
              return _CompactChip(
                text: text,
                icon: icon,
                color: color,
                isDark: isDark,
                colors: colors,
                onTap: () {
                  HapticService.selection();
                  onSuggestionTap(text);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _CompactChip({
    required this.text,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
