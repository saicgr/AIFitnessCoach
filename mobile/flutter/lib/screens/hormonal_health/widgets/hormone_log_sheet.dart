import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/repositories/hormonal_health_repository.dart';
import '../../../core/providers/user_provider.dart';

/// Bottom sheet for logging daily hormone-related metrics
class HormoneLogSheet extends ConsumerStatefulWidget {
  const HormoneLogSheet({super.key});

  @override
  ConsumerState<HormoneLogSheet> createState() => _HormoneLogSheetState();
}

class _HormoneLogSheetState extends ConsumerState<HormoneLogSheet> {
  int? _energyLevel;
  int? _sleepQuality;
  int? _stressLevel;
  int? _libidoLevel;
  int? _motivationLevel;
  Mood? _mood;
  final Set<Symptom> _symptoms = {};
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                child: Row(
                  children: [
                    Text(
                      'Daily Check-in',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSliderSection(
                      'Energy Level',
                      Icons.bolt,
                      _energyLevel,
                      (val) => setState(() => _energyLevel = val),
                    ),
                    _buildSliderSection(
                      'Sleep Quality',
                      Icons.bedtime,
                      _sleepQuality,
                      (val) => setState(() => _sleepQuality = val),
                    ),
                    _buildSliderSection(
                      'Stress Level',
                      Icons.psychology,
                      _stressLevel,
                      (val) => setState(() => _stressLevel = val),
                    ),
                    _buildSliderSection(
                      'Libido',
                      Icons.favorite,
                      _libidoLevel,
                      (val) => setState(() => _libidoLevel = val),
                    ),
                    _buildSliderSection(
                      'Motivation',
                      Icons.fitness_center,
                      _motivationLevel,
                      (val) => setState(() => _motivationLevel = val),
                    ),
                    const SizedBox(height: 16),

                    // Mood Selection
                    Text('Mood', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Mood.values.map((mood) {
                        final isSelected = _mood == mood;
                        return FilterChip(
                          label: Text(_getMoodLabel(mood)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _mood = mood),
                          avatar: Text(_getMoodEmoji(mood)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Symptoms Selection
                    Text('Symptoms', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Symptom.values.map((symptom) {
                        final isSelected = _symptoms.contains(symptom);
                        return FilterChip(
                          label: Text(symptom.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _symptoms.remove(symptom);
                              } else {
                                _symptoms.add(symptom);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'How are you feeling today?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submitLog,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isLoading ? 'Saving...' : 'Save Check-in'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderSection(
    String label,
    IconData icon,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              if (value != null)
                Text(
                  '$value/10',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('1', style: theme.textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: value?.toDouble() ?? 5,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (val) => onChanged(val.round()),
                ),
              ),
              Text('10', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  String _getMoodLabel(Mood mood) {
    return mood.toString().split('.').last.replaceAll('_', ' ');
  }

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.excellent:
        return '😄';
      case Mood.good:
        return '🙂';
      case Mood.stable:
        return '😐';
      case Mood.low:
        return '😔';
      case Mood.irritable:
        return '😤';
      case Mood.anxious:
        return '😰';
      case Mood.depressed:
        return '😢';
    }
  }

  Future<void> _submitLog() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final logData = <String, dynamic>{
        'log_date': DateTime.now().toIso8601String().split('T')[0],
        if (_energyLevel != null) 'energy_level': _energyLevel,
        if (_sleepQuality != null) 'sleep_quality': _sleepQuality,
        if (_stressLevel != null) 'stress_level': _stressLevel,
        if (_libidoLevel != null) 'libido_level': _libidoLevel,
        if (_motivationLevel != null) 'motivation_level': _motivationLevel,
        if (_mood != null) 'mood': _mood.toString().split('.').last,
        if (_symptoms.isNotEmpty)
          'symptoms': _symptoms.map((s) => s.toString().split('.').last).toList(),
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
      };

      final repository = ref.read(hormonalHealthRepositoryProvider);
      await repository.createLog(user.id, logData);

      ref.invalidate(todayHormoneLogProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
