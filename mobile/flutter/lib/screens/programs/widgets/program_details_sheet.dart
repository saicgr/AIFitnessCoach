import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/branded_program.dart';
import '../../../data/providers/branded_program_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet showing detailed program info with option to start
class ProgramDetailsSheet extends ConsumerStatefulWidget {
  final BrandedProgram program;

  const ProgramDetailsSheet({
    super.key,
    required this.program,
  });

  @override
  ConsumerState<ProgramDetailsSheet> createState() =>
      _ProgramDetailsSheetState();
}

class _ProgramDetailsSheetState extends ConsumerState<ProgramDetailsSheet> {
  final TextEditingController _customNameController = TextEditingController();
  bool _useCustomName = false;

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String? category, bool isDark) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _startProgram() async {
    HapticService.medium();

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to start a program'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final customName = _useCustomName && _customNameController.text.isNotEmpty
        ? _customNameController.text.trim()
        : null;

    final success = await ref.read(currentProgramProvider.notifier).assignProgram(
          programId: widget.program.id,
          customName: customName,
          userId: userId,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started "${customName ?? widget.program.name}"!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start program. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground =
        isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final categoryColor = _getCategoryColor(widget.program.category, isDark);

    final isAssigning = ref.watch(isProgramAssigningProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
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
            child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Hero area with icon
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.3),
                      categoryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isDark
                      ? null
                      : Border.all(color: AppColorsLight.cardBorder),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getCategoryIcon(widget.program.category),
                        size: 64,
                        color: categoryColor,
                      ),
                    ),
                    // Featured badge
                    if (widget.program.isFeatured == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: AppColors.yellow),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.yellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.program.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Celebrity name if present
              if (widget.program.celebrityName != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Inspired by ${widget.program.celebrityName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(
                      icon: _getCategoryIcon(widget.program.category),
                      label: 'Category',
                      value: widget.program.category ?? 'Program',
                      color: categoryColor,
                      isDark: isDark,
                    ),
                    if (widget.program.difficultyLevel != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: DifficultyUtils.getDisplayName(widget.program.difficultyLevel!),
                        color: DifficultyUtils.getColor(widget.program.difficultyLevel!),
                        isDark: isDark,
                      ),
                    if (widget.program.durationWeeks != null)
                      _DetailBadge(
                        icon: Icons.calendar_today,
                        label: 'Duration',
                        value: '${widget.program.durationWeeks} weeks',
                        color: cyan,
                        isDark: isDark,
                      ),
                    if (widget.program.sessionsPerWeek != null)
                      _DetailBadge(
                        icon: Icons.repeat,
                        label: 'Sessions',
                        value: '${widget.program.sessionsPerWeek}/week',
                        color: cyan,
                        isDark: isDark,
                      ),
                    if (widget.program.sessionDurationMinutes != null)
                      _DetailBadge(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: '${widget.program.sessionDurationMinutes} min',
                        color: cyan,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),

              // Description
              if (widget.program.description != null &&
                  widget.program.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.program.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Goals
              if (widget.program.goals != null &&
                  widget.program.goals!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOALS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.program.goals!.map((goal) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: cyan,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cyan,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              if (widget.program.tags != null &&
                  widget.program.tags!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.program.tags!.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(16),
                              border: isDark
                                  ? null
                                  : Border.all(
                                      color: AppColorsLight.cardBorder),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Custom name toggle and input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() {
                          _useCustomName = !_useCustomName;
                        });
                      },
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _useCustomName
                                  ? cyan
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _useCustomName ? cyan : textMuted,
                                width: 2,
                              ),
                            ),
                            child: _useCustomName
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Give it a custom name',
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_useCustomName) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? null
                              : Border.all(color: AppColorsLight.cardBorder),
                        ),
                        child: TextField(
                          controller: _customNameController,
                          decoration: InputDecoration(
                            hintText: 'e.g., My Strength Journey',
                            hintStyle: TextStyle(color: textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Start Program button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAssigning ? null : _startProgram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: cyan.withOpacity(0.5),
                    ),
                    child: isAssigning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Start This Program',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail badge widget
class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
