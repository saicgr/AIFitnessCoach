# ZealovaLiveActivity — Xcode Setup (one-time manual step)

This folder contains the Swift sources for the Live Activity / Dynamic Island
Widget Extension. Creating a Widget Extension target cannot be reliably
scripted — it has to be done once in Xcode. After this is done, every
subsequent build is automatic.

## Prerequisites

- Xcode 15.0 or newer (required for iOS 16.1+ Live Activity SDK).
- Same Apple Developer team as the Runner target (so the App Group can be
  shared).

## 1. Open the workspace

```bash
cd mobile/flutter
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Note: always `.xcworkspace`, **never** `.xcodeproj`.

## 2. Add the Widget Extension target

1. In Xcode: **File → New → Target…**
2. Pick **Widget Extension** (under iOS). Click **Next**.
3. Fill in:
   - **Product Name:** `ZealovaLiveActivity` (exact — referenced in the
     Dart `App Group` name and this folder's files).
   - **Team:** same team as Runner.
   - **Organization Identifier:** inherit from project.
   - **Bundle Identifier:** auto → `com.aifitnesscoach.app.ZealovaLiveActivity`
     (or whatever Runner's bundle id dotted with `.ZealovaLiveActivity`).
   - **Language:** Swift.
   - **Include Configuration Intent:** OFF.
   - ✅ **Include Live Activity:** ON.
   - **Embed in Application:** Runner.
4. Click **Finish**. If Xcode asks to activate the scheme, choose **Cancel**.

## 3. Replace the auto-generated files with ours

Xcode will have generated a few files inside a new `ZealovaLiveActivity/`
group in the project navigator. The files in this folder on disk
(`ios/ZealovaLiveActivity/*.swift`) are what should ship. Either:

- **Option A (easier):** delete the Xcode-generated files (choose
  "Remove Reference" — leave ours on disk), then drag our files from
  Finder into the Xcode `ZealovaLiveActivity` group, and in the dialog:
  - ✅ Copy items if needed → **OFF** (files already in the right folder).
  - ✅ Add to targets → **ZealovaLiveActivity** only.

- **Option B:** Let Xcode keep its files, but replace their contents by
  copy-pasting from ours. Make sure the widget bundle struct is annotated
  with `@main` in exactly one place.

Required files (all should be members of the `ZealovaLiveActivity` target,
NOT the Runner target):
- `LiveActivitiesAppAttributes.swift`
- `WorkoutLiveActivityState.swift`
- `WorkoutLiveActivity.swift`
- `ZealovaLiveActivityBundle.swift`
- `Info.plist` (auto-generated; ensure `NSSupportsLiveActivities = YES`).
- `ZealovaLiveActivity.entitlements` (create fresh from capabilities dialog).

## 4. Configure capabilities on BOTH targets

**Runner target** → Signing & Capabilities:
1. `+ Capability` → **App Groups** → enable and add
   `group.zealova.liveactivity` (exact string — matches `_appGroupId` in
   `lib/data/services/live_activity_service.dart`).
2. `+ Capability` → **Push Notifications**. (Required by the
   `live_activities` Flutter package even though we only do local updates.)

**ZealovaLiveActivity target** → Signing & Capabilities:
1. `+ Capability` → **App Groups** → enable and add the **same**
   `group.zealova.liveactivity`.

## 5. Info.plist — Runner

`ios/Runner/Info.plist` already contains `<key>NSSupportsLiveActivities</key><true/>`
(committed via this change). No action needed.

## 6. Minimum iOS version

`ios/Podfile` is pinned to `platform :ios, '16.1'` (committed via this
change). In Xcode, also set **ZealovaLiveActivity → General → Minimum
Deployments → iOS 16.1** (should default, but verify).

## 7. Validate

```bash
flutter build ios --debug --no-codesign
```

Expected: "Build succeeded." No Swift errors.

If you see:
- **"No such module 'ActivityKit'"** → ZealovaLiveActivity target's
  deployment target is below 16.1. Bump it.
- **"'ActivityAttributes' is unavailable in macOS"** (in editor, not
  build) → ignore; ActivityKit is iOS-only and the editor was analyzing
  against macOS SDK before you added the target.
- **"Cannot find LiveActivitiesAppAttributes in scope"** → the file is
  not a member of the ZealovaLiveActivity target. Select the file, open
  the File Inspector (right side), and tick ZealovaLiveActivity under
  Target Membership.

## 8. First run

On a real iPhone 15 Pro simulator (Xcode → Window → Devices and
Simulators → choose the simulator) or a physical iOS 16.1+ device:

```bash
flutter run -d <device-id>
```

Start a workout in the app. Within a second or two, the Dynamic Island
should pop with the dumbbell + live timer. Lock the phone to see the
Live Activity banner on the Lock Screen.
