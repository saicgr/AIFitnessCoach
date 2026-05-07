// Coach inbox — Coach flavor.
// Lists threads from /api/v1/threads + recent messages preview.

import 'package:flutter/material.dart';

class CoachInboxScreen extends StatelessWidget {
  const CoachInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockThreads = <_InboxRow>[
      const _InboxRow(client: 'Alice S.', preview: 'Felt strong today!'),
      const _InboxRow(client: 'Bob J.', preview: 'Quick form check?'),
      const _InboxRow(client: 'Cara T.', preview: 'Travelling Mon-Wed.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: ListView.builder(
        itemCount: mockThreads.length,
        itemBuilder: (_, i) {
          final t = mockThreads[i];
          return ListTile(
            title: Text(t.client),
            subtitle: Text(t.preview),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}

class _InboxRow {
  final String client;
  final String preview;
  const _InboxRow({required this.client, required this.preview});
}
