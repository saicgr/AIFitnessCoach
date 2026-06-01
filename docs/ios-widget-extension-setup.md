# iOS Home-Screen Widget Extension — final setup (one Xcode step)

The home-screen widget code (`mobile/flutter/ios/FitnessWidgets/*.swift`) and the
whole Dart pipeline are done and live. Everything that can be done as text/config
is done. The **one** remaining step needs Xcode's Widget Extension target
template — hand-writing an app-extension target into `project.pbxproj` risks
corrupting the project, so it must be created in the IDE.

## What's already done (no action needed)
- **Dart pipeline LIVE:** `WidgetService.initialize()` is uncommented in
  `main.dart`; water data is pushed on every hydration refresh (with the Gap-6
  `enabled` flag + Gap-5 saved bottles) and food data on every nutrition refresh.
- **App Group on the host app:** `group.com.aifitnesscoach.widgets` added to
  `ios/Runner/Runner.entitlements`.
- **Extension entitlements + Info.plist pre-created:**
  `ios/FitnessWidgets/FitnessWidgets.entitlements` (App Group) and
  `ios/FitnessWidgets/Info.plist` (WidgetKit extension point).
- **App group id is consistent** across Dart (`WidgetService._appGroupId`),
  Swift (`WidgetDataKeys.appGroupId`), and both entitlements files:
  `group.com.aifitnesscoach.widgets`.
- **Signing is Automatic** (team `G9RL26P89Q`) — Xcode auto-registers the App
  Group with the dev portal at build time; no manual provisioning-profile work.
- **Android works today** with zero native setup (home_widget uses SharedPreferences).

## The one Xcode step (~5 min)

1. Open `mobile/flutter/ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.**
   - Product Name: **`FitnessWidgets`**
   - Team: G9RL26P89Q (pre-selected)
   - Uncheck **"Include Live Activity"** and **"Include Configuration App Intent"**
     (these are static widgets; the bundle is hand-authored).
   - When prompted "Activate scheme?", click **Activate**. When prompted to embed
     in **Runner**, accept.
3. Xcode generates a `FitnessWidgets` group with a template `FitnessWidgets.swift`
   (+ its own Info.plist). **Delete the generated `FitnessWidgets.swift`**
   (move to trash) — `FitnessWidgetsBundle.swift` is the real `@main` `WidgetBundle`.
4. **Add the existing source files to the new target.** In the Project navigator,
   select all files under `ios/FitnessWidgets/` (FitnessWidgetsBundle.swift,
   Views/WidgetViews.swift, SharedData/WidgetDataProvider.swift, and every file in
   Widgets/) → File Inspector → **Target Membership → check `FitnessWidgets`**
   (and uncheck Runner). If Xcode didn't already reference them, drag the folder in
   ("Create groups", add to the FitnessWidgets target only).
5. **Info.plist:** point the target at the prepared one — target Build Settings →
   `INFOPLIST_FILE = FitnessWidgets/Info.plist` (or keep Xcode's generated plist;
   both declare `com.apple.widgetkit-extension`).
6. **Entitlements / App Group:** select the **FitnessWidgets** target →
   Signing & Capabilities → **+ Capability → App Groups** → check
   `group.com.aifitnesscoach.widgets`. (This sets
   `CODE_SIGN_ENTITLEMENTS = FitnessWidgets/FitnessWidgets.entitlements`, which is
   already present.)
7. Select the **Runner** target → Signing & Capabilities → App Groups → confirm
   `group.com.aifitnesscoach.widgets` is checked (already in Runner.entitlements).
8. Set the FitnessWidgets target **iOS Deployment Target ≥ 15.0** to match Runner.
9. Build & run to a device/simulator. Long-press home screen → **+** → search
   "Zealova" → add the **Water** / **Food** widgets.

### Build-order gotcha (project memory)
`Embed Foundation Extensions` must come **before** `Thin Binary` in the Runner
target's Build Phases (reordering to Xcode's default causes a "Cycle inside
Runner" error — same constraint already noted for FitWizLiveActivityExtension).
Xcode adds the new extension's embed entry to the existing `Embed Foundation
Extensions` phase; just verify the phase order after adding the target.

## Verify it's wired
- Water tracking OFF in Settings → widget shows the muted "Water tracking is off"
  state; ON → shows progress + quick-add (saved custom bottles if any).
- Log water in-app → widget total updates within ~30 min (or on next timeline
  refresh / tap).
