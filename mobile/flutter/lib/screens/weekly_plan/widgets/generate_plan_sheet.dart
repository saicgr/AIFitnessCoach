import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../data/providers/guest_mode_provider.dart';
import '../../../data/providers/guest_usage_limits_provider.dart';
import '../../../data/providers/weekly_plan_provider.dart';
import '../../../widgets/guest_upgrade_sheet.dart';

/// Bottom sheet for generating a new weekly plan
class GeneratePlanSheet extends ConsumerStatefulWidget {
  const GeneratePlanSheet({super.key});

  @override
  ConsumerState<GeneratePlanSheet> createState() => _GeneratePlanSheetState();
}

class _GeneratePlanSheetState extends ConsumerState<GeneratePlanSheet> {
  final Set<int> _selectedDays = {0, 1, 3, 4}; // Mon, Tue, Thu, Fri default
  String? _fastingProtocol = '16:8';
  NutritionStrategy _nutritionStrategy = NutritionStrategy.workoutAware;
  String _preferredTime = '17:00';

  final List<String> _fastingOptions = [
    'None',
    '12:12',
    '14:10',
    '16:8',
    '18:6',
    '20:4',
    'OMAD',
  ];

  final List<String> _timeOptions = [
    '06:00',
    '07:00',
    '08:00',
    '12:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _generatePlan() async {
    // Check guest mode limits
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canGenerate = await ref.read(guestUsageLimitsProvider.notifier).useWorkoutGeneration();
      if (!canGenerate) {
        // Show upgrade prompt when limit reached
        if (mounted) {
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.workout);
        }
        return;
      }
    }

    final navigator = Navigator.of(context);

    final plan = await ref.read(weeklyPlanProvider.notifier).generatePlan(
          workoutDays: _selectedDays.toList()..sort(),
          fastingProtocol:
              _fastingProtocol == 'None' ? null : _fastingProtocol,
          nutritionStrategy: _nutritionStrategy.name,
          preferredWorkoutTime: _preferredTime,
        );

    if (plan != null && mounted) {
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly plan generated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(weeklyPlanProvider);
    final isGenerating = planState.isGenerating;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Generate Weekly Plan',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a holistic plan that coordinates your workouts, nutrition, and fasting.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                // Workout Days Selection
                Text(
                  'Training Days',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDaySelector(colorScheme),
                const SizedBox(height: 24),

                // Fasting Protocol
                Text(
                  'Fasting Protocol',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFastingSelector(colorScheme),
                const SizedBox(height: 24),

                // Nutrition Strategy
                Text(
                  'Nutrition Strategy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNutritionStrategySelector(colorScheme),
                const SizedBox(height: 24),

                // Preferred Workout Time
                Text(
                  'Preferred Workout Time',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeSelector(colorScheme),
                const SizedBox(height: 32),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        isGenerating || _selectedDays.isEmpty ? null : _generatePlan,
                    icon: isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(isGenerating ? 'Generating...' : 'Generate Plan'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                // Error message
                if (planState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            planState.error!,
                            style:
                                TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaySelector(ColorScheme colorScheme) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (_) => _toggleDay(index),
          showCheckmark: false,
          selectedColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color:
                isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  Widget _buildFastingSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fastingOptions.map((protocol) {
        final isSelected = _fastingProtocol == protocol;
        return ChoiceChip(
          label: Text(protocol),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _fastingProtocol = protocol;
            });
          },
          selectedColor: colorScheme.secondaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionStrategySelector(ColorScheme colorScheme) {
    return Column(
      children: NutritionStrategy.values.map((strategy) {
        final isSelected = _nutritionStrategy == strategy;
        return RadioListTile<NutritionStrategy>(
          value: strategy,
          groupValue: _nutritionStrategy,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _nutritionStrategy = value;
              });
            }
          },
          title: Text(strategy.displayName),
          subtitle: Text(
            strategy.description,
            style: theme.textTheme.bodySmall,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeOptions.map((time) {
        final isSelected = _preferredTime == time;
        return ChoiceChip(
          label: Text(time),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _preferredTime = time;
            });
          },
          selectedColor: colorScheme.tertiaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  ThemeData get theme => Theme.of(context);
}
