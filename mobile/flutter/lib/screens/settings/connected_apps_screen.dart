import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/sync_repository.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Catalog of supported providers. `requiresCredentials=true` means the
/// provider doesn't expose a public OAuth flow and the user must type an
/// email/password into a native sheet (Garmin, Peloton); everything else
/// opens the authorization URL in the in-app browser.
class _ProviderCatalog {
  static const entries = <_ProviderEntry>[
    _ProviderEntry(
      slug: 'strava',
      displayName: 'Strava',
      subtitle: 'Runs, rides, swims — push webhook, <1s latency.',
      icon: Icons.directions_run,
      color: Color(0xFFFC4C02),
      requiresCredentials: false,
    ),
    _ProviderEntry(
      slug: 'fitbit',
      displayName: 'Fitbit',
      subtitle: 'Activity, heart rate, sleep. Push webhook.',
      icon: Icons.watch,
      color: Color(0xFF00B0B9),
      requiresCredentials: false,
    ),
    _ProviderEntry(
      slug: 'garmin',
      displayName: 'Garmin Connect',
      subtitle: 'Personal use only — scrapes Connect IQ, may break.',
      icon: Icons.watch_outlined,
      color: Color(0xFF000000),
      requiresCredentials: true,
    ),
    _ProviderEntry(
      slug: 'apple_health',
      displayName: 'Apple Health',
      subtitle: 'iOS only — on-device HealthKit bridge.',
      icon: Icons.favorite,
      color: Color(0xFFFF3B30),
      requiresCredentials: false,
      isDeviceOnly: true,
    ),
    _ProviderEntry(
      slug: 'peloton',
      displayName: 'Peloton',
      subtitle: 'Cycle + Tread classes. Cookie auth, no OAuth.',
      icon: Icons.pedal_bike,
      color: Color(0xFF181818),
      requiresCredentials: true,
    ),
  ];
}

class _ProviderEntry {
  final String slug;
  final String displayName;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool requiresCredentials;
  final bool isDeviceOnly;

  const _ProviderEntry({
    required this.slug,
    required this.displayName,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.requiresCredentials = false,
    this.isDeviceOnly = false,
  });
}

/// Async state for the list of connected accounts keyed by provider slug.
final _connectedAccountsProvider =
    FutureProvider.autoDispose<Map<String, ConnectedSyncAccount>>((ref) async {
  final repo = ref.watch(syncRepositoryProvider);
  final accounts = await repo.listAccounts();
  return <String, ConnectedSyncAccount>{
    for (final account in accounts) account.provider: account,
  };
});

