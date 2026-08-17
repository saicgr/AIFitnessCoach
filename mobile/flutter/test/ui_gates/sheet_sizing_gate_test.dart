// Bottom-sheet sizing gate.
//
// WHY: a bottom sheet can be "broken" without ever throwing. Nothing in
// Flutter complains when a sheet's scrollable viewport is squeezed to 20pt —
// it just renders a sliced-in-half card and a band of empty glass, which is
// exactly how the gym switcher ("Switch Gym") shipped.
//
// Two mechanisms caused that, and this file locks both:
//
//  1. DOUBLE FRACTIONAL SIZING. `GlassSheet` caps its own height at
//     `maxHeightFraction` (0.9). A `DraggableScrollableSheet` child then sizes
//     itself as a fraction OF THAT BOX, so `initialChildSize: 0.55` silently
//     resolved to 0.495 of the screen. Every one of the ~30 sheets built this
//     way was ~11% shorter than its author asked for; the switcher, whose
//     chrome alone measured 376pt, had nothing left for its list.
//
//  2. STARVED CONTENT. A sheet pinned to a hard-coded fraction cannot react to
//     its own chrome. The fix is to size by content — `Column(mainAxisSize.min)`
//     plus a `Flexible` shrink-wrapping list — so the list keeps whatever the
//     chrome does not take and the sheet grows until GlassSheet's cap stops it.
//
// The second test reproduces the real switcher's chrome inventory (handle,
// header, Travel Mode tile, "Find a gym near me" row, docked add button) at the
// measured heights, so a future edit that re-adds a fixed fraction — or piles
// another 100pt row into the header — fails here rather than in a screenshot.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/glass_sheet.dart';

/// Real measured chrome of the gym-switcher picker, top to bottom.
const double _kHandle = 24;
const double _kHeader = 78;
const double _kTravelTile = 106;
const double _kFindGymRow = 66;
const double _kAddButton = 72;
const double _kGymCard = 96;

/// A list viewport smaller than this cannot show even one gym card, which is
/// the whole reason the sheet exists.
const double _kUsableViewport = _kGymCard;

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(bottom: 102, top: 141);
  addTearDown(tester.view.reset);

  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navKey,
    home: const Scaffold(body: SizedBox.expand()),
  ));
  return navKey.currentContext!;
}

