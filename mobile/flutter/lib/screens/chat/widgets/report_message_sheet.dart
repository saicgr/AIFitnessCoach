import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Report categories for AI messages
enum ReportCategory {
  wrongAdvice('Wrong advice', Icons.error_outline),
  inappropriate('Inappropriate', Icons.block),
  unhelpful('Unhelpful', Icons.thumb_down_outlined),
  outdatedInfo('Outdated info', Icons.update),
  other('Other', Icons.more_horiz);

  final String label;
  final IconData icon;

  const ReportCategory(this.label, this.icon);
}

/// Bottom sheet for reporting an AI message
class ReportMessageSheet extends ConsumerStatefulWidget {
  final String? messageId;
  final String originalUserMessage;
  final String aiResponse;

  const ReportMessageSheet({
    super.key,
    this.messageId,
    required this.originalUserMessage,
    required this.aiResponse,
  });

  @override
  ConsumerState<ReportMessageSheet> createState() => _ReportMessageSheetState();
}

class _ReportMessageSheetState extends ConsumerState<ReportMessageSheet> {
  ReportCategory? _selectedCategory;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ClipRRect(
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report this response',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Help us improve our AI coach',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category selection label
              Text(
                'What\'s wrong with this response?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // Category chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? AppColors.error : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.error : textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      HapticService.selection();
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor: AppColors.error.withOpacity(0.15),
                    checkmarkColor: AppColors.error,
                    side: BorderSide(
                      color: isSelected ? AppColors.error.withOpacity(0.5) : cardBorder,
                    ),
                    backgroundColor: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
                    showCheckmark: false,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Reason text field
              Text(
                'Additional details (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell us more about the issue...',
                  hintStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
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
                    borderSide: BorderSide(color: AppColors.cyan, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: textSecondary),
                ),
                style: TextStyle(color: textPrimary),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Submit button
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _selectedCategory == null || _isSubmitting
                          ? null
                          : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        disabledBackgroundColor: AppColors.error.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) return;

    HapticService.medium();
    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.reportMessage(
        messageId: widget.messageId,
        category: _selectedCategory!.name,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        originalUserMessage: widget.originalUserMessage,
        aiResponse: widget.aiResponse,
      );

      if (!mounted) return;

      HapticService.success();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Report submitted. Thank you for your feedback!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to submit report: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Show the report message bottom sheet
void showReportMessageSheet(
  BuildContext context, {
  String? messageId,
  required String originalUserMessage,
  required String aiResponse,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    builder: (context) => ReportMessageSheet(
      messageId: messageId,
      originalUserMessage: originalUserMessage,
      aiResponse: aiResponse,
    ),
  );
}
