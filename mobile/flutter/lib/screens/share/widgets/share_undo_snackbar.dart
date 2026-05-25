/// Helpers that show the 5-second "Imported as workout · Undo" snackbar
/// on the destination screen reached via the share funnel. Tapping Undo
/// marks the shared_items row as overridden and reopens the chooser so
/// the user can re-route.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/imports_api_service.dart';
import '../share_chooser_sheet.dart';
import '../share_routing_table.dart';

/// Show the undo snackbar at the bottom of the current scaffold.
///
/// [intentLabel] is the human label ("workout" / "recipe" / "food log") —
/// the snackbar reads "Imported as <intentLabel> · Undo".
///
/// [sharedItemId] (optional) is the shared_items row id. When non-null,
/// tapping Undo POSTs to the reclassify endpoint and reopens the chooser.
/// When null (image-classifier path that didn't return an id), Undo just
/// pops the user back to the previous screen.
void showShareUndoSnackbar(
  BuildContext context, {
  required String intentLabel,
  String? sharedItemId,
  required WidgetRef ref,
  ShareDestination? predictedDestination,
}) {
  final messenger = ScaffoldMessenger.of(context);
  late final ScaffoldFeatureController controller;
  controller = messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 5),
      content: Text('Imported as $intentLabel'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          // Reclassify the row so it returns to `received` status — the
          // chooser sheet then walks the user through picking a new home.
          if (sharedItemId != null) {
            try {
              await ref
                  .read(importsApiServiceProvider)
                  .bulkReclassify([sharedItemId]);
            } catch (_) {/* best-effort */}
          }
          if (!context.mounted) return;
          // Pop the destination screen and offer the chooser instead.
          Navigator.of(context).maybePop();
          final picked = await ShareChooserSheet.show(
            context,
            predicted: predictedDestination ?? ShareDestination.chooser,
            predictionLabel: intentLabel,
          );
          if (picked != null && context.mounted) {
            // The actual GoRouter dispatch lives in AppRoot —
            // _dispatchShareRoute. To avoid a layer break, surface the
            // picked destination back up the widget tree via a generic
            // pop-with-value. AppRoot's listener re-routes accordingly.
            Navigator.of(context, rootNavigator: true)
                .maybePop<ShareDestination>(picked);
          }
        },
      ),
    ),
  );
  // controller can be used to dismiss programmatically if the user takes
  // any action that should hide the undo (e.g. starts editing the
  // imported workout). Currently unused — the 5-second timer is enough.
  // ignore: unused_local_variable
  final _ = controller;
}
