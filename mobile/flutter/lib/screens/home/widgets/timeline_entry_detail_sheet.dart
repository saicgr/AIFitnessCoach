/// Bottom sheet shown when the user taps a Timeline entry.
///
/// Displays full metadata + edit / delete / share buttons. Calls into
/// TimelineRepository for mutations and uses the optimistic-remove
/// helper on TimelineNotifier to keep the UI snappy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/timeline_entry.dart';
import '../../../data/providers/timeline_provider.dart';
import '../../../data/services/api_client.dart';

import '../../../l10n/generated/app_localizations.dart';
class TimelineEntryDetailSheet extends ConsumerWidget {
  final TimelineEntry entry;

  const TimelineEntryDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(entry.title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.source.label,
                    style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_fmtTimestamp(entry.occurredAt),
                    style:
                        TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
            const Divider(height: 24),
            ..._metadataRows(textPrimary, textSecondary),
            if (entry.coachNote != null && entry.coachNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.coachNote!,
                    style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (entry.actions.contains('edit'))
                  TextButton.icon(
                    onPressed: () => _onEdit(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).commonEdit),
                  ),
                if (entry.actions.contains('share'))
                  TextButton.icon(
                    onPressed: () => _onShare(context),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).commonShare),
                  ),
                if (entry.actions.contains(AppLocalizations.of(context).timelineEntryDetailRelog))
                  TextButton.icon(
                    onPressed: () => _onRelog(context, ref),
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(AppLocalizations.of(context).timelineEntryDetailReLog),
                  ),
                const Spacer(),
                if (entry.actions.contains('delete'))
                  TextButton.icon(
                    onPressed: () => _onDelete(context, ref),
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.redAccent),
                    label: Text(AppLocalizations.of(context).buttonDelete,
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _metadataRows(Color textPrimary, Color textSecondary) {
    final rows = <Widget>[];
    void add(String label, dynamic value) {
      if (value == null || value.toString().isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(color: textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value.toString(),
                  style: TextStyle(color: textPrimary, fontSize: 13)),
            ),
          ],
        ),
      ));
    }

    final m = entry.metadata;
    if (entry.subtitle != null) add('Summary', entry.subtitle);
    add('Duration',
        m['duration_minutes'] != null ? '${m['duration_minutes']} min' : null);
    add('Calories', m['calories']);
    add('Calories', m['calories_eaten']);
    add('Protein', m['protein_g'] != null ? '${m['protein_g']} g' : null);
    add('Carbs', m['carbs_g'] != null ? '${m['carbs_g']} g' : null);
    add('Fat', m['fat_g'] != null ? '${m['fat_g']} g' : null);
    add('Water', m['amount_ml'] != null ? '${m['amount_ml']} ml' : null);
    add('Weight', m['weight_kg'] != null ? '${m['weight_kg']} kg' : null);
    add('Body fat',
        m['body_fat_percent'] != null ? '${m['body_fat_percent']}%' : null);
    add('Mood', m['mood']);
    add('Energy', m['energy_level']);
    add('During', m['during']);
    return rows;
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(timelineProvider.notifier);
    final repo = ref.read(timelineRepositoryProvider);
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) return;

    notifier.removeEntry(entry.id);
    if (context.mounted) Navigator.of(context).pop();

    final ok = await repo.deleteEntry(userId: userId, eventId: entry.id);
    messenger.showSnackBar(SnackBar(
      content:
          Text(ok ? AppLocalizations.of(context).timelineEntryDetailDeleted : AppLocalizations.of(context).timelineEntryDetailFailedToDeleteRefresh),
      duration: const Duration(seconds: 3),
      action: ok
          ? SnackBarAction(
              label: AppLocalizations.of(context).timelineRefresh,
              onPressed: notifier.refresh,
            )
          : null,
    ));
  }

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(timelineRepositoryProvider);
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) return;

    final ctrl = TextEditingController(
        text: (entry.metadata['duration_minutes'] ?? '').toString());
    final patch = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).timelineEntryDetailEditDurationMin),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context).buttonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, {
                    'duration_minutes':
                        int.tryParse(ctrl.text.trim()) ?? 0,
                  }),
              child: Text(AppLocalizations.of(context).buttonSave)),
        ],
      ),
    );
    if (patch == null) return;
    final domain = entry.id.split(':').first;
    final ok = await repo.editEntry(
      userId: userId,
      eventId: entry.id,
      domain: domain,
      patch: patch,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? AppLocalizations.of(context).timelineEntryDetailUpdated : AppLocalizations.of(context).timelineEntryDetailFailedToUpdate),
    ));
    if (ok) {
      ref.read(timelineProvider.notifier).refresh();
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  void _onRelog(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).timelineEntryDetailReLogQueuedComing)),
    );
  }

  void _onShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).timelineEntryDetailShareSheetComingSoon)),
    );
  }

  static String _fmtTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')} $h:$m';
    } catch (_) {
      return iso;
    }
  }
}
