import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/mcp_integration.dart';
import '../../data/providers/mcp_integrations_provider.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_loading_overlay.dart';
import '../../widgets/glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';

/// "AI Integrations" settings screen.
///
/// Lets yearly subscribers generate Personal Access Tokens that connect
/// external AI clients (Claude Desktop, ChatGPT, Cursor) to their Zealova
/// account. Each connection is shown with the scopes granted and a
/// per-row revoke action.
///
/// UX shape mirrors Supabase MCP / GitHub PATs — no cross-device OAuth
/// consent dance. User taps "Create Connection", gets a JSON config
/// block, pastes it into their MCP client, done.
class AiIntegrationsScreen extends ConsumerWidget {
  const AiIntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mcpIntegrationsProvider);
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;
    final accent = tc.accent;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      appBar: ZealovaAppBar(
        kicker: 'CONNECT',
        title: AppLocalizations.of(context).aiIntegrationsAiIntegrations,
        titleSize: 26,
      ),
      floatingActionButton: state.hasLoadedOnce && !state.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateFlow(context, ref, accent, isDark),
              icon: const Icon(Icons.add_link),
              label: Text(
                AppLocalizations.of(context).aiIntegrationsCreateConnection,
              ),
              backgroundColor: accent,
              foregroundColor: tc.accentContrast,
            )
          : null,
      body: AppRefreshIndicator(
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
        onRetry: () => ref.read(mcpIntegrationsProvider.notifier).load(),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _HeaderCard(accent: accent),
        const SizedBox(height: 24),

        if (state.error != null && state.hasLoadedOnce) ...[
          _InlineErrorBanner(
            message: state.error!,
            onDismiss: () =>
                ref.read(mcpIntegrationsProvider.notifier).clearError(),
          ),
          const SizedBox(height: 16),
        ],

        const ZealovaSectionKicker(
          'CONNECTED ASSISTANTS',
          padding: EdgeInsets.only(left: 4),
        ),
        const SizedBox(height: 8),

        if (state.isEmpty)
          _EmptyState(
            accent: accent,
            onCreate: () => _openCreateFlow(context, ref, accent, isDark),
          )
        else
          ...state.integrations.map(
            (integration) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IntegrationCard(
                integration: integration,
                accent: accent,
                isDark: isDark,
                isDisconnecting: state.disconnectingId == integration.id,
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

    final result = await showGlassSheet<_CreateFlowResult>(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: _CreateConnectionSheet(accent: accent, isDark: isDark),
      ),
    );

    if (result == null || !context.mounted) return;

    // The create sheet has already closed by this point, so without an
    // overlay the screen sits silent for the round-trip — show one, per
    // the same pattern as workout completion / regenerate.
    final loading = showGlassLoadingOverlay(
      context,
      message: 'Creating connection…',
    );
    final McpPatCreation? created;
    try {
      created = await ref
          .read(mcpIntegrationsProvider.notifier)
          .createPat(
            name: result.name,
            scopes: result.scopes, // null = Quick Setup (backend defaults)
          );
    } finally {
      loading.dismiss();
    }

    if (!context.mounted) return;

    if (created == null) {
      // Error state is already surfaced via the inline error banner.
      final failedState = ref.read(mcpIntegrationsProvider);
      final err = failedState.error;
      final upgradeUrl = failedState.upgradeUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err ??
                AppLocalizations.of(
                  context,
                ).aiIntegrationsCouldNotCreateConnection,
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: upgradeUrl != null
              ? SnackBarAction(
                  label: 'Upgrade',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(upgradeUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      debugPrint(
                        '❌ [AIIntegrations] Could not open upgrade URL: $e',
                      );
                    }
                  },
                )
              : null,
        ),
      );
      return;
    }

    // Show the "Connection Ready" sheet with copy buttons.
    await showGlassSheet<void>(
      context: context,
      isDismissible: false, // user must explicitly acknowledge
      enableDrag: false,
      builder: (sheetContext) => GlassSheet(
        opaque: true,
        showHandle: false,
        child: _ConnectionReadySheet(
          creation: created!,
          accent: accent,
          isDark: isDark,
        ),
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
          title: Text(
            AppLocalizations.of(context).aiIntegrationsDisconnectThisAssistant,
          ),
          content: Text(
            '${integration.name} will immediately lose access to your '
            '${Branding.appName} data. You can create a new connection anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).buttonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: Text(
                AppLocalizations.of(context).googleCalendarConnectDisconnect,
              ),
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
        backgroundColor: ok
            ? accent.withValues(alpha: 0.9)
            : Colors.red.shade700,
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
                AppLocalizations.of(context).aiIntegrationsCreateConnection,
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
                AppLocalizations.of(context).menuAnalysisName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  ).aiIntegrationsMyLaptopClaude,
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
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Custom scope picker (collapsed by default) ───────────
              if (_showCustom) ...[
                Text(
                  AppLocalizations.of(context).aiIntegrationsPermissions,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  ).aiIntegrationsUncheckAnythingYouWant,
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
                      child: ZealovaButton(
                        label: AppLocalizations.of(context).workoutsCustom,
                        onTap: () => setState(() => _showCustom = true),
                        variant: ZealovaButtonVariant.ghost,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ZealovaButton(
                        label: AppLocalizations.of(
                          context,
                        ).aiIntegrationsQuickSetup,
                        onTap: () => _submit(quickSetup: true),
                        height: 48,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ZealovaButton(
                        label: AppLocalizations.of(context).commonBack,
                        onTap: () => setState(() => _showCustom = false),
                        variant: ZealovaButtonVariant.ghost,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ZealovaButton(
                        label: AppLocalizations.of(
                          context,
                        ).aiIntegrationsGenerate,
                        onTap: _selected.isEmpty
                            ? null
                            : () => _submit(quickSetup: false),
                        height: 48,
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).aiIntegrationsGiveThisConnectionA,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _CreateFlowResult(
        name: name,
        // Quick Setup → null means "use backend defaults" — a safe
        // read-only subset (read:profile/workouts/nutrition), NOT all
        // scopes. Custom → explicit subset the user picked.
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
  late final String _prettyConfig = const JsonEncoder.withIndent(
    '  ',
  ).convert(widget.creation.connectionConfig);

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
                AppLocalizations.of(context).aiIntegrationsConnectionReady,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                AppLocalizations.of(context).aiIntegrationsPasteThisConfigInto,
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
                      "read and modify your ${Branding.appName} data within the scopes "
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
                      _justCopied == 'json'
                          ? AppLocalizations.of(context).aiIntegrationsCopied
                          : AppLocalizations.of(
                              context,
                            ).aiIntegrationsCopyConfig,
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
                    onPressed: () => _copy(widget.creation.token, 'token'),
                    icon: Icon(
                      _justCopied == 'token' ? Icons.check : Icons.vpn_key,
                      size: 16,
                      color: accent,
                    ),
                    label: Text(
                      _justCopied == 'token'
                          ? AppLocalizations.of(context).aiIntegrationsCopied
                          : AppLocalizations.of(
                              context,
                            ).aiIntegrationsCopyTokenOnly,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withValues(alpha: 0.4)),
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
                child: Text(
                  AppLocalizations.of(context).aiIntegrationsIVeSavedMy,
                ),
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
// HEADER CARD
// ============================================

class _HeaderCard extends StatelessWidget {
  final Color accent;
  const _HeaderCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hub_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect ${Branding.appName} anywhere',
                  style: ZType.lbl(15, color: textPrimary, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create a connection to plug ${Branding.appName} into Claude, ChatGPT, Cursor, '
            'or any MCP-compatible AI tool. Tap Create Connection, paste the '
            'config into your tool, done. Yearly subscription required.',
            style: TextStyle(fontSize: 14, height: 1.45, color: textMuted),
          ),
          // "Setup Guide" deep link removed: https://zealova.com/mcp/docs
          // doesn't exist yet. The copy above already covers the flow
          // end-to-end. Re-add once the marketing page ships (needs
          // `cd frontend && npm run deploy`, not just a commit) — restore
          // the InkWell(onTap: onOpenDocs, ...) block from git history.
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
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;

    return ZealovaCard(
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
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialFor(integration.name),
                  style: ZType.disp(18, color: accent),
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context).aiIntegrationsOauth,
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
              AppLocalizations.of(context).aiIntegrationsGrantedPermissions,
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
                  : Icon(Icons.link_off, size: 18, color: Colors.red.shade400),
              label: Text(
                isDisconnecting
                    ? AppLocalizations.of(context).aiIntegrationsDisconnecting
                    : AppLocalizations.of(
                        context,
                      ).googleCalendarConnectDisconnect,
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
    final tc = ThemeColors.of(context);
    final label = _labels[scope] ?? scope;
    // Write/export/chat scopes spend the accent; read scopes stay muted.
    final color = _isWriteScope ? accent : tc.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isWriteScope
              ? accent.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: ZType.lbl(10, color: color, letterSpacing: 1.2),
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
  const _EmptyState({required this.accent, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textMuted = tc.textMuted;
    return ZealovaCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.power_outlined, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).aiIntegrationsNoConnectionsYet,
            textAlign: TextAlign.center,
            style: ZType.lbl(15, color: tc.textPrimary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one to start using ${Branding.appName} in Claude, ChatGPT, or Cursor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 18),
          ZealovaButton(
            label: AppLocalizations.of(context).aiIntegrationsCreateConnection,
            onTap: onCreate,
            trailingIcon: Icons.add_link,
            expand: false,
            height: 48,
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
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 64),
        Icon(Icons.cloud_off_outlined, size: 56, color: tc.textMuted),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).aiIntegrationsCouldNotLoadIntegrations,
          textAlign: TextAlign.center,
          style: ZType.lbl(15, color: tc.textPrimary, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: tc.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(
          child: ZealovaButton(
            label: AppLocalizations.of(context).workoutReviewTryAgain,
            onTap: onRetry,
            trailingIcon: Icons.refresh,
            expand: false,
            height: 48,
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
        border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
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
