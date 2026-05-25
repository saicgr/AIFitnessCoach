import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/providers/recipe_save_jobs_provider.dart';
import '../data/providers/root_messenger.dart';
import '../data/providers/schedule_save_jobs_provider.dart';
import '../screens/nutrition/recipes/recipe_detail_screen.dart';

import '../l10n/generated/app_localizations.dart';
/// Watches the global recipeSaveJobsProvider and surfaces a toast when a
/// background Save-as-Recipe job flips off `pending`. Mounted high in the
/// widget tree (in app.dart's builder) so the toast appears regardless of
/// which sub-route the user is on when the AI enrichment finishes.
class RecipeSaveJobsListener extends ConsumerStatefulWidget {
  final Widget child;
  const RecipeSaveJobsListener({super.key, required this.child});

  @override
  ConsumerState<RecipeSaveJobsListener> createState() =>
      _RecipeSaveJobsListenerState();
}

class _RecipeSaveJobsListenerState extends ConsumerState<RecipeSaveJobsListener> {
  // Tracks job IDs we've already surfaced a toast for so a rebuild doesn't
  // fire a duplicate. Bounded by the provider's _prune (30s window).
  final Set<String> _seen = <String>{};

  @override
  Widget build(BuildContext context) {
    ref.listen<List<RecipeSaveJob>>(recipeSaveJobsProvider, (prev, next) {
      for (final job in next) {
        if (job.status == RecipeSaveStatus.pending) continue;
        if (_seen.contains(job.jobId)) continue;
        _seen.add(job.jobId);
        _showToast(job);
      }
    });
    ref.listen<List<ScheduleSaveJob>>(scheduleSaveJobsProvider, (prev, next) {
      for (final job in next) {
        if (job.status == ScheduleSaveStatus.pending) continue;
        if (_seen.contains(job.jobId)) continue;
        _seen.add(job.jobId);
        _showScheduleToast(job);
      }
    });
    return widget.child;
  }

  void _showScheduleToast(ScheduleSaveJob job) {
    if (job.status == ScheduleSaveStatus.error) {
      rootSnackBar(SnackBar(
        content: Text("Couldn't schedule '${job.mealName}': ${job.error ?? 'Unknown error'}"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
    } else if (job.result != null) {
      // Render a friendly "next at <weekday> <time>" so the user sees what
      // their tap actually scheduled.
      final next = job.result!.nextFireAt.toLocal();
      final fmt = DateFormat('EEE h:mm a');
      rootSnackBar(SnackBar(
        content: Text("${job.cadenceLabel} — next at ${fmt.format(next)}"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    }
    ref.read(scheduleSaveJobsProvider.notifier).markAcknowledged(job.jobId);
  }

  void _showToast(RecipeSaveJob job) {
    switch (job.status) {
      case RecipeSaveStatus.done:
        rootSnackBar(SnackBar(
          content: Text("Saved '${job.mealName}' to your recipes"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: job.result == null
              ? null
              : SnackBarAction(
                  label: AppLocalizations.of(context).setTrackingOverlayView,
                  onPressed: () => _openRecipe(job.result!.recipeId),
                ),
        ));
        break;
      case RecipeSaveStatus.merged:
        rootSnackBar(SnackBar(
          content: Text("'${job.mealName}' is already in your recipes"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: job.result == null
              ? null
              : SnackBarAction(
                  label: AppLocalizations.of(context).setTrackingOverlayView,
                  onPressed: () => _openRecipe(job.result!.recipeId),
                ),
        ));
        break;
      case RecipeSaveStatus.error:
        rootSnackBar(SnackBar(
          content: Text("Couldn't save recipe: ${job.error ?? 'Unknown error'}"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: AppLocalizations.of(context).buttonRetry,
            onPressed: () {
              // Re-enqueue with the same params. createCookEvent isn't carried
              // through — rare edge case for retry; user can retry manually
              // from the menu if they want the cook-event side effect.
              ref.read(recipeSaveJobsProvider.notifier).enqueue(
                    logId: job.logId,
                    itemIndex: job.itemIndex,
                    mealName: job.mealName,
                  );
            },
          ),
        ));
        break;
      case RecipeSaveStatus.pending:
        // Guarded earlier; nothing to do.
        break;
    }
    ref.read(recipeSaveJobsProvider.notifier).markAcknowledged(job.jobId);
  }

  void _openRecipe(String recipeId) {
    final messenger = rootScaffoldMessengerKey.currentContext;
    if (messenger == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isDark = Theme.of(messenger).brightness == Brightness.dark;
    Navigator.of(messenger, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipeId: recipeId,
          userId: userId,
          isDark: isDark,
        ),
      ),
    );
  }
}
