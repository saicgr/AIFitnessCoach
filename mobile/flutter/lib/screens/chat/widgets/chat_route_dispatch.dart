import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Deep-link out of chat, and SAY SO when it fails.
///
/// Every tappable thing in the thread that navigates — briefing chips, greeting
/// chips, suggested-reply chips, data blocks, the logged-event row — used to
/// wrap `context.push` in a bare `catch (_) {}` at some call sites and a
/// SnackBar at others. The bare ones turn an unregistered / malformed route
/// into a tap that does nothing at all, which is the register's #2 UX
/// complaint ("actions that don't visibly do anything") and the same failure
/// mode that made a 500ing Save look inert (#98 / #105).
///
/// One chokepoint, one behaviour: navigate, or tell the user it didn't.
void pushChatRoute(BuildContext context, String route) {
  try {
    context.push(route);
  } catch (e) {
    debugPrint('❌ [Chat] deep link failed for "$route": $e');
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context).chatScreenRouteNotRegistered(route)),
      ),
    );
  }
}
