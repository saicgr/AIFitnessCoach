import 'package:flutter/material.dart';

import 'editor/card_editor_screen.dart';
import 'recent_templates_store.dart';
import 'share_compose_screen.dart';
import 'shareable_catalog.dart';
import 'shareable_data.dart';

/// THE unified share entry point. Every share surface in the app delegates to
/// [ShareableSheet.show] (Reports & Insights, Stats & Scores, Workout
/// completion, Weekly summary, Strength, Wrapped, Nutrition …). Carries one
/// [Shareable] payload built by the appropriate adapter in
/// `lib/shareables/adapters/`.
///
/// **Photo-first flow (Gravl parity).** `show()` is a thin launcher:
///   1. Open [ShareComposeScreen] — the user picks a canvas first
///      (Camera Roll / Stock / "No photo / background"), kind-aware
///      pre-selecting the logged meal photo (food) or a fresh post-workout
///      photo (workout, via `data.customPhotoPath`).
///   2. Open [CardEditorScreen] over that canvas — two trays (Custom stickers
///      + Templates), photo effects, perspective, and a Story / Save / Share
///      action bar.
///
/// The old monolithic gallery + tool-rail collapsed into the editor's
/// Templates tray; the heavy in-sheet preview is gone.
class ShareableSheet {
  const ShareableSheet._();

  /// Launches the photo-first share flow. Signature unchanged so all existing
  /// call sites keep working:
  ///   - [data] the share payload (its `kind` drives template + sticker sets).
  ///   - [onGenerateShareLink] optional link generator (workout completion);
  ///     kept for source compatibility — the deep-link/referral surface is
  ///     Workstream F5.
  ///   - [initialTemplate] a preferred starting template; falls back to the
  ///     kind's default editable template.
  static Future<void> show(
    BuildContext context, {
    required Shareable data,
    Future<String?> Function()? onGenerateShareLink,
    ShareableTemplate? initialTemplate,
  }) async {
    // 1) Photo-first: pick the canvas.
    final compose = await ShareComposeScreen.open(context, data);
    if (compose == null || !context.mounted) return;

    // 2) Open the editor over the chosen canvas (Custom + Templates trays).
    final edited = await CardEditorScreen.openForShare(
      context,
      data: data,
      compose: compose,
      initialTemplate: initialTemplate,
    );

    // Stamp the chosen template as "recent" when the user shipped a card.
    if (edited?.presetId != null) {
      // ignore: unawaited_futures
      RecentTemplatesStore.recordUsed(edited!.presetId!);
    }
  }
}
