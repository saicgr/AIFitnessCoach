import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Receipt — cream-paper "FITWIZ GYM RECEIPT" with each highlight rendered
/// as a monospaced line item and the hero value stamped at the bottom.
/// Locks out with a ShareLockOverlay when there are no highlights to print.
class ReportReceiptTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportReceiptTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroMetricFor(data);
    final unit = heroUnitFor(data);
    final customer = (data.userDisplayName ?? 'LIFTER').toUpperCase();

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF121212)),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Container(
                decoration: BoxDecoration(
                  // Cream-paper look with a subtle gradient for texture.
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF8EC), Color(0xFFF5ECCC)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'FITWIZ GYM',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 4,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'REPORT RECEIPT · ${data.periodLabel}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _DashedDivider(),
                    const SizedBox(height: 10),
                    _ReceiptRow(
                      label: 'CUSTOMER',
                      value: customer,
                    ),
                    _ReceiptRow(
                      label: 'REPORT',
                      value: data.title.toUpperCase(),
                    ),
                    const SizedBox(height: 10),
                    const _DashedDivider(),
                    const SizedBox(height: 8),
                    ...data.highlights.take(8).map(
                          (h) => _ReceiptRow(label: h.label, value: h.value),
                        ),
                    const SizedBox(height: 8),
                    const _DashedDivider(),
                    const SizedBox(height: 8),
                    _ReceiptRow(
                      label: 'TOTAL ${unit.toUpperCase()}',
                      value: hero,
                      bold: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '*** THANKS FOR LIFTING ***',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (showWatermark)
                      const ShareWatermarkBadge(color: Color(0xFF333333)),
                  ],
                ),
              ),
            ),
          ),
          if (data.highlights.isEmpty)
            const ShareLockOverlay(message: 'Log more to unlock'),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Courier',
      fontSize: bold ? 15 : 12,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      color: const Color(0xFF1A1A1A),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-painted dashed line — matches the thermal-printer aesthetic.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dashes = (width / 6).floor();
        return Row(
          children: List.generate(dashes, (_) {
            return Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                color: const Color(0xFF333333),
              ),
            );
          }),
        );
      },
    );
  }
}
