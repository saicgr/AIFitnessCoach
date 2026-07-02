/// ShareDispatcher — the single pipeline that turns a [SharedPayload] into
/// navigation: push the router/URL processing screen, await the user's
/// (or classifier's) destination decision, then route.
///
/// Used by BOTH:
///   * the app shell (`app.dart`) for payloads arriving via the system
///     share sheet, and
///   * the Imports screen's in-app "Import with AI" launcher (photo / PDF /
///     audio / pasted text or link picked inside the app).
library share_dispatch;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/incoming_share_service.dart';
import '../../navigation/app_router.dart';
import 'meal_plan_import_review_screen.dart';
import 'share_router_screen.dart';
import 'share_routing_table.dart';
import 'url_processing_screen.dart';
import 'workout_import_review_screen.dart';

class ShareDispatcher {
  ShareDispatcher._();

  /// Push the processing screen for [payload], await the routing decision,
  /// and navigate to the destination. Returns once the destination
  /// navigation has been dispatched (or the user dismissed the flow).
  static Future<void> run(WidgetRef ref, SharedPayload payload) async {
    final router = ref.read(routerProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    // URL payloads get the dedicated UrlProcessingScreen for richer
    // SSE progress (chapters, exercise-found feed, etc.). Everything
    // else uses the generic ShareRouterScreen.
    final ShareRouteResult? result;
    if (payload.kind == SharedPayloadKind.url && payload.urls.isNotEmpty) {
      result = await Navigator.of(ctx, rootNavigator: true)
          .push<ShareRouteResult>(MaterialPageRoute(
        builder: (_) => UrlProcessingScreen(
          url: payload.urls.first,
          payload: payload,
        ),
        fullscreenDialog: true,
      ));
    } else {
      result = await Navigator.of(ctx, rootNavigator: true)
          .push<ShareRouteResult>(MaterialPageRoute(
        builder: (_) => ShareRouterScreen(payload: payload),
        fullscreenDialog: true,
      ));
    }
    if (result != null) {
      _dispatchShareRoute(ref, result);
    }
  }

  static void _pushWorkoutReview(WidgetRef ref, ShareRouteResult result) {
    final router = ref.read(routerProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => WorkoutImportReviewScreen(
        sharedItemId: result.decision?.sharedItemId ?? '',
        initialPayload: _resultPayload(result),
      ),
    ));
  }

  static void _pushMealPlanReview(WidgetRef ref, ShareRouteResult result) {
    final router = ref.read(routerProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => MealPlanImportReviewScreen(
        sharedItemId: result.decision?.sharedItemId ?? '',
        initialPayload: _resultPayload(result),
      ),
    ));
  }

  static Map<String, dynamic> _resultPayload(ShareRouteResult result) {
    // ShareRouteResult only carries the decision + original payload. The
    // server-side SSE `done` event's `payload` is captured by the router
    // screen inside `ShareDecision` — store/retrieve it via a small map.
    // For v1 we surface the source URL + raw text + a best-effort
    // exercises stub so the review screens have something to render.
    final p = <String, dynamic>{};
    if (result.payload.text != null) p['body'] = result.payload.text;
    if (result.payload.urls.isNotEmpty) p['source_url'] = result.payload.urls.first;
    return p;
  }

  static void _dispatchShareRoute(WidgetRef ref, ShareRouteResult result) {
    final router = ref.read(routerProvider);
    final payload = result.payload;
    switch (result.destination) {
      case ShareDestination.logFood:
        router.go('/nutrition?tab=log');
        break;
      case ShareDestination.scanMenu:
        // Menu scan reuses the in-chat menu flow; route to chat with the
        // shared photo attached. Photo upload flow lives in chat.
        router.go('/nutrition?tab=menu-scan');
        break;
      case ShareDestination.parseAppScreenshot:
        router.go('/nutrition?tab=log');
        break;
      case ShareDestination.scanNutritionLabel:
        router.go('/nutrition?tab=log');
        break;
      case ShareDestination.importRecipeUrl:
      case ShareDestination.importRecipePaste:
      case ShareDestination.importRecipePhoto:
        // Recipe importer — pre-fills via Riverpod-scoped state. For v1 we
        // navigate to the importer route and pass payload bits through the
        // query string. The recipe import screen's constructor already
        // supports initialUrl / initialText / initialTab.
        if (payload.urls.isNotEmpty) {
          router.go('/nutrition/recipes/import?tab=0&url=${Uri.encodeComponent(payload.urls.first)}');
        } else if (payload.text != null && payload.text!.isNotEmpty) {
          router.go('/nutrition/recipes/import?tab=2&text=${Uri.encodeComponent(payload.text!)}');
        } else {
          router.go('/nutrition/recipes/import?tab=1');
        }
        break;
      case ShareDestination.importMealPlan:
        _pushMealPlanReview(ref, result);
        break;
      case ShareDestination.importWorkoutReview:
        _pushWorkoutReview(ref, result);
        break;
      case ShareDestination.formCheck:
      case ShareDestination.importEquipment:
        router.go('/exercises/import');
        break;
      case ShareDestination.progressUpload:
        router.go('/progress?tab=photos');
        break;
      case ShareDestination.pantryLog:
        router.go('/nutrition?tab=pantry');
        break;
      case ShareDestination.savedTip:
        router.go('/chat');
        break;
      case ShareDestination.chat:
      case ShareDestination.chooser:
        router.go('/chat');
        break;
    }
  }
}
