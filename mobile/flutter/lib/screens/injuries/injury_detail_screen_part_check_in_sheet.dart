part of 'injury_detail_screen.dart';


/// Bottom sheet for logging check-ins
class _CheckInSheet extends StatefulWidget {
  final Injury injury;
  final Function(int painLevel, String? notes) onSubmit;

  const _CheckInSheet({
    required this.injury,
    required this.onSubmit,
  });

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}


class _CheckInSheetState extends State<_CheckInSheet> {
  int _painLevel = 5;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _painLevel = widget.injury.painLevel ?? 5;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final painColor = _painLevel <= 3
        ? AppColors.success
        : _painLevel <= 6
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Daily Check-in',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How is your ${widget.injury.bodyPartDisplay.toLowerCase()} feeling today?',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Pain level selector
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_painLevel',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: painColor,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 20,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Slider(
                value: _painLevel.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: painColor,
                inactiveColor: painColor.withValues(alpha: 0.2),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _painLevel = value.round();
                  });
                },
              ),

              const SizedBox(height: 24),

              // Notes field
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Any notes about how it feels today...',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.coral, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          await widget.onSubmit(
                            _painLevel,
                            _notesController.text.isNotEmpty ? _notesController.text : null,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Log Check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

