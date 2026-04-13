import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/models/mcp_integration.dart';
import '../../data/providers/mcp_integrations_provider.dart';

/// "AI Integrations" settings screen.
///
/// Lets yearly subscribers generate Personal Access Tokens that connect
/// external AI clients (Claude Desktop, ChatGPT, Cursor) to their FitWiz
/// account. Each connection is shown with the scopes granted and a
/// per-row revoke action.
///
/// UX shape mirrors Supabase MCP / GitHub PATs — no cross-device OAuth
/// consent dance. User taps "Create Connection", gets a JSON config
/// block, pastes it into their MCP client, done.
class AiIntegrationsScreen extends ConsumerWidget {
  const AiIntegrationsScreen({super.key});

  // Public docs URL — how to paste the generated config into each client.
  static const _docsUrl = 'https://fitwiz.us/mcp/docs';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mcpIntegrationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI Integrations'),
        centerTitle: false,
        elevation: 0,
      ),
      floatingActionButton: state.hasLoadedOnce && !state.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateFlow(context, ref, accent, isDark),
              icon: const Icon(Icons.add_link),
              label: const Text('Create Connection'),
              backgroundColor: accent,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        color: accent,
        onRefresh: () => ref.read(mcpIntegrationsProvider.notifier).load(),
        child: _buildBody(context, ref, state, accent, isDark),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // BODY
  // ───────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    McpIntegrationsState state,
    Color accent,
    bool isDark,
  ) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (state.error != null && !state.hasLoadedOnce) {
      return _ErrorView(
        message: state.error!,
        accent: accent,
        onRetry: () => ref.read(mcpIntegrationsProvider.notifier).load(),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _HeaderCard(accent: accent, isDark: isDark, onOpenDocs: _openDocs),
        const SizedBox(height: 24),

        if (state.error != null && state.hasLoadedOnce) ...[
          _InlineErrorBanner(
            message: state.error!,
            onDismiss: () =>
                ref.read(mcpIntegrationsProvider.notifier).clearError(),
          ),
          const SizedBox(height: 16),
        ],

        _SectionLabel(
          'CONNECTED ASSISTANTS',
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(height: 8),

        if (state.isEmpty)
          _EmptyState(
            accent: accent,
            onCreate: () => _openCreateFlow(context, ref, accent, isDark),
            onOpenDocs: _openDocs,
          )
        else
          ...state.integrations.map(
            (integration) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IntegrationCard(
                integration: integration,
                accent: accent,
                isDark: isDark,
                isDisconnecting:
                    state.disconnectingId == integration.id,
                onDisconnect: () =>
                    _confirmAndDisconnect(context, ref, integration, accent),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // ACTIONS
  // ───────────────────────────────────────────────

  Future<void> _openDocs() async {
    try {
      await launchUrl(
        Uri.parse(_docsUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('❌ [AIIntegrations] Could not open docs URL: $e');
    }
  }

  /// The full Create Connection flow.
  /// Step 1: name + Quick Setup vs Custom picker (bottom sheet).
  /// Step 2a (Quick): mint with default scopes + show Connection Ready.
  /// Step 2b (Custom): scope picker → mint → show Connection Ready.
  Future<void> _openCreateFlow(
    BuildContext context,
    WidgetRef ref,
    Color accent,
    bool isDark,
  ) async {
    HapticFeedback.selectionClick();

    final result = await showModalBottomSheet<_CreateFlowResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _CreateConnectionSheet(
        accent: accent,
        isDark: isDark,
      ),
    );

    if (result == null || !context.mounted) return;

    final created = await ref.read(mcpIntegrationsProvider.notifier).createPat(
          name: result.name,
          scopes: result.scopes, // null = Quick Setup (backend defaults)
        );

    if (!context.mounted) return;

    if (created == null) {
      // Error state is already surfaced via the inline error banner.
      final err = ref.read(mcpIntegrationsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not create connection.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show the "Connection Ready" sheet with copy buttons.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // user must explicitly acknowledge
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ConnectionReadySheet(
        creation: created,
        accent: accent,
        isDark: isDark,
      ),
    );
  }

  Future<void> _confirmAndDisconnect(
    BuildContext context,
    WidgetRef ref,
    McpIntegration integration,
    Color accent,
  ) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect this assistant?'),
          content: Text(
            '${integration.name} will immediately lose access to your '
            'FitWiz data. You can create a new connection anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(mcpIntegrationsProvider.notifier)
        .disconnect(integration);

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${integration.name} disconnected'
              : 'Could not disconnect ${integration.name}.',
        ),
        backgroundColor:
            ok ? accent.withValues(alpha: 0.9) : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================
// CREATE FLOW — SHEET + RESULT
// ============================================

class _CreateFlowResult {
  final String name;
  /// null → Quick Setup (backend applies defaults).
  final List<String>? scopes;

  const _CreateFlowResult({required this.name, this.scopes});
}

/// Catalog of scopes — mirrors backend MCPConfig.SCOPES. Kept here (not
/// fetched) so the create flow works offline and so we can order them
/// semantically (read-first, write-next, coach/export last).
const _allScopes = <_ScopeDef>[
  _ScopeDef('read:profile', 'Read profile', 'Name, goals, preferences'),
  _ScopeDef('read:workouts', 'Read workouts', 'Your plan and history'),
  _ScopeDef('read:nutrition', 'Read nutrition', 'Meals and macros'),
  _ScopeDef('read:scores', 'Read scores', 'Strength and readiness'),
  _ScopeDef('write:logs', 'Log meals & sets', 'Add meals, water, sets, weight'),
  _ScopeDef('write:workouts', 'Modify workouts', 'Generate and edit plans'),
  _ScopeDef('chat:coach', 'Chat with coach', 'Full AI coach conversations'),
  _ScopeDef('export:data', 'Export data', 'Download reports and archives'),
];

class _ScopeDef {
  final String key;
  final String label;
  final String description;
  const _ScopeDef(this.key, this.label, this.description);
}

class _CreateConnectionSheet extends StatefulWidget {
  final Color accent;
  final bool isDark;
  const _CreateConnectionSheet({required this.accent, required this.isDark});

  @override
  State<_CreateConnectionSheet> createState() => _CreateConnectionSheetState();
}

class _CreateConnectionSheetState extends State<_CreateConnectionSheet> {
  final _nameController = TextEditingController(text: 'My Connection');
  bool _showCustom = false;
  // Defaults to all scopes — if user opens Custom and unchecks some,
  // they get a reduced set. Quick Setup bypasses this entirely.
  late final Set<String> _selected = _allScopes.map((s) => s.key).toSet();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = widget.accent;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Create Connection',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Generate a connection token you'll paste into Claude, "
                "ChatGPT, or Cursor. Only you can see this token.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Name ─────────────────────────────────────────────────
              Text(
                'Name',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'My Laptop Claude',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Custom scope picker (collapsed by default) ───────────
              if (_showCustom) ...[
                Text(
                  'Permissions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uncheck anything you want to withhold from this connection.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                ..._allScopes.map((s) => _scopeTile(s, accent)),
                const SizedBox(height: 20),
              ],

              // ─── CTAs ────────────────────────────────────────────────
              Row(
                children: [
                  if (!_showCustom) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showCustom = true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Custom',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _submit(quickSetup: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Quick Setup',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _showCustom = false),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => _submit(quickSetup: false),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Generate',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeTile(_ScopeDef def, Color accent) {
    final theme = Theme.of(context);
    final checked = _selected.contains(def.key);
    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _selected.remove(def.key);
          } else {
            _selected.add(def.key);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: checked,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(def.key);
                    } else {
                      _selected.remove(def.key);
                    }
                  });
                },
                activeColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    def.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit({required bool quickSetup}) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this connection a name first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _CreateFlowResult(
        name: name,
        // Quick Setup → null means "use backend defaults (all scopes)".
        // Custom → explicit subset.
        scopes: quickSetup ? null : _selected.toList(),
      ),
    );
  }
}

// ============================================
// CONNECTION READY SHEET
// ============================================

class _ConnectionReadySheet extends StatefulWidget {
  final McpPatCreation creation;
  final Color accent;
  final bool isDark;

  const _ConnectionReadySheet({
    required this.creation,
    required this.accent,
    required this.isDark,
  });

  @override
  State<_ConnectionReadySheet> createState() => _ConnectionReadySheetState();
}

class _ConnectionReadySheetState extends State<_ConnectionReadySheet> {
  String _justCopied = ''; // 'json' | 'token' | ''

  /// Pretty-print the server-provided JSON config so it paste-previews nicely.
  late final String _prettyConfig = const JsonEncoder.withIndent('  ')
      .convert(widget.creation.connectionConfig);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accent;
    final textMuted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Hero.
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.check_circle, color: accent, size: 44),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Connection ready!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Paste this config into your AI client.',
                style: theme.textTheme.bodyMedium?.copyWith(color: textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // Security warning — copying a token = sensitive action.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade400.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.shade400.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.orange.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Treat this token like a password. Anyone with it can '
                      "read and modify your FitWiz data within the scopes "
                      "you granted. You can revoke it anytime from this screen.",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // JSON config block — copy-paste target.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                _prettyConfig,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _copy(_prettyConfig, 'json'),
                    icon: Icon(
                      _justCopied == 'json' ? Icons.check : Icons.copy,
                      size: 16,
                    ),
                    label: Text(
                      _justCopied == 'json' ? 'Copied!' : 'Copy config',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _copy(widget.creation.token, 'token'),
                    icon: Icon(
                      _justCopied == 'token' ? Icons.check : Icons.vpn_key,
                      size: 16,
                      color: accent,
                    ),
                    label: Text(
                      _justCopied == 'token' ? 'Copied!' : 'Copy token only',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: accent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meta row — name + scopes count. Reassures user what they made.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.creation.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.creation.scopes.length} permission${widget.creation.scopes.length == 1 ? '' : 's'} granted',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("I've saved my config  ·  Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(String value, String kind) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _justCopied = kind);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _justCopied = '');
    });
  }
}

