/// Imports-feature privacy controls — surfaced inside the Privacy & Data
/// settings page.
///
/// Two controls:
///   1. "Always ask before routing" — when enabled, every shared payload
///      skips the auto-route countdown and lands directly on the chooser
///      sheet. Persisted in SharedPreferences (not server-side — it's a
///      local UX preference).
///   2. "Clear shared history" — calls DELETE /share/history.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/imports_api_service.dart';

const String kImportsAlwaysAskPrefKey = 'imports.always_ask_before_routing';

/// Provider exposing the current value of the always-ask preference.
/// Returns false by default — auto-route is the default UX.
final importsAlwaysAskProvider =
    StateNotifierProvider<ImportsAlwaysAskNotifier, bool>(
  (ref) => ImportsAlwaysAskNotifier()..load(),
);

class ImportsAlwaysAskNotifier extends StateNotifier<bool> {
  ImportsAlwaysAskNotifier() : super(false);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(kImportsAlwaysAskPrefKey) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> set(bool v) async {
    state = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kImportsAlwaysAskPrefKey, v);
    } catch (_) {/* best-effort */}
  }
}

class ImportsPrivacySection extends ConsumerWidget {
  const ImportsPrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alwaysAsk = ref.watch(importsAlwaysAskProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Imports',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Always ask before routing'),
            subtitle: const Text(
              'Skip the auto-route countdown — every share opens the chooser.',
            ),
            value: alwaysAsk,
            onChanged: (v) =>
                ref.read(importsAlwaysAskProvider.notifier).set(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear shared history'),
            subtitle: const Text(
              "Removes every record from your Imports list. Imported workouts, recipes, and food logs themselves stay.",
            ),
            onTap: () => _confirmClear(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear shared history?'),
        content: const Text(
          "Every row in your Imports list is removed. The workouts, recipes, "
          "and food logs you imported stay where they are.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(importsApiServiceProvider).clearAll();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Shared history cleared.'),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't clear — try again later."),
      ));
    }
  }
}