void main() {
  testWidgets(
      'GlassSheet does not double-apply its height cap to a self-sizing child',
      (tester) async {
    final ctx = await _pumpHost(tester);
    final screenHeight = MediaQuery.of(ctx).size.height;

    unawaitedSheet(showGlassSheet(
      context: ctx,
      builder: (_) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            children: const [SizedBox(height: 4000)],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final dssHeight =
        tester.getSize(find.byType(DraggableScrollableSheet)).height;
    // The contract: fractions resolve against the sheet's USABLE height —
    // the screen minus the home-indicator band the sheet reserves below its
    // child — never against `maxHeightFraction` on top of that.
    final usableHeight = screenHeight - MediaQuery.of(ctx).padding.bottom;

    expect(
      dssHeight,
      closeTo(usableHeight * 0.55, 1.0),
      reason: 'initialChildSize resolved to '
          '${(dssHeight / usableHeight).toStringAsFixed(3)} of the usable '
          "height, not 0.55 — GlassSheet's maxHeightFraction is being "
          'multiplied in again.',
    );
  });

  testWidgets('a content-sized sheet never starves its list', (tester) async {
    final ctx = await _pumpHost(tester);

    unawaitedSheet(showGlassSheet(
      context: ctx,
      builder: (sheetContext) => GlassSheet(
        showHandle: false,
        maxHeightFraction: 0.88,
        // The add-button row below adds the home-indicator inset itself;
        // letting GlassSheet add it too paints a dead band under the button.
        reserveBottomInset: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: _kHandle),
            const SizedBox(height: _kHeader),
            const SizedBox(height: _kTravelTile),
            const SizedBox(height: _kFindGymRow),
            Flexible(
              child: ListView.builder(
                key: const Key('gym_list'),
                shrinkWrap: true,
                // Explicit padding matters: a null padding makes ListView
                // silently inherit MediaQuery's bottom inset.
                padding: EdgeInsets.zero,
                itemCount: 4,
                itemBuilder: (_, __) => const SizedBox(height: _kGymCard),
              ),
            ),
            SizedBox(
              height: _kAddButton + MediaQuery.of(sheetContext).padding.bottom,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final listHeight = tester.getSize(find.byKey(const Key('gym_list'))).height;
    expect(
      listHeight,
      greaterThanOrEqualTo(_kUsableViewport),
      reason: 'The profile list got ${listHeight.toStringAsFixed(1)}pt — less '
          'than one ${_kGymCard.toStringAsFixed(0)}pt gym card. Chrome above it '
          'has grown past what the sheet can give back.',
    );

    // And the sheet must stop at its cap rather than run off the screen.
    final sheetHeight = tester.getSize(find.byType(GlassSheet).first).height;
    expect(sheetHeight,
        lessThanOrEqualTo(MediaQuery.of(ctx).size.height * 0.88 + 0.5));

    expect(tester.takeException(), isNull);
  });

  testWidgets('a content-sized sheet shrinks to fit a single row',
      (tester) async {
    final ctx = await _pumpHost(tester);

    unawaitedSheet(showGlassSheet(
      context: ctx,
      builder: (_) => GlassSheet(
        showHandle: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: _kHandle),
            const SizedBox(height: _kHeader),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: 1,
                itemBuilder: (_, __) => const SizedBox(height: _kGymCard),
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final sheetHeight = tester.getSize(find.byType(GlassSheet).first).height;
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    expect(
      sheetHeight,
      closeTo(_kHandle + _kHeader + _kGymCard + safeBottom, 1.0),
      reason: 'A one-gym sheet must be one gym tall, not a fixed fraction of '
          'the screen with empty glass under it.',
    );
  });

  _bottomInsetTests();
}

/// `showGlassSheet` returns the route's future, which only completes when the
/// sheet is popped — these tests never pop, so the future is intentionally
/// dropped.
void unawaitedSheet(Future<void> future) {}

/// The home-indicator band belongs to exactly one widget.
///
/// Sheet bodies routinely end in `SizedBox(height: MediaQuery.padding.bottom
/// + 16)` or a `SafeArea`. `GlassSheet` reserves that band itself, so unless it
/// hides the inset from its child the two stack and the sheet ends in a strip
/// of empty glass.
void _bottomInsetTests() {
  testWidgets('GlassSheet hides the bottom inset it already reserves',
      (tester) async {
    final ctx = await _pumpHost(tester);
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    expect(safeBottom, greaterThan(0));

    unawaitedSheet(showGlassSheet(
      context: ctx,
      builder: (_) => GlassSheet(
        showHandle: false,
        child: Builder(
          builder: (inner) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(key: Key('body'), height: 200),
              // The idiom found across ~50 sheet bodies in this app.
              SizedBox(height: MediaQuery.of(inner).padding.bottom + 16),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final bodyBottom = tester.getBottomLeft(find.byKey(const Key('body'))).dy;
    final sheetBottom = tester.getBottomLeft(find.byType(GlassSheet).first).dy;
    expect(
      sheetBottom - bodyBottom,
      closeTo(16 + safeBottom, 0.5),
      reason: 'Expected one 16pt gap plus one home-indicator band under the '
          'body. Getting ${(sheetBottom - bodyBottom).toStringAsFixed(1)}pt '
          'means the inset is being reserved twice.',
    );
  });

  testWidgets('opting out of the reserve keeps the real inset visible',
      (tester) async {
    final ctx = await _pumpHost(tester);
    final safeBottom = MediaQuery.of(ctx).padding.bottom;

    late double seenByChild;
    unawaitedSheet(showGlassSheet(
      context: ctx,
      builder: (_) => GlassSheet(
        showHandle: false,
        reserveBottomInset: false,
        child: Builder(builder: (inner) {
          seenByChild = MediaQuery.of(inner).padding.bottom;
          return const SizedBox(height: 200);
        }),
      ),
    ));
    await tester.pumpAndSettle();

    expect(seenByChild, safeBottom,
        reason: 'A sheet that pads itself must still be told the real inset.');
  });
}
