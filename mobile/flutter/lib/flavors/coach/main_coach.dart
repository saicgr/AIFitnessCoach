// Reppora Coach flavor entrypoint.
//
// Build: flutter run --flavor coach -t lib/flavors/coach/main_coach.dart
// Bundle ID: com.reppora.coach, App Store name: Reppora for Coach.
//
// The Coach flavor is REPLY/MONITOR only — program building stays on the
// web app per docs/strategy/STRATEGY.md.
// DO NOT run `dart run build_runner build`. Flutter pinned 3.44.6.

import 'package:flutter/material.dart';

import 'reppora_coach_config.dart';
import '../../features/coach_inbox/coach_inbox_screen.dart';
import '../../features/coach_quick_assign/coach_quick_assign_screen.dart';

void main() {
  runApp(const RepporaCoachApp());
}

class RepporaCoachApp extends StatelessWidget {
  const RepporaCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = RepporaCoachConfig.values;
    return MaterialApp(
      title: cfg.appStoreName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A5DFF)),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const _CoachHome(),
      routes: {
        '/inbox': (_) => const CoachInboxScreen(),
        '/quick-assign': (_) => const CoachQuickAssignScreen(),
      },
    );
  }
}

class _CoachHome extends StatelessWidget {
  const _CoachHome();

  @override
  Widget build(BuildContext context) {
    final cfg = RepporaCoachConfig.values;
    return Scaffold(
      appBar: AppBar(title: Text(cfg.appStoreName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coach dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/inbox'),
              child: const Text('Open inbox'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pushNamed('/quick-assign'),
              child: const Text('Quick-assign program'),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Authoring lives on the web app — pro.fitwiz.app',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
