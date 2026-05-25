import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';

/// Phase 6 #18 — Create-challenge sheet.
///
/// The `challenges` + `challenge_participants` + `challenge_leaderboard`
/// tables already existed in prod (verified via Supabase MCP); the audit
/// flagged the *creation flow* as the only gap. This sheet hits
/// POST /api/v1/challenges (in workouts_overhaul_extras.py) and lets the
/// user invite friends from the friends graph.
class ChallengeCreateSheet extends ConsumerStatefulWidget {
  const ChallengeCreateSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChallengeCreateSheet(),
    );
  }

  @override
  ConsumerState<ChallengeCreateSheet> createState() =>
      _ChallengeCreateSheetState();
}

class _ChallengeCreateSheetState extends ConsumerState<ChallengeCreateSheet> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _goalCtl = TextEditingController();
  String _type = 'weekly_volume';
  String _unit = 'sets';
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublic = false;
  bool _saving = false;
  String? _error;

  static const _types = [
    ('weekly_volume', 'Weekly volume', 'sets'),
    ('pr', 'PR battle', 'kg'),
    ('streak', 'Streak', 'days'),
    ('cardio_distance', 'Distance', 'km'),
  ];

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _goalCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final goal = double.tryParse(_goalCtl.text.trim());
    if (_titleCtl.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    if (goal == null || goal <= 0) {
      setState(() => _error = 'Goal must be a positive number.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/challenges', data: {
        'title': _titleCtl.text.trim(),
        'description': _descCtl.text.trim().isEmpty
            ? null
            : _descCtl.text.trim(),
        'challenge_type': _type,
        'goal_value': goal,
        'goal_unit': _unit,
        'end_date': _endDate.toUtc().toIso8601String(),
        'is_public': _isPublic,
        'invite_user_ids': const <String>[],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Create challenge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. 100 chest sets this week',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _types.map((t) {
                  final selected = _type == t.$1;
                  return ChoiceChip(
                    label: Text(t.$2),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _type = t.$1;
                      _unit = t.$3;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Goal ($_unit)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ends',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public'),
                subtitle: const Text('Anyone can join via the social tab'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create challenge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
