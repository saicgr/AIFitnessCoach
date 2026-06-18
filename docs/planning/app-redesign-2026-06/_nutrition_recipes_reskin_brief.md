# Signature dark re-skin brief — Nutrition / Recipe screens

You are RE-SKINNING Zealova Flutter nutrition recipe screens to the "Signature" dark design.
PRODUCTION code — must compile, ZERO functionality lost. RE-SKIN ONLY (visual/layout/style only).

## ABSOLUTE GUARDRAILS — re-skin ONLY
- DO NOT change provider reads, API/service calls, navigation targets, analytics, prefs keys,
  state logic, method signatures, constructors, callbacks. EVERY onTap/onPressed/controller/
  callback preserved EXACTLY. Keep all `mounted` checks. Only visual/layout/style code.
- DO NOT run build_runner. DO NOT commit.
- Edit ONLY the file(s) assigned to you.

## DESIGN CONTRACT ("Signature" dark)
- HAIRLINE-LED, not boxed-card stacks. Screen mastheads use Anton uppercase titles
  (use `ZealovaAppBar` where there's an AppBar/title, or ZType.disp for big titles).
  Section kickers → Barlow uppercase (ZealovaSectionKicker / ZType.lbl).
- Recipe cards: flatten heavy glass/shadow cards toward hairline-outlined surfaces
  (AppColors.cardBorder, ThemeColors.of(context).surface). Use ZealovaCard where it fits.
  Big numerals (kcal, macros, time) → Anton (ZType.disp). Small numerals → ZType.data.
  Labels → Barlow uppercase (ZType.lbl, letterSpacing ~1.3-2).
- Macros SEMANTIC: AppColors.macroProtein (violet) / macroCarbs (cyan) / macroFat (orange).
- Accent RESERVED: `ThemeColors.of(context).accent` ONLY for the ONE primary CTA / active
  filter chip per screen. NEVER hardcode orange (AppColors.orange) for UI accents. Use
  ZealovaButton(primary) for the single main CTA, ZealovaButton(ghost) for secondary.
- Chips → ZealovaChip (hairline Barlow). Tabs → ZealovaTextTabs. List rows → ZealovaListRow.
  Sheets keep glass (bottom-sheet container can keep glass; restyle contents to hairline).

## DESIGN SYSTEM (package `fitwiz`)
Match each file's existing import style (package: vs relative). Add as needed:
- `import 'package:fitwiz/widgets/design_system/zealova.dart';`  (barrel — exports
  ZealovaAppBar, ZealovaButton + ZealovaButtonVariant + ZealovaPlusButton, ZealovaCard +
  ZealovaCardVariant{flat,outlined,hero}, ZealovaChip + ZealovaTextTabs, ZealovaListRow,
  ZealovaRule + ZealovaSectionKicker, ZealovaStatTile)
- `import 'package:fitwiz/core/theme/app_typography.dart';`  (ZType.disp/lbl/ser/data)
- `import 'package:fitwiz/core/theme/theme_colors.dart';`     (ThemeColors.of(context))
- `import 'package:fitwiz/core/constants/app_colors.dart';`   (AppColors.cardBorder, hairline,
  hairlineStrong, macroProtein/macroCarbs/macroFat, surface, etc.)

### Key tokens
- ThemeColors.of(context): .accent, .accentContrast, .surface, .elevated, .glassSurface,
  .cardBorder, .textPrimary, .textSecondary, .textMuted, .background, .success/.warning/.error
- AppColors.cardBorder = 0xFF262626 ; AppColors.hairline = 0xFF1A1A1A ; hairlineStrong = 0xFF2A2A2E
- AppColors.macroProtein / macroCarbs / macroFat
- ZType.disp(size, {color, letterSpacing=0.5, height=0.98})  — Anton display
- ZType.lbl(size, {color, weight=w700, letterSpacing=1.8})    — Barlow uppercase (uppercase the text yourself)
- ZType.data(size, {color, weight=w700})                      — Space Mono numerals
- ZType.ser(size, {color, style=italic})                      — Fraunces human line

### Components (from zealova.dart)
- ZealovaAppBar(title, {kicker, showBack, onBack, actions, titleSize=30}) — PreferredSizeWidget
- ZealovaButton(label, {onTap, variant: ZealovaButtonVariant.primary|ghost, trailingIcon, height=52, expand=true})
- ZealovaPlusButton({onTap, size=44})
- ZealovaCard(child:, {variant: ZealovaCardVariant.flat|outlined|hero, padding=EdgeInsets.all(15), onTap, radius=14})
- ZealovaChip(label, {icon, emoji, selected, onTap})
- ZealovaTextTabs(tabs:, activeIndex:, {onChanged})
- ZealovaListRow({icon, emoji, label:, value, trailing, onTap, showChevron, hairline, labelColor})
- ZealovaRule({height=1, margin, strong})
- ZealovaSectionKicker(label, {accent, fontSize=11, padding})
- ZealovaStatTile(value:, label:, {unit, valueSize=20, accentValue, align})

## What "good" looks like
- Replace ad-hoc `Container` glass/shadow cards with ZealovaCard(outlined) or hairline rules.
- Replace AppBar with ZealovaAppBar (Anton title) when the screen has a title AppBar; keep all
  existing actions wired to the same callbacks.
- Replace hardcoded orange accents / colored section headers with reserved accent + Barlow kickers.
- Replace pill tab bars with ZealovaTextTabs. Replace filter chips with ZealovaChip.
- Big numbers (calories/time/macros) become Anton; their labels Barlow uppercase.
- Macro values colored by macroProtein/macroCarbs/macroFat.
- Keep primary accent to ONE CTA per screen; everything else ghost/hairline.
- Don't break layout: keep scroll, padding rhythm sane, no overflow (Wrap over Row where lists grow).

## VERIFY (MANDATORY, per your files only)
cd /Users/saichetangrandhe/AIFitnessCoach/mobile/flutter && flutter analyze <your files>
Fix EVERY NEW error/warning you introduce. Baseline avoid_print/deprecated_member_use/
use_build_context_synchronously/unused_field/unnecessary_non_null_assertion already exist — OK.
MUST compile (zero errors). Shared working tree: only fix YOUR files' errors, ignore unrelated orphans.
