// Reppora Client flavor entrypoint.
//
// Build: flutter run --flavor client -t lib/flavors/client/main_client.dart
// Bundle ID: com.reppora.app, App Store name: Reppora.
//
// Per /Users/saichetangrandhe/Reppora/docs/architecture/reuse-audit.md:
// the Client flavor reuses ~90% of Zealova consumer infra (workout exec,
// food logging, recipes, wearables, offline DB) and adds:
//   - coach-program follow home (lib/features/coach_program_follow)
//   - trainer↔client chat (lib/features/trainer_chat)
//   - "Powered by Reppora" footer (non-removable on Free tier)
//
// DO NOT run `dart run build_runner build` — committed .g.dart files only.
// Flutter pinned 3.38.10 / Dart 3.10.9.

import 'package:flutter/material.dart';

import 'reppora_client_config.dart';
import '../../features/coach_program_follow/coach_program_follow_screen.dart';
import '../../features/trainer_chat/trainer_chat_screen.dart';

void main() {
  runApp(const RepporaClientApp());
}

class RepporaClientApp extends StatelessWidget {
  const RepporaClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = RepporaClientConfig.values;
    return MaterialApp(
      title: cfg.appStoreName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A5DFF)),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const _ClientHome(),
      routes: {
        '/coach-program': (_) => const CoachProgramFollowScreen(),
        '/trainer-chat': (_) => const TrainerChatScreen(),
      },
    );
  }
}

class _ClientHome extends StatelessWidget {
  const _ClientHome();

  @override
  Widget build(BuildContext context) {
    final cfg = RepporaClientConfig.values;
    return Scaffold(
      appBar: AppBar(title: Text(cfg.appStoreName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ${cfg.appStoreName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/coach-program'),
              child: const Text('Today\'s coach program'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pushNamed('/trainer-chat'),
              child: const Text('Message your coach'),
            ),
            const Spacer(),
            if (cfg.poweredByFooter)
              const Center(
                child: Text(
                  'Powered by Reppora',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
