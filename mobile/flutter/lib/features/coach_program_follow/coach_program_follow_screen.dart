// Coach-program follow home — Client flavor.
// Renders today's blocks from a coach-assigned program (assigned via web /builder).

import 'package:flutter/material.dart';

class CoachProgramFollowScreen extends StatelessWidget {
  const CoachProgramFollowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s program')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day 1 • Strength', style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            ListTile(title: Text('Squat — 5×5')),
            ListTile(title: Text('Bench Press — 5×5')),
            ListTile(title: Text('Deadlift — 1×5')),
            SizedBox(height: 24),
            Text(
              'Backend wiring fetches reppora_programs by assigned_client_id; '
              'scaffold returns the local fallback for now.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
