import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Common custom goals suggestions for the quiz
const List<String> suggestedCustomGoals = [
  'Improve box jump height',
  'Do my first pull-up',
  'Run a 5K',
  'Increase vertical leap',
  'Master handstand',
  'Improve flexibility',
  'Sprint faster',
  'Build explosive power',
];

/// Widget for adding custom training goals in onboarding
class QuizCustomGoals extends StatefulWidget {
  /// Currently entered custom goals
  final List<String> customGoals;

  /// Callback when goals change
  final ValueChanged<List<String>> onGoalsChanged;

  /// Whether the widget is disabled
  final bool disabled;

  const QuizCustomGoals({
    super.key,
    required this.customGoals,
    required this.onGoalsChanged,
    this.disabled = false,
  });

  @override
  State<QuizCustomGoals> createState() => _QuizCustomGoalsState();
}

class _QuizCustomGoalsState extends State<QuizCustomGoals> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = true;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addGoal(String goal) {
    if (goal.trim().isEmpty) return;
    if (widget.customGoals.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 custom goals allowed'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final trimmedGoal = goal.trim();
    if (!widget.customGoals.contains(trimmedGoal)) {
      widget.onGoalsChanged([...widget.customGoals, trimmedGoal]);
    }
    _controller.clear();
    setState(() => _showSuggestions = false);
  }

  void _removeGoal(String goal) {
    widget.onGoalsChanged(
      widget.customGoals.where((g) => g != goal).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter suggestions to exclude already added goals
    final availableSuggestions = suggestedCustomGoals
        .where((s) => !widget.customGoals.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.flag_outlined,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom Goals',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Any specific skills you want to improve?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Text input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !widget.disabled,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g., "Improve box jump height"',
            hintStyle: TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.accent),
              onPressed: widget.disabled
                  ? null
                  : () => _addGoal(_controller.text),
            ),
          ),
          onSubmitted: widget.disabled ? null : _addGoal,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),

        // Suggestions
        if (_showSuggestions && availableSuggestions.isNotEmpty) ...[
          Text(
            'Suggestions',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSuggestions.take(6).map((suggestion) {
              return InkWell(
                onTap: widget.disabled ? null : () => _addGoal(suggestion),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Added goals
        if (widget.customGoals.isNotEmpty) ...[
          Text(
            'Your Goals',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.customGoals.map((goal) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      goal,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: widget.disabled ? null : () => _removeGoal(goal),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        // Info text
        if (widget.customGoals.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Skip if you don\'t have specific skills in mind',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
