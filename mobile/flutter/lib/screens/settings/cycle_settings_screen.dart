import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/body_analyzer_repository.dart';

/// Cycle-aware reminder opt-in + simple cycle log form.
///
/// Writes the toggle through `/users/me`; the cycle-log form writes
/// directly to Supabase via the user's normal policies (RLS).
class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends ConsumerState<CycleSettingsScreen> {
  bool _enabled = false;
  bool _saving = false;
  DateTime _lastStart = DateTime.now();
  int _cycleLen = 28;
  int _periodLen = 5;

  Future<void> _toggle(bool v) async {
    setState(() {
      _enabled = v;
      _saving = true;
    });
    try {
      await ref
          .read(menstrualCycleRepositoryProvider)
          .setCycleAwareReminders(v);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _enabled = !v);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle-aware reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Skip progress-photo reminders during your period so water '
              'retention doesn\'t skew your photos. Entirely optional.',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              value: _enabled,
              onChanged: _saving ? null : _toggle,
              title: Text('Enable cycle-aware reminders',
                  style: TextStyle(color: textPrimary)),
              subtitle: Text(
                  'Suppresses photo reminders during menstruation days 1–5.',
                  style: TextStyle(color: textMuted, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Text(
              'Cycle log',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('Latest cycle start',
                  style: TextStyle(color: textPrimary)),
              subtitle: Text(
                '${_lastStart.toLocal().year}-${_lastStart.month.toString().padLeft(2, '0')}-${_lastStart.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: textMuted),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: _pickDate,
              ),
            ),
            ListTile(
              title: Text('Cycle length', style: TextStyle(color: textPrimary)),
              trailing: Text('$_cycleLen days', style: TextStyle(color: textMuted)),
            ),
            Slider(
              value: _cycleLen.toDouble(),
              min: 14,
              max: 60,
              divisions: 46,
              label: '$_cycleLen',
              onChanged: (v) => setState(() => _cycleLen = v.round()),
            ),
            ListTile(
              title: Text('Period length', style: TextStyle(color: textPrimary)),
              trailing: Text('$_periodLen days', style: TextStyle(color: textMuted)),
            ),
            Slider(
              value: _periodLen.toDouble(),
              min: 1,
              max: 14,
              divisions: 13,
              label: '$_periodLen',
              onChanged: (v) => setState(() => _periodLen = v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastStart,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastStart = picked);
  }
}
