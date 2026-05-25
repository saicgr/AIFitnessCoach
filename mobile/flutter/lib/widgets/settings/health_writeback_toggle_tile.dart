import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../services/health_export_service.dart';

import '../../l10n/generated/app_localizations.dart';
/// SLICE_HEALTH_EXPORT — single settings tile that toggles Apple Health /
/// Health Connect write-back.
///
/// Composer (settings_card owner) wires this tile into the settings screen —
/// do NOT compose it here. This widget is responsible only for its own state
/// (toggle, permission request, sync subtitle).
///
/// Usage:
///   HealthWritebackToggleTile(service: ref.read(healthExportServiceProvider))
class HealthWritebackToggleTile extends StatefulWidget {
  final HealthExportService service;

  /// Override the platform label for tests / preview screens.
  final String? labelOverride;

  const HealthWritebackToggleTile({
    super.key,
    required this.service,
    this.labelOverride,
  });

  @override
  State<HealthWritebackToggleTile> createState() =>
      _HealthWritebackToggleTileState();
}

class _HealthWritebackToggleTileState extends State<HealthWritebackToggleTile> {
  bool _enabled = false;
  bool _loading = true;
  bool _pending = false; // disable switch while permission dialog is up
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final on = await widget.service.isEnabled();
    final last = await widget.service.getLastSyncAt();
    if (!mounted) return;
    setState(() {
      _enabled = on;
      _lastSync = last;
      _loading = false;
    });
  }

  String get _platformLabel {
    if (widget.labelOverride != null) return widget.labelOverride!;
    if (Platform.isIOS) return 'Write workouts to Apple Health';
    if (Platform.isAndroid) return 'Write workouts to Health Connect';
    return 'Write workouts to Health';
  }

  Future<void> _handleToggle(bool next) async {
    if (_pending) return;

    // Turning OFF: just persist, no permission flow.
    if (!next) {
      setState(() => _enabled = false);
      await widget.service.setEnabled(false);
      return;
    }

    // Turning ON: request write permissions first. Only flip on success.
    setState(() => _pending = true);
    final granted = await widget.service.requestWritePermissions();
    if (!mounted) return;

    if (!granted) {
      setState(() => _pending = false);
      _showSnack(
        Platform.isIOS
            ? 'Apple Health write permission denied. Enable in Settings → Health → Data Access & Devices → Zealova.'
            : 'Health Connect write permission denied.',
        isError: true,
      );
      return;
    }

    await widget.service.setEnabled(true);
    if (!mounted) return;
    setState(() {
      _enabled = true;
      _pending = false;
    });
    _showSnack('Workouts will now sync to ${Platform.isIOS ? "Apple Health" : "Health Connect"}.');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatLastSync(DateTime when) {
    final delta = DateTime.now().difference(when);
    if (delta.inSeconds < 60) return 'Last sync: just now';
    if (delta.inMinutes < 60) return 'Last sync: ${delta.inMinutes} min ago';
    if (delta.inHours < 24) return 'Last sync: ${delta.inHours} hr ago';
    return 'Last sync: ${delta.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final subtitle = _enabled && _lastSync != null
        ? _formatLastSync(_lastSync!)
        : 'Lets other apps see workouts you log in Zealova.';

    return Semantics(
      label: _platformLabel,
      toggled: _enabled,
      child: SwitchListTile.adaptive(
        title: Text(_platformLabel),
        subtitle: _loading
            ? Text(AppLocalizations.of(context).commonLoading)
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
        value: _enabled,
        onChanged: (_loading || _pending) ? null : _handleToggle,
        activeThumbColor: accent,
        secondary: Icon(
          Platform.isIOS ? Icons.favorite_rounded : Icons.health_and_safety_rounded,
          color: accent,
        ),
      ),
    );
  }
}
