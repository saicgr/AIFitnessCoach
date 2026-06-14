import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Signature typography roles.
///
/// Opt-in helper so screens use the right bundled brand font without guessing
/// a `fontFamily` string. Backed by fonts already bundled in pubspec.yaml:
/// Anton (display / big numerals), Barlow Condensed (uppercase labels/kickers),
/// Fraunces (human/emotional lines), Space Mono (telemetry / numeric data).
///
/// Colors default to the Signature text ladder. Where an accent tint is wanted,
/// apply the RESOLVED accent (from AccentColorScope / ThemeColors.of(context).accent)
/// via `.copyWith(color: ...)` — never hardcode orange.
class ZType {
  ZType._();

  /// Anton — mastheads + hero numerals. Heavy display face; uppercase-friendly.
  static TextStyle disp(
    double size, {
    Color? color,
    double letterSpacing = 0.5,
    double height = 0.98,
  }) =>
      TextStyle(
        fontFamily: 'Anton',
        fontWeight: FontWeight.w400,
        fontSize: size,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.textPrimary,
      );

  /// Barlow Condensed — uppercase labels, kickers, nav labels, chips.
  static TextStyle lbl(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.8,
  }) =>
      TextStyle(
        fontFamily: 'Barlow Condensed',
        fontWeight: weight,
        fontSize: size,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.textSecondary,
      );

  /// Fraunces — the human/emotional line (greetings, coach whispers, exhales).
  static TextStyle ser(
    double size, {
    Color? color,
    FontStyle style = FontStyle.italic,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
  }) =>
      TextStyle(
        fontFamily: 'Fraunces',
        fontStyle: style,
        fontWeight: weight,
        fontSize: size,
        height: height,
        color: color ?? AppColors.textPrimary,
      );

  /// Space Mono — telemetry / monospaced numeric readouts (timers, set tables).
  static TextStyle data(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) =>
      TextStyle(
        fontFamily: 'Space Mono',
        fontWeight: weight,
        fontSize: size,
        color: color ?? AppColors.textPrimary,
      );
}

/// Sugar so widgets can write `context.zDisp(40)` etc.
extension ZTypeContext on BuildContext {
  TextStyle zDisp(double size, {Color? color, double letterSpacing = 0.5}) =>
      ZType.disp(size, color: color, letterSpacing: letterSpacing);
  TextStyle zLbl(double size,
          {Color? color, FontWeight weight = FontWeight.w700, double letterSpacing = 1.8}) =>
      ZType.lbl(size, color: color, weight: weight, letterSpacing: letterSpacing);
  TextStyle zSer(double size, {Color? color, FontStyle style = FontStyle.italic}) =>
      ZType.ser(size, color: color, style: style);
  TextStyle zData(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      ZType.data(size, color: color, weight: weight);
}
