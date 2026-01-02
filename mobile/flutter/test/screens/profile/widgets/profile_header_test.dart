import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/profile/widgets/profile_header.dart';

void main() {
  group('ProfileHeader', () {
    testWidgets('displays user name correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              name: 'John Doe',
              email: 'john@example.com',
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays user email correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              name: 'John Doe',
              email: 'john@example.com',
            ),
          ),
        ),
      );

      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('shows default avatar icon when no photo URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              name: 'John Doe',
              email: 'john@example.com',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows avatar icon when photo URL is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              name: 'John Doe',
              email: 'john@example.com',
              photoUrl: '',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ProfileHeader(
              name: 'Jane Doe',
              email: 'jane@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ProfileHeader(
              name: 'Jane Doe',
              email: 'jane@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });
  });
}
