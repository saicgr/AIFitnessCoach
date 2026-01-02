import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/support_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../models/support_ticket.dart';

/// Screen for creating a new support ticket
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.other;
  TicketPriority _selectedPriority = TicketPriority.medium;
  final List<File> _attachments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_attachments.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 attachments allowed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _attachments.add(File(image.path));
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create a ticket'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ticket = await ref.read(supportTicketsProvider.notifier).createTicket(
        subject: _subjectController.text.trim(),
        category: _selectedCategory.value,
        priority: _selectedPriority.value,
        description: _descriptionController.text.trim(),
        // Note: In a real app, you would upload attachments first and pass URLs
        attachments: null,
      );

      if (mounted) {
        // Show success dialog
        await _showSuccessDialog(ticket);
        context.go('/support-tickets');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showSuccessDialog(SupportTicket ticket) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ticket Created!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ticket number is',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.ticketNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our support team will respond within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got It',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Ticket',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject
            Text(
              'Subject',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Brief description of your issue',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: elevated,
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
                  borderSide: const BorderSide(color: AppColors.cyan),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                if (value.trim().length < 10) {
                  return 'Subject must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Category
            Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonFormField<TicketCategory>(
                initialValue: _selectedCategory,
                dropdownColor: elevated,
                style: TextStyle(color: textPrimary),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: InputBorder.none,
                ),
                items: TicketCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.displayName,
                      style: TextStyle(color: textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Priority
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: TicketPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                Color priorityColor;
                switch (priority) {
                  case TicketPriority.low:
                    priorityColor = AppColors.success;
                    break;
                  case TicketPriority.medium:
                    priorityColor = AppColors.warning;
                    break;
                  case TicketPriority.high:
                    priorityColor = AppColors.orange;
                    break;
                  case TicketPriority.urgent:
                    priorityColor = AppColors.error;
                    break;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = priority),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: priority != TicketPriority.urgent ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? priorityColor.withOpacity(0.15)
                            : elevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? priorityColor : cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priority.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? priorityColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: textPrimary),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe your issue in detail...',
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: elevated,
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
                  borderSide: const BorderSide(color: AppColors.cyan),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your issue';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Attachments
            Text(
              'Attachments (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add screenshots to help us understand your issue',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Attachment grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Existing attachments
                ..._attachments.asMap().entries.map((entry) {
                  return _AttachmentTile(
                    file: entry.value,
                    onRemove: () => _removeAttachment(entry.key),
                  );
                }),

                // Add button
                if (_attachments.length < 3)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cardBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
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
                    : const Text(
                        'Submit Ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Center(
              child: Text(
                'Our support team typically responds within 24 hours',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Attachment tile widget
class _AttachmentTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _AttachmentTile({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
