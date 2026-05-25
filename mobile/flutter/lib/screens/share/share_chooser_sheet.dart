import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'share_routing_table.dart';

/// Modal bottom sheet that lets the user pick the destination manually.
///
/// Shown when the classifier's confidence is low, when the user taps
/// "Change" on the auto-route countdown card, or when they long-press an
/// Imports row → Reclassify.
class ShareChooserSheet extends ConsumerWidget {
  const ShareChooserSheet({
    super.key,
    required this.predictedDestination,
    required this.onPick,
    this.predictionLabel,
    this.predictionWhy,
  });

  final ShareDestination predictedDestination;
  final void Function(ShareDestination dest) onPick;
  final String? predictionLabel;
  final String? predictionWhy;

  static Future<ShareDestination?> show(
    BuildContext context, {
    required ShareDestination predicted,
    String? predictionLabel,
    String? predictionWhy,
  }) {
    return showModalBottomSheet<ShareDestination>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ShareChooserSheet(
        predictedDestination: predicted,
        predictionLabel: predictionLabel,
        predictionWhy: predictionWhy,
        onPick: (dest) => Navigator.of(ctx).pop(dest),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final primary = <_ChipSpec>[
      _ChipSpec(ShareDestination.logFood,            'Log food',        Icons.restaurant),
      _ChipSpec(ShareDestination.importRecipePaste,  'Save recipe',     Icons.menu_book),
      _ChipSpec(ShareDestination.formCheck,          'Check form',      Icons.video_camera_back),
      _ChipSpec(ShareDestination.chat,               'Ask coach',       Icons.chat_bubble_outline),
    ];

    final secondary = <_ChipSpec>[
      _ChipSpec(ShareDestination.scanMenu,           'Scan menu',          Icons.menu),
      _ChipSpec(ShareDestination.progressUpload,     'Log progress',       Icons.photo_camera),
      _ChipSpec(ShareDestination.importEquipment,    'Import equipment',   Icons.fitness_center),
      _ChipSpec(ShareDestination.scanNutritionLabel, 'Nutrition label',    Icons.label_important_outline),
      _ChipSpec(ShareDestination.importWorkoutReview,'Import workout',     Icons.list_alt),
      _ChipSpec(ShareDestination.pantryLog,          'Pantry',             Icons.kitchen),
      _ChipSpec(ShareDestination.savedTip,           'Save as tip',        Icons.bookmark_add_outlined),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Where should this go?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (predictionLabel != null && predictionLabel!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Best guess: $predictionLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            if (predictionWhy != null && predictionWhy!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                predictionWhy!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in primary)
                  _DestinationChip(
                    spec: c,
                    selected: c.dest == predictedDestination,
                    onTap: () => onPick(c.dest),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'More options',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in secondary)
                  _DestinationChip(
                    spec: c,
                    selected: c.dest == predictedDestination,
                    onTap: () => onPick(c.dest),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Escape hatch — chat the share contents
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onPick(ShareDestination.chat),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Just chat about this'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSpec {
  _ChipSpec(this.dest, this.label, this.icon);
  final ShareDestination dest;
  final String label;
  final IconData icon;
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({
    required this.spec,
    required this.selected,
    required this.onTap,
  });
  final _ChipSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 16),
          const SizedBox(width: 6),
          Text(spec.label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}
