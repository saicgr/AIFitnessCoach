import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a testable widget wrapper with MaterialApp and ProviderScope
Widget createTestWidget(Widget child, {bool isDark = true}) {
  return ProviderScope(
    child: MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: child),
    ),
  );
}

/// Creates a testable widget wrapper without Scaffold (for sheet testing)
Widget createTestWidgetNoScaffold(Widget child, {bool isDark = true}) {
  return ProviderScope(
    child: MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: child,
    ),
  );
}

/// Extension for common test widget finders
extension TestFinders on CommonFinders {
  /// Finds widgets by semantic label
  Finder bySemanticsLabel(String label) =>
      find.bySemanticsLabel(label);
}

/// Test helper to pump widget with multiple frames for animations
extension WidgetTesterExtensions on WidgetTester {
  /// Pumps the widget with a short delay to allow animations
  Future<void> pumpAndSettle([Duration duration = const Duration(milliseconds: 100)]) async {
    await pump(duration);
    await pumpAndSettle();
  }
}
