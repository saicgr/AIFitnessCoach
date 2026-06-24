/// Signature v2 widget kit — small, const-friendly, dark-theme building blocks
/// that program-facing screens compose. Reuses the app's existing tokens
/// (`ZType`, `AppColors`) — no new fonts/colors invented.
///
/// Import this barrel to get the whole kit:
/// ```dart
/// import 'package:fitwiz/widgets/signature/signature.dart';
/// ```
library;

export 'signature_theme.dart'
    show programDifficultyColor, categoryTheme, CategoryTheme;
export 'z_section_kicker.dart' show ZSectionKicker;
export 'z_hairline_row.dart' show ZHairlineRow;
export 'z_chip.dart' show ZChip;
export 'z_poster_card.dart' show ZPosterCard, ZDifficultyRibbon;
export 'z_hero_card.dart' show ZHeroCard, ZCarouselDots;
