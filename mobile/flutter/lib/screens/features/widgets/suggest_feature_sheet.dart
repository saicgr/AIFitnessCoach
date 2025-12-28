import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/feature_provider.dart';

/// Bottom sheet for users to suggest new features
class SuggestFeatureSheet extends ConsumerStatefulWidget {
  const SuggestFeatureSheet({super.key});

  @override
  ConsumerState<SuggestFeatureSheet> createState() =>
      _SuggestFeatureSheetState();
}

class _SuggestFeatureSheetState extends ConsumerState<SuggestFeatureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'workout';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'workout', 'label': 'Workout', 'icon': Icons.fitness_center},
    {'value': 'social', 'label': 'Social', 'icon': Icons.people},
    {'value': 'analytics', 'label': 'Analytics', 'icon': Icons.bar_chart},
    {'value': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant},
    {'value': 'coaching', 'label': 'Coaching', 'icon': Icons.psychology},
    {'value': 'ui_ux', 'label': 'UI/UX', 'icon': Icons.design_services},
    {'value': 'integration', 'label': 'Integration', 'icon': Icons.extension},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingAsync = ref.watch(remainingSubmissionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Suggest a Feature',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Remaining submissions info
                remainingAsync.when(
                  data: (data) {
                    final remaining = data['remaining'] as int;
                    final used = data['used'] as int;

                    if (remaining == 0) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'ve used all $used of your $used suggestions. Vote on existing features instead!',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Text(
                      'You have $remaining ${remaining == 1 ? "suggestion" : "suggestions"} remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Feature Title',
                    hintText: 'e.g., Social workout sharing',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 10) {
                      return 'Title must be at least 10 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your feature idea in detail...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category selector
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['value'];
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData, size: 16),
                          const SizedBox(width: 4),
                          Text(cat['label'] as String),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat['value'] as String);
                      },
                      selectedColor: const Color(0xFF00D9FF).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF00D9FF),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
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
                            'Submit Suggestion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Check remaining submissions first
    final remainingData = await ref.read(remainingSubmissionsProvider.future);
    if (remainingData['remaining'] == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have reached the maximum of 2 feature suggestions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(featuresProvider.notifier).createFeature(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
          );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature suggestion submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh remaining submissions count
      ref.invalidate(remainingSubmissionsProvider);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
