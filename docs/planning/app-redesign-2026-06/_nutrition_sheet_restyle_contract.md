# Nutrition Sheets — Signature dark RE-SKIN contract (shared brief)

You are restyling Zealova Flutter NUTRITION sheets/widgets to the "Signature" dark design.
PRODUCTION code — must compile, ZERO functionality lost. RE-SKIN ONLY.

## DESIGN CONTRACT ("Signature" dark)
Reference HTML: /Users/saichetangrandhe/AIFitnessCoach/docs/planning/app-redesign-2026-06/signature-v2.html

- HAIRLINE-LED. Sheets KEEP their glass surface (GlassSheet / glassmorphic container stays).
  Inside them: hairline dividers, Barlow uppercase kickers/labels, Anton big numerals,
  ZealovaListRow rows, ZealovaChip chips. Replace boxed-card stacks with hairline-separated rows.
- Big numerals (calories, macros, scores, weights) -> Anton via `ZType.disp(size)`.
- Labels / kickers / section headers -> Barlow uppercase via `ZType.lbl(size)` or
  `ZealovaSectionKicker('LABEL')`. Use UPPERCASE text for kickers.
- Macros are SEMANTIC colors, NEVER hardcoded:
  - protein -> `AppColors.macroProtein` (violet)
  - carbs   -> `AppColors.macroCarbs` (cyan)
  - fat     -> `AppColors.macroFat` (orange)
- Accent is RESERVED: `ThemeColors.of(context).accent` is used ONLY for the ONE primary
  CTA / single active state per sheet. NEVER hardcode orange/teal/green. Replace any
  hardcoded `Color(0xFF14B8A6)` (teal), `Color(0xFFF97316)`, accent-ish literals.
- Primary action: `ZealovaButton(label: ..., onTap: ..., variant: ZealovaButtonVariant.primary)`
  — ONE per sheet. Secondary actions: `ZealovaButtonVariant.ghost` (hairline outline, white label).
- The "+" quick-add affordance -> `ZealovaPlusButton(onTap: ...)` look (white glyph on surface,
  never accent-filled).
- Search bars / inputs -> hairline-bordered FLAT surface (no Material default OutlineInputBorder
  with rounded fill). Use a Container with `Border.all(color: AppColors.cardBorder)` +
  `BorderRadius.circular(12)` wrapping the TextField, OR an InputDecoration with
  `enabledBorder`/`focusedBorder` = OutlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder))
  and focused border tinted with `ThemeColors.of(context).accent`. Flat surface fill = `tc.surface`.
- Chips / filter pills -> `ZealovaChip(label:, selected:, onTap:)`.
- Toggles -> `ZealovaToggle(value:, onChanged:)`.
- Dividers -> `ZealovaRule()` (or `AppColors.hairline` border on a Container).
- Row links / list items (icon + label + value + chevron) -> `ZealovaListRow(...)`.

## IMPORTS (match each file's existing relative-vs-package style)
If file uses package imports:
  import 'package:fitwiz/widgets/design_system/zealova.dart';
  import 'package:fitwiz/core/theme/app_typography.dart';   // only if ZType used AND not already from barrel
  import 'package:fitwiz/core/theme/theme_colors.dart';
  import 'package:fitwiz/core/constants/app_colors.dart';
If file uses relative imports, mirror with relative paths, e.g. from lib/screens/nutrition/widgets/:
  import '../../../widgets/design_system/zealova.dart';
NOTE: zealova.dart barrel re-exports `ZType` (show ZType, ZTypeContext). So if you import the
barrel AND app_typography.dart you may get `unnecessary_import`. Keep ONLY what's needed — prefer
the barrel for ZType and drop a separate app_typography import if the barrel covers it.

## ABSOLUTE GUARDRAILS — re-skin ONLY
- DO NOT change provider reads, API/service/composer calls, navigation, analytics, prefs keys,
  state logic, method signatures, constructors, callbacks, controllers/focusNodes.
- EVERY onTap/onChanged/onSubmitted/callback preserved exactly.
- Keep ALL `mounted` checks. Keep all l10n `AppLocalizations.of(context)...` calls.
- Keep the GlassSheet/showGlassSheet wrappers and their params (showHandle etc).
- DO NOT run build_runner. DO NOT commit. Visual/layout/style code only.
- Do NOT touch files outside your assigned list.

## VERIFY
Run `flutter analyze <your files>` from /Users/saichetangrandhe/AIFitnessCoach/mobile/flutter.
Fix EVERY NEW error/warning (esp. unused/unnecessary imports). Baseline avoid_print /
deprecated_member_use / withOpacity are OK to leave. ZERO new errors required.
