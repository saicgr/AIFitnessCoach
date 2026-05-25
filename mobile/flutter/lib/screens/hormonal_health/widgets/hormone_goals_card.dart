import 'package:flutter/material.dart';
import '../../../data/models/hormonal_health.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card displaying user's hormone optimization goals
class HormoneGoalsCard extends StatelessWidget {
  final List<HormoneGoal> goals;
  final VoidCallback? onEditGoals;

  const HormoneGoalsCard({
    super.key,
    required this.goals,
    this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (goals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).hormoneGoalsCardNoHormoneGoalsSet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: onEditGoals,
                child: Text(AppLocalizations.of(context).hormoneGoalsCardSetGoals),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).nutritionSettingsScreenYourGoals,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (onEditGoals != null)
                  TextButton(
                    onPressed: onEditGoals,
                    child: Text(AppLocalizations.of(context).commonEdit),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals.map((goal) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(goal.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        goal.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
