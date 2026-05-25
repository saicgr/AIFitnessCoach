# iOS Share Extension — one-time Xcode target creation

The Swift source, `Info.plist`, and entitlements live in this directory
already. The pieces that must be done in Xcode (xcodeproj wiring) — once
per developer machine that opens the project — are below.

## 1. Add the Share Extension target

1. Open `mobile/flutter/ios/Runner.xcworkspace` in Xcode.
2. File → New → Target → **Share Extension** (under iOS).
3. Product name: `ShareExtension`.
4. Bundle identifier: **`com.zealova.app.ShareExtension`**.
5. Language: Swift. Include UI: yes (Xcode default; we override the
   storyboard with our SLComposeServiceViewController-based controller).
6. After Xcode creates the target, **delete** the auto-generated
   `ShareViewController.swift` + storyboard files inside `Runner.xcodeproj`
   group view, but keep them on disk only if Xcode says so — we replace
   them with the files in `ios/ShareExtension/` already on disk.

## 2. Point the target at our files

In Project Navigator, drag `ios/ShareExtension/ShareViewController.swift`,
`Info.plist`, and `ShareExtension.entitlements` into the
`ShareExtension` group. When Xcode prompts:

- ☑️ **Copy items if needed** → leave unchecked (files already live there).
- ☑️ **Add to targets** → check ONLY the `ShareExtension` target (NOT
  Runner).

## 3. Build Settings for the new target

In the target's **Build Settings**:

- `INFOPLIST_FILE` = `ShareExtension/Info.plist`
- `CODE_SIGN_ENTITLEMENTS` = `ShareExtension/ShareExtension.entitlements`
- `PRODUCT_BUNDLE_IDENTIFIER` = `com.zealova.app.ShareExtension`
- `IPHONEOS_DEPLOYMENT_TARGET` = `15.0` (matches the existing Runner target)
- `SWIFT_VERSION` = `5.0`

## 4. Build Phases — important order!

In the ShareExtension target's **Build Phases**, ensure phases run in
this order (Live Activity extension has the same gotcha — see
`docs/widget-app-group-id.md`):

1. Target Dependencies
2. Compile Sources
3. **Embed Foundation Extensions** (if Xcode added it here)
4. Resources
5. Frameworks
6. (Any custom run-script phases)

In the **Runner** target's Build Phases (NOT the ShareExtension target):

- An `Embed App Extensions` (or `Embed Foundation Extensions`) phase MUST
  exist and MUST contain the `ShareExtension.appex` product.
- This phase MUST run **before** the existing `Thin Binary` phase.
  Reverting to Xcode's default order causes a "Cycle inside Runner" build
  failure — same issue as the Live Activity extension.

## 5. Signing & Capabilities (both targets)

In **Capabilities** for both Runner AND ShareExtension:

- Enable **App Groups** and add `group.com.zealova.app.share`. (Already
  declared in `Runner.entitlements` and `ShareExtension.entitlements` —
  Xcode just needs to acknowledge the capability.)

## 6. URL scheme handoff

The extension opens the host app via the existing `zealova://` URL scheme
already registered in `Runner/Info.plist`. No new scheme needs adding.

## 7. Smoke test

Build to a device. From Photos, select a photo, hit Share, scroll the
share sheet until **Zealova** appears, tap it. The composer should
appear; tap **Post**. The host app should open and navigate into
`ShareRouterScreen` ("Looking at the photo…" → routed).

If Zealova does NOT appear in the share sheet:
- Re-build with a clean device.
- Confirm `NSExtensionActivationRule` in `Info.plist` accepts your
  payload type.
- iOS caches share-sheet listings for ~10 minutes after install; if you
  installed from Xcode and immediately tested, reboot the device or wait
  out the cache.

## 8. Locked YouTube path reminder

This extension delivers payloads to the host app only. The host app's
backend `/share/fetch-url` endpoint follows the rule that YouTube URLs go
through the **YouTube Data API + youtube_transcript_api** ONLY, never
yt-dlp. No work needed here — this note exists so the next reviewer
doesn't add "download YouTube" logic to the extension by mistake.
