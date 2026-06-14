/// Zealova Signature design-system primitives.
///
/// Import this barrel to get the hairline-led component kit:
/// `import 'package:.../widgets/design_system/zealova.dart';`
///
/// All components read the resolved accent via `ThemeColors.of(context).accent`
/// (gym-override aware) and use the `ZType` brand fonts. Glass is reserved for
/// sheets; everything else is matte hairline surfaces.
library;

export '../../core/theme/app_typography.dart' show ZType, ZTypeContext;
export 'zealova_app_bar.dart';
export 'zealova_button.dart';
export 'zealova_card.dart';
export 'zealova_chip.dart';
export 'zealova_list_row.dart';
export 'zealova_rule.dart';
export 'zealova_stat_tile.dart';
