// Quick-assign existing program to a client — Coach flavor.
// Backed by POST /api/v1/programs/{id}/assign.

import 'package:flutter/material.dart';

class CoachQuickAssignScreen extends StatefulWidget {
  const CoachQuickAssignScreen({super.key});

  @override
  State<CoachQuickAssignScreen> createState() => _CoachQuickAssignScreenState();
}

class _CoachQuickAssignScreenState extends State<CoachQuickAssignScreen> {
  String? _selectedProgram;
  String? _selectedClient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick-assign')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pick a program template'),
            DropdownButton<String>(
              value: _selectedProgram,
              hint: const Text('Choose…'),
              items: const [
                DropdownMenuItem(value: '5x5', child: Text('5×5 Strength')),
                DropdownMenuItem(value: 'cut', child: Text('12-week Cut')),
              ],
              onChanged: (v) => setState(() => _selectedProgram = v),
            ),
            const SizedBox(height: 16),
            const Text('Pick a client'),
            DropdownButton<String>(
              value: _selectedClient,
              hint: const Text('Choose…'),
              items: const [
                DropdownMenuItem(value: 'alice', child: Text('Alice S.')),
                DropdownMenuItem(value: 'bob', child: Text('Bob J.')),
              ],
              onChanged: (v) => setState(() => _selectedClient = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  (_selectedProgram == null || _selectedClient == null) ? null : _assign,
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _assign() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigned $_selectedProgram → $_selectedClient')),
    );
  }
}