/// Connected Apps settings screen — lists Strava / Garmin / Fitbit / Apple
/// Health / Peloton with Connect / Syncing / Reconnect states and per-account
/// toggles (auto-import, import_strength, import_cardio).
class ConnectedAppsScreen extends ConsumerWidget {
  const ConnectedAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final asyncAccounts = ref.watch(_connectedAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Apps'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(_connectedAccountsProvider.future),
        child: asyncAccounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(message: '$e', onRetry: () {
            ref.invalidate(_connectedAccountsProvider);
          }),
          data: (connected) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(accent: accent),
              const SizedBox(height: 12),
              for (final entry in _ProviderCatalog.entries) ...[
                _ProviderTile(
                  entry: entry,
                  account: connected[entry.slug],
                  accent: accent,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              const _PrivacyFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────── Header + Footer ──────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: accent.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sync, color: accent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Connect your favorite fitness apps to automatically import runs, '
                'rides, and workouts. Data flows both ways — ${Branding.appName} workouts can '
                'also show up in Strava.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Privacy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 6),
          Text(
            'Access tokens are encrypted at rest with AES-GCM. We never share your '
            'data with third parties. You can disconnect any app at any time — we '
            'also notify the provider to stop sending us data.',
            style: TextStyle(fontSize: 12, height: 1.45, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────── Provider Tile ──────────────────────────

class _ProviderTile extends ConsumerStatefulWidget {
  const _ProviderTile({
    required this.entry,
    required this.account,
    required this.accent,
  });

  final _ProviderEntry entry;
  final ConnectedSyncAccount? account;
  final Color accent;

  @override
  ConsumerState<_ProviderTile> createState() => _ProviderTileState();
}

class _ProviderTileState extends ConsumerState<_ProviderTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final account = widget.account;
    final status = _resolveStatus(account);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: e.color.withOpacity(0.15),
                  foregroundColor: e.color,
                  radius: 22,
                  child: Icon(e.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(e.subtitle,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                _StatusPill(status: status, accent: widget.accent),
              ],
            ),
            if (account != null) ...[
              const SizedBox(height: 10),
              _AccountDetail(account: account, accent: widget.accent),
              const SizedBox(height: 8),
              _AccountToggles(
                account: account,
                accent: widget.accent,
                disabled: _busy,
                onChanged: _updateFlag,
              ),
            ],
            const SizedBox(height: 10),
            _buildActionRow(status, account),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(_ProviderStatus status, ConnectedSyncAccount? account) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    switch (status) {
      case _ProviderStatus.notConnected:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.link, size: 18),
              label: Text(widget.entry.isDeviceOnly ? 'Enable' : 'Connect'),
              style: FilledButton.styleFrom(backgroundColor: widget.accent),
            ),
          ],
        );
      case _ProviderStatus.connected:
      case _ProviderStatus.syncing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _confirmDisconnect(account!),
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('Disconnect'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => _manualSync(account!),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Sync now'),
            ),
          ],
        );
      case _ProviderStatus.needsReauth:
      case _ProviderStatus.hasError:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (account != null)
              TextButton.icon(
                onPressed: () => _confirmDisconnect(account),
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Disconnect'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reconnect'),
              style: FilledButton.styleFrom(backgroundColor: widget.accent),
            ),
          ],
        );
    }
  }

  _ProviderStatus _resolveStatus(ConnectedSyncAccount? account) {
    if (account == null) return _ProviderStatus.notConnected;
    if (account.needsReauth) return _ProviderStatus.needsReauth;
    if (account.status == 'revoked') return _ProviderStatus.notConnected;
    if (account.hasError) return _ProviderStatus.hasError;
    if (account.lastSyncAt == null) return _ProviderStatus.syncing;
    return _ProviderStatus.connected;
  }

  // ─────────── Actions ───────────

  Future<void> _connect() async {
    final repo = ref.read(syncRepositoryProvider);
    setState(() => _busy = true);
    try {
      if (widget.entry.isDeviceOnly) {
        // Apple Health has no remote URL to open — the native HealthKit
        // permission sheet opens inside the app via the ``health`` package.
        // We still POST a callback so the "connected" row exists in
        // oauth_sync_accounts and the UI can show toggles.
        await repo.completeAuth('apple_health', code: 'DEVICE');
        await _refresh();
        if (mounted) _toast('Apple Health enabled');
        return;
      }
      if (widget.entry.requiresCredentials) {
        await _showCredentialsDialog();
        return;
      }
      final url = await repo.beginAuth(widget.entry.slug);
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) throw Exception('Failed to open browser');
      // The deep-link handler in main.dart will complete the callback; this
      // screen just waits for the user to come back and pulls the list.
    } catch (e) {
      if (mounted) _toast('Connect failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCredentialsDialog() async {
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign in to ${widget.entry.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.entry.slug == 'garmin'
                  ? 'Garmin requires your account email and password. We store '
                      'the session token encrypted — we never keep the password.'
                  : 'Peloton has no public API. Your credentials are used once, '
                      'then discarded; only a session cookie is kept (encrypted).',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passCtl,
              obscureText: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    final repo = ref.read(syncRepositoryProvider);
    setState(() => _busy = true);
    try {
      await repo.completeAuth(
        widget.entry.slug,
        email: emailCtl.text.trim(),
        password: passCtl.text,
      );
      // Best-effort memory hygiene — clear the buffer after submission.
      passCtl.clear();
      await _refresh();
      if (mounted) _toast('${widget.entry.displayName} connected');
    } catch (e) {
      if (mounted) _toast('Sign-in failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDisconnect(ConnectedSyncAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect ${widget.entry.displayName}?'),
        content: const Text(
          'Previously imported activities will stay in your ${Branding.appName} history. '
          'New activities will stop syncing until you reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(syncRepositoryProvider).disconnectAccount(account.id);
      await _refresh();
      if (mounted) _toast('${widget.entry.displayName} disconnected');
    } catch (e) {
      if (mounted) _toast('Disconnect failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manualSync(ConnectedSyncAccount account) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(syncRepositoryProvider).manualSync(account.id);
      await _refresh();
      if (mounted) {
        _toast(
          'Synced: ${result.syncedCardio} cardio, '
          '${result.syncedStrength} strength',
        );
      }
    } catch (e) {
      if (mounted) _toast('Sync failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateFlag({
    bool? autoImport,
    bool? importCardio,
    bool? importStrength,
  }) async {
    final account = widget.account;
    if (account == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(syncRepositoryProvider).updateAccount(
            account.id,
            autoImport: autoImport,
            importCardio: importCardio,
            importStrength: importStrength,
          );
      await _refresh();
    } catch (e) {
      if (mounted) _toast('Update failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(_connectedAccountsProvider);
    await ref.read(_connectedAccountsProvider.future);
  }

  void _toast(String message, {bool isError = false}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }
}

// ─────────────────────── Status + Toggles widgets ───────────────────────

enum _ProviderStatus { notConnected, connected, syncing, needsReauth, hasError }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final _ProviderStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    late Color fg;
    late Color bg;
    late String label;
    switch (status) {
      case _ProviderStatus.notConnected:
        fg = Colors.grey.shade700;
        bg = Colors.grey.shade200;
        label = 'Not connected';
        break;
      case _ProviderStatus.connected:
        fg = Colors.white;
        bg = accent;
        label = 'Connected';
        break;
      case _ProviderStatus.syncing:
        fg = Colors.white;
        bg = Colors.amber.shade700;
        label = 'Syncing';
        break;
      case _ProviderStatus.needsReauth:
        fg = Colors.white;
        bg = Colors.orange.shade700;
        label = 'Reconnect';
        break;
      case _ProviderStatus.hasError:
        fg = Colors.white;
        bg = Colors.red.shade600;
        label = 'Error';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  const _AccountDetail({required this.account, required this.accent});
  final ConnectedSyncAccount account;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final last = account.lastSyncAt?.toLocal();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              last == null
                  ? 'No sync yet — will run within 15 minutes.'
                  : 'Last synced ${_relativeTime(last)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (account.lastError != null)
            Tooltip(
              message: account.lastError!,
              child: const Icon(Icons.info_outline,
                  size: 14, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _AccountToggles extends StatelessWidget {
  const _AccountToggles({
    required this.account,
    required this.accent,
    required this.disabled,
    required this.onChanged,
  });

  final ConnectedSyncAccount account;
  final Color accent;
  final bool disabled;
  final Future<void> Function({
    bool? autoImport,
    bool? importCardio,
    bool? importStrength,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _toggleRow(
          label: 'Auto-import every 15 min',
          value: account.autoImport,
          onChanged: (v) => onChanged(autoImport: v),
        ),
        _toggleRow(
          label: 'Include cardio sessions',
          value: account.importCardio,
          onChanged: (v) => onChanged(importCardio: v),
        ),
        _toggleRow(
          label: 'Include strength workouts',
          value: account.importStrength,
          onChanged: (v) => onChanged(importStrength: v),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Switch.adaptive(
          value: value,
          activeColor: accent,
          onChanged: disabled ? null : onChanged,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
