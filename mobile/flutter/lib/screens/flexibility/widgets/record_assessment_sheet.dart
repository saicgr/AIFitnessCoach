import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/flexibility_assessment.dart';
import '../../../data/providers/flexibility_provider.dart';

/// Bottom sheet for recording a new flexibility assessment
class RecordAssessmentSheet extends ConsumerStatefulWidget {
  final FlexibilityTest test;
  final String userId;

  const RecordAssessmentSheet({
    super.key,
    required this.test,
    required this.userId,
  });

  @override
  ConsumerState<RecordAssessmentSheet> createState() => _RecordAssessmentSheetState();
}

class _RecordAssessmentSheetState extends ConsumerState<RecordAssessmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _measurementController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isRecording = false;

  @override
  void dispose() {
    _measurementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Assessment',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.test.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions Preview
                      if (widget.test.instructions.isNotEmpty) ...[
                        Text(
                          'Quick Instructions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.test.instructions.take(4).map((instruction) {
                              final index = widget.test.instructions.indexOf(instruction);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        instruction,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Measurement Input
                      Text(
                        'Your Measurement',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _measurementController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter measurement',
                          suffixText: widget.test.unit,
                          border: const OutlineInputBorder(),
                          helperText: _getHelperText(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a measurement';
                          }
                          final number = double.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        autofocus: true,
                      ),
                      const SizedBox(height: 20),

                      // Notes Input
                      Text(
                        'Notes (Optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Any notes about this assessment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tips
                      if (widget.test.tips.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.test.tips.take(2).map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\u2022 ',
                                style: TextStyle(color: Colors.amber.shade700),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRecording ? null : _submitAssessment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRecording
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Assessment'),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _getHelperText() {
    if (widget.test.higherIsBetter) {
      return 'Higher values indicate better flexibility';
    } else {
      return 'Lower values indicate better flexibility';
    }
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRecording = true);

    final measurement = double.parse(_measurementController.text);
    final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

    final response = await ref.read(flexibilityProvider.notifier).recordAssessment(
      testType: widget.test.id,
      measurement: measurement,
      notes: notes,
      userId: widget.userId,
    );

    setState(() => _isRecording = false);

    if (response != null && mounted) {
      Navigator.pop(context);
      _showResultSnackbar(response);
    }
  }

  void _showResultSnackbar(RecordAssessmentResponse response) {
    final theme = Theme.of(context);
    final rating = response.assessment.rating ?? 'fair';
    final color = _getRatingColor(rating);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  response.isImprovement ? Icons.trending_up : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rating.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (response.assessment.percentile != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Top ${100 - response.assessment.percentile!}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: response.ratingImproved
            ? Colors.green.shade700
            : theme.colorScheme.primary,
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
