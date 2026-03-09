import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/repositories/auth_repository.dart';

/// Bottom sheet for creating a new fitness challenge (F8)
class CreateChallengeSheet extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;

  const CreateChallengeSheet({super.key, this.onCreated});

  @override
  ConsumerState<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalValueController = TextEditingController();
  final _goalUnitController = TextEditingController();

  String _challengeType = 'workout_count';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isPublic = true;
  bool _isSubmitting = false;

  static const _challengeTypes = {
    'workout_count': 'Workout Count',
    'workout_streak': 'Workout Streak',
    'total_volume': 'Total Volume',
    'weight_loss': 'Weight Loss',
    'step_count': 'Step Count',
    'custom': 'Custom',
  };

  static const _defaultUnits = {
    'workout_count': 'workouts',
    'workout_streak': 'days',
    'total_volume': 'lbs',
    'weight_loss': 'lbs',
    'step_count': 'steps',
    'custom': '',
  };

  @override
  void initState() {
    super.initState();
    _goalUnitController.text = _defaultUnits[_challengeType] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalValueController.dispose();
    _goalUnitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate : _endDate;
    final firstDate = isStart ? now : _startDate;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final socialService = ref.read(socialServiceProvider);

      // Create the challenge
      final challenge = await socialService.createChallenge(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        challengeType: _challengeType,
        goalValue: double.parse(_goalValueController.text.trim()),
        goalUnit: _goalUnitController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isPublic: _isPublic,
      );

      // Auto-join the creator
      final challengeId = challenge['id'] as String?;
      if (challengeId != null) {
        await socialService.joinChallenge(
          userId: userId,
          challengeId: challengeId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
      }
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challenge: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = ref.colors(context);
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Create Challenge',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Challenge Title *',
                        hintText: 'e.g., 30-Day Workout Streak',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Describe the challenge...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Challenge Type
                    DropdownButtonFormField<String>(
                      value: _challengeType,
                      decoration: InputDecoration(
                        labelText: 'Challenge Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _challengeTypes.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _challengeType = value;
                            _goalUnitController.text = _defaultUnits[value] ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Goal Value & Unit
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _goalValueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Goal Value *',
                              hintText: 'e.g., 30',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = double.tryParse(value.trim());
                              if (num == null || num <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _goalUnitController,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'e.g., workouts',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: 'Start Date',
                            date: dateFormat.format(_startDate),
                            onTap: () => _pickDate(isStart: true),
                            colors: colors,
                            cardBorder: cardBorder,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateButton(
                            label: 'End Date',
                            date: dateFormat.format(_endDate),
                            onTap: () => _pickDate(isStart: false),
                            colors: colors,
                            cardBorder: cardBorder,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Public/Private toggle
                    SwitchListTile(
                      title: const Text('Public Challenge'),
                      subtitle: Text(
                        _isPublic
                            ? 'Anyone can discover and join'
                            : 'Only invited users can join',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _isPublic = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.accentContrast,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.accentContrast,
                                ),
                              )
                            : const Text(
                                'Create Challenge',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    // Bottom safe area padding
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required String date,
    required VoidCallback onTap,
    required ThemeColors colors,
    required Color cardBorder,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: colors.accent),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
