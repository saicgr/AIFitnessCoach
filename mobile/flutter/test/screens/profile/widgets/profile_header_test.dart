import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitwiz/screens/profile/widgets/profile_header.dart';

/// ProfileHeader is a [ConsumerWidget] — it resolves its accent colour through
/// `ref.colors(context)` (which watches `accentColorProvider`), so every pump
/// needs a [ProviderScope] ancestor. The accent notifier hydrates from
/// SharedPreferences, so we seed a fake store to keep the accent deterministic
/// (orange) instead of depending on a real platform channel.
Widget _wrap(Widget child, {ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'accent_color': 'orange'});
  });

  group('ProfileHeader', () {
    testWidgets('displays user name correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'John Doe',
            email: 'john@example.com',
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays user email correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'John Doe',
            email: 'john@example.com',
          ),
        ),
      );

      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('shows default avatar icon when no photo URL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'John Doe',
            email: 'john@example.com',
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows avatar icon when photo URL is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'John Doe',
            email: 'john@example.com',
            photoUrl: '',
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'Jane Doe',
            email: 'jane@example.com',
          ),
          theme: ThemeData.dark(),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileHeader(
            name: 'Jane Doe',
            email: 'jane@example.com',
          ),
          theme: ThemeData.light(),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });
  });
}
