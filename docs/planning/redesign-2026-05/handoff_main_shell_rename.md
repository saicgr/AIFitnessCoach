# Handoff: bottom-nav label rename "Discover" -> "Leaderboard"

Owner of `lib/widgets/main_shell.dart` (and its `part`
`lib/widgets/main_shell_part_edge_panel_handle.dart`) — apply this edit
after Surface 4 ships. Surface 4 already added the
`bottomNavLeaderboard` ARB key to `lib/l10n/app_en.arb`. Route key
`/discover` is intentionally unchanged so deep links keep working.

## Required edits

### 1) `mobile/flutter/lib/widgets/main_shell_part_edge_panel_handle.dart`

Line range to edit: lines 286-298 (the `_ExpandableNavItem` block for the
Discover tab).

Old string (verbatim):
```dart
                  // Discover tab (W2) — globe icon (world/community leaderboard)
                  Expanded(
                    child: _ExpandableNavItem(
                      icon: Icons.public_outlined,
                      selectedIcon: Icons.public,
                      label: AppLocalizations.of(context).navDiscover,
                      isSelected: selectedIndex == 3,
                      onTap: () => onItemTapped(3),
                      accentColor: accentColor,
                      mutedColor: iconMuted,
                      isDark: isDark,
                    ),
                  ),
```

New string (verbatim):
```dart
                  // Leaderboard tab — globe icon retained (the icon is less
                  // ambiguous than the renamed label, and the screen is the
                  // same percentile leaderboard surface; route key stays
                  // `/discover` to avoid breaking deep links).
                  Expanded(
                    child: _ExpandableNavItem(
                      icon: Icons.public_outlined,
                      selectedIcon: Icons.public,
                      label: AppLocalizations.of(context).bottomNavLeaderboard,
                      isSelected: selectedIndex == 3,
                      onTap: () => onItemTapped(3),
                      accentColor: accentColor,
                      mutedColor: iconMuted,
                      isDark: isDark,
                    ),
                  ),
```

### 2) Generated localization file

Because `dart run build_runner build` / l10n codegen is intentionally
skipped in this repo (Flutter pinned to 3.38.10; generated l10n files
are committed by hand — see `mobile/flutter/CLAUDE.md`), the new
`bottomNavLeaderboard` accessor must be added manually to BOTH:

- `mobile/flutter/lib/l10n/generated/app_localizations.dart` — add an
  abstract getter `String get bottomNavLeaderboard;` next to
  `String get navDiscover;` (around line 39900).
- `mobile/flutter/lib/l10n/generated/app_localizations_en.dart` — add
  `String get bottomNavLeaderboard => 'Leaderboard';` next to
  `String get navDiscover => 'Discover';` (around line 23634).

The 35 non-English locale files (`app_localizations_*.dart`) inherit
the English fallback until the i18n translation script is rerun, so the
new key renders "Leaderboard" everywhere in the meantime. Existing
`navDiscover` key stays in place untouched for backward-compat with
any code paths still referencing it.

### 3) Verify after edit

```bash
cd mobile/flutter && flutter analyze lib/widgets/main_shell.dart \
    lib/widgets/main_shell_part_edge_panel_handle.dart \
    lib/l10n/generated/app_localizations.dart \
    lib/l10n/generated/app_localizations_en.dart 2>&1 \
    | grep -E "error|warning" | head -40
```

Expected: zero new errors. The bottom nav should render "Leaderboard"
on the fourth tab; deep links to `/discover` still route to
`DiscoverScreen` unchanged.
