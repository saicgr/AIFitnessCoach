import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Dialog shown when user tries to quit a challenge workout midway
/// Uses provocative language to motivate completion
class ChallengeQuitDialog extends StatefulWidget {
  final String challengerName;
  final String workoutName;
  final VoidCallback onContinue;
  final Function(String quitReason) onConfirmQuit;

  const ChallengeQuitDialog({
    super.key,
    required this.challengerName,
    required this.workoutName,
    required this.onContinue,
    required this.onConfirmQuit,
  });

  @override
  State<ChallengeQuitDialog> createState() => _ChallengeQuitDialogState();
}

class _ChallengeQuitDialogState extends State<ChallengeQuitDialog>
    with SingleTickerProviderStateMixin {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _showCustomInput = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Embarrassing quick reply options to discourage quitting
  final List<Map<String, dynamic>> _quitReasons = [
    {
      'text': 'Too hard for me 😓',
      'value': 'too_hard',
      'color': Colors.red,
    },
    {
      'text': 'Not feeling it today 😴',
      'value': 'not_motivated',
      'color': Colors.orange,
    },
    {
      'text': 'This is impossible 😭',
      'value': 'too_difficult',
      'color': Colors.red,
    },
    {
      'text': 'I give up 🏳️',
      'value': 'gave_up',
      'color': Colors.grey,
    },
    {
      'text': 'Maybe next time 😅',
      'value': 'postpone',
      'color': Colors.orange,
    },
    {
      'text': 'I\'m not ready yet 🙈',
      'value': 'not_ready',
      'color': Colors.orange,
    },
    {
      'text': 'Custom reason...',
      'value': 'custom',
      'color': AppColors.textMuted,
    },
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value * ((_shakeController.value * 2) - 1).sign, 0),
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Provocative header
              _buildHeader(context),

              // Challenge reminder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildChallengeReminder(context),
              ),

              const SizedBox(height: 20),

              // Quick reply reasons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickReplies(context),
              ),

              // Custom reason input (if selected)
              if (_showCustomInput) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCustomReasonInput(context, isDark),
                ),
              ],

              const SizedBox(height: 20),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Chicken emoji
          const Text(
            '🐔',
            style: TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 12),

          // Provocative title
          const Text(
            'CHICKENING OUT?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Really? You\'re giving up on the challenge?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeReminder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                    children: [
                      TextSpan(
                        text: widget.challengerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' challenged you to '),
                      TextSpan(
                        text: widget.workoutName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'They\'ll see your excuse if you quit!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick your excuse:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quitReasons.map((reason) {
            final isSelected = _selectedReason == reason['value'];
            final isCustom = reason['value'] == 'custom';

            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedReason = reason['value'] as String;
                  _showCustomInput = isCustom;
                });
                if (!isCustom) {
                  _shake(); // Shake dialog when they select an embarrassing reason
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (reason['color'] as Color).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (reason['color'] as Color)
                        : AppColors.cardBorder.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  reason['text'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? (reason['color'] as Color) : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomReasonInput(BuildContext context, bool isDark) {
    return TextField(
      controller: _customReasonController,
      maxLength: 100,
      maxLines: 2,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Type your excuse here... (they\'ll see this)',
        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: isDark ? AppColors.background : AppColorsLight.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Continue workout button (prominent)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              widget.onContinue();
            },
            icon: const Icon(Icons.fitness_center, size: 20),
            label: const Text(
              'KEEP GOING! 💪',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Quit button (less prominent)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _selectedReason == null
                ? null
                : () {
                    HapticFeedback.lightImpact();

                    final quitReason = _selectedReason == 'custom'
                        ? _customReasonController.text.trim()
                        : _quitReasons.firstWhere((r) => r['value'] == _selectedReason)['text'] as String;

                    if (quitReason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reason'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    widget.onConfirmQuit(quitReason);
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: _selectedReason != null
                    ? Colors.red.withValues(alpha: 0.5)
                    : AppColors.cardBorder.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _selectedReason == null ? 'Select a reason to quit' : 'Yes, I quit 🏳️',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
