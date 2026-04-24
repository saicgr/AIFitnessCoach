# `/mobile/flutter` — Three-Flavor Flutter Codebase

This Flutter codebase ships THREE App Store apps via build flavors:

| Flavor | App Store name | Bundle ID | Purpose |
|---|---|---|---|
| `consumer` (existing) | FitWiz | `com.fitwiz.app` | B2C self-directed AI fitness |
| `client` (Reppora — new) | Reppora | `com.reppora.app` | Coach-led clients, white-labeled at runtime to coach's brand |
| `coach` (Reppora — new) | Reppora for Coach | `com.reppora.coach` | Trainer dashboard companion (reply/monitor only; building stays on web) |

Reppora-specific guidance lives in **`/Users/saichetangrandhe/Reppora/`** repo. This CLAUDE.md is the cross-repo bridge.

## Workflow when working on Reppora client/coach flavors

1. Read `/Users/saichetangrandhe/Reppora/CLAUDE.md` for Reppora workflow + ultrathink + swarm rules.
2. Read `/Users/saichetangrandhe/Reppora/docs/reference/flutter-gotchas.md` for ALL Flutter gotchas (build_runner trap, iOS pipeline, widget infra).
3. New screens for `client` flavor → `lib/screens/client/`. New screens for `coach` flavor → `lib/screens/coach/`. Shared widgets → `lib/widgets/glass/` (Reppora glassmorphism).
4. Run via Reppora repo's `./scripts/run_ios_client.sh` / `run_ios_coach.sh` / Android equivalents.

## Critical invariants (apply to ALL flavors)

- **DO NOT run `dart run build_runner build`** — analyzer 7.x crash with Dart 3.11 dot-shorthand AST. The 13 `.g.dart` files under `lib/data/local/` MUST stay in git. Flutter pinned to **3.38.10 / Dart 3.10.9** via `/opt/homebrew/Caskroom/flutter/3.38.3/`.
- **iOS Runner.xcodeproj phase order:** `Embed Foundation Extensions` MUST come BEFORE `Thin Binary` in `buildPhases`. Reverting to Xcode default → "Cycle inside Runner" build failure (Live Activity dependency).
- **iOS `flutter_gemma` strip script** must run at build time (Xcode build phase id `B1A5BEEF1F901F6004384FC0`), not just `pod install` — `flutter run` regenerates `GeneratedPluginRegistrant.m` between pod install and compile.
- **Widget app-group ID** = `group.com.aifitnesscoach.widgets` (NOT `group.com.fitwiz.widgets`). Widget URL scheme = `fitwiz://`. New flavor schemes: `reppora://` (client), `reppora-coach://` (coach) — register in Info.plist + AndroidManifest before any widget work.
- **S3 exercise illustrations** live at `ILLUSTRATIONS ALL/` (with trailing space + ALL suffix). Plain `ILLUSTRATIONS/` doesn't exist.
- **Flutter packages over native Swift/Kotlin** for v1 of native-adjacent features (ActivityKit, WidgetKit, HealthKit). Migrate to native later if package is limiting.
- **No mock data, no fallback data, no silent degradation.** B2C feedback memory rule applies to Reppora flavors too.
- **Always check `mounted` before `setState`** in async flows.

## Reppora client app — purpose-built (NOT a re-theme)

The `client` flavor is NOT a re-skin of FitWiz consumer. FitWiz lacks coach-program / trainer↔client message / coach-assigned check-in primitives. ~90% of FitWiz infra reuses (workout execution, food logging, recipes, wearables, offline DB); ~10% is new screens (coach-program home, trainer-message thread, coach-assigned forms/tasks/check-ins). See Reppora `docs/architecture/reuse-audit.md`.

## "Powered by Reppora" footer

In Reppora client app — non-removable on Reppora Free tier, removable on Pro. NOT "Powered by FitWiz" (Reppora is the B2B brand; clients clicking footer should land on `reppora.com`).