// ============================================
// SECTION LABEL
// ============================================

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================
// HEADER CARD
// ============================================

class _HeaderCard extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback onOpenDocs;
  const _HeaderCard({
    required this.accent,
    required this.isDark,
    required this.onOpenDocs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textMuted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hub_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect FitWiz anywhere',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create a connection to plug FitWiz into Claude, ChatGPT, Cursor, '
            'or any MCP-compatible AI tool. Tap Create Connection, paste the '
            'config into your tool, done. Yearly subscription required.',
            style: TextStyle(fontSize: 14, height: 1.45, color: textMuted),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpenDocs,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'Setup guide',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// INTEGRATION CARD
// ============================================

class _IntegrationCard extends StatelessWidget {
  final McpIntegration integration;
  final Color accent;
  final bool isDark;
  final bool isDisconnecting;
  final VoidCallback onDisconnect;

  const _IntegrationCard({
    required this.integration,
    required this.accent,
    required this.isDark,
    required this.isDisconnecting,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textMuted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final cardColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;
    final borderColor = theme.dividerColor.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initialFor(integration.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              integration.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (integration.authType ==
                              McpIntegrationAuthType.oauth)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OAuth',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(integration),
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (integration.scopes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Granted permissions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: integration.scopes
                    .map((s) => _ScopeChip(scope: s, accent: accent))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isDisconnecting ? null : onDisconnect,
                icon: isDisconnecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade400,
                        ),
                      )
                    : Icon(Icons.link_off,
                        size: 18, color: Colors.red.shade400),
                label: Text(
                  isDisconnecting ? 'Disconnecting…' : 'Disconnect',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Colors.red.shade400.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  static String _subtitleFor(McpIntegration i) {
    final connected = 'Created ${_friendlyDate(i.createdAt)}';
    if (i.lastUsedAt == null) return '$connected · Never used';
    return '$connected · Last used ${_friendlyDate(i.lastUsedAt!)}';
  }

  static String _friendlyDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// ============================================
// SCOPE CHIP
// ============================================

class _ScopeChip extends StatelessWidget {
  final String scope;
  final Color accent;
  const _ScopeChip({required this.scope, required this.accent});

  static const _labels = <String, String>{
    'read:profile': 'Read profile',
    'read:workouts': 'Read workouts',
    'read:nutrition': 'Read nutrition',
    'read:scores': 'Read scores',
    'write:logs': 'Log meals & sets',
    'write:workouts': 'Modify workouts',
    'chat:coach': 'Chat with coach',
    'export:data': 'Export data',
  };

  bool get _isWriteScope =>
      scope.startsWith('write:') ||
      scope.startsWith('export:') ||
      scope.startsWith('chat:');

  @override
  Widget build(BuildContext context) {
    final label = _labels[scope] ?? scope;
    final color = _isWriteScope ? accent : accent.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================
// EMPTY STATE
// ============================================

class _EmptyState extends StatelessWidget {
  final Color accent;
  final VoidCallback onCreate;
  final VoidCallback onOpenDocs;
  const _EmptyState({
    required this.accent,
    required this.onCreate,
    required this.onOpenDocs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textMuted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.power_outlined, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one to start using FitWiz in Claude, ChatGPT, or Cursor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_link, size: 18),
            label: const Text(
              'Create Connection',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onOpenDocs,
            icon: Icon(Icons.open_in_new, size: 14, color: accent),
            label: Text(
              'Setup guide',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// ERROR VIEW
// ============================================

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 64),
        Icon(
          Icons.cloud_off_outlined,
          size: 56,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Could not load integrations',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// INLINE ERROR BANNER
// ============================================

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _InlineErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade400.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
