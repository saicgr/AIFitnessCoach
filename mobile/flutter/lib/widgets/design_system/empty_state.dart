import 'package:flutter/material.dart';

import '../../core/theme/theme_colors.dart';

/// Three-state empty-state primitive used everywhere a metric tile / card
/// surface might be "not connected", "zero data yet", or "real data".
///
/// Replaces the inconsistent mix we shipped before (`0`, `No data`, `0%`,
/// `Connect` chip) — same screen used to show three different treatments
/// simultaneously. Carbon / NN/G empty-state guidance: one visual treatment
/// per state, applied consistently.
///
/// Usage:
///   Tile(
///     metric: EmptyStateMetric.value('1,247', 'steps'),
///   )
///   Tile(
///     metric: EmptyStateMetric.placeholder(helper: 'Updates each morning'),
///   )
///   Tile(
///     metric: EmptyStateMetric.connect(source: 'Apple Health'),
///   )
///
/// Callers pick the variant based on `healthSyncProvider.isConnected` and
/// whether the underlying value is non-zero. The three constructors render
/// distinct visuals so a 0-value can never be confused with disconnected.
sealed class EmptyStateMetric {
  const EmptyStateMetric();

  /// Connected + real data. Render the actual value + unit.
  const factory EmptyStateMetric.value(String value, String unit) =
      _ValueMetric;

  /// Connected but no data yet (e.g., 5am, no steps logged). `—` placeholder
  /// plus a helper line describing when data lands.
  const factory EmptyStateMetric.placeholder({String? helper}) =
      _PlaceholderMetric;

  /// Disconnected — no Health permission. Render a `Connect` pill instead of
  /// any number / placeholder so the user can never mis-read a "0" as zero
  /// data when it's actually no permission.
  const factory EmptyStateMetric.connect({required String source}) =
      _ConnectMetric;

  Widget build(BuildContext context);
}

class _ValueMetric extends EmptyStateMetric {
  final String value;
  final String unit;
  const _ValueMetric(this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderMetric extends EmptyStateMetric {
  final String? helper;
  const _PlaceholderMetric({this.helper});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '—',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: c.textMuted,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: TextStyle(
              fontSize: 11,
              color: c.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectMetric extends EmptyStateMetric {
  final String source;
  const _ConnectMetric({required this.source});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: c.cardBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Connect $source',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
