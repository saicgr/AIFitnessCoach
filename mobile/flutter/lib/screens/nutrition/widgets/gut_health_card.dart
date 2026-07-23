import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/digestion_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';

/// One row of the Bristol Stool Scale — a clinically-recognised stool-form
/// scale (1 = separate hard lumps … 7 = entirely liquid; 3–4 is the healthy
/// "ideal"). Each gets a signature Material glyph + Barlow label, NO emoji.
class _BristolItem {
  final int type;
  final IconData icon;
  final String label; // short descriptor
  final String hint; // one-line clinical-but-friendly note
  const _BristolItem(this.type, this.icon, this.label, this.hint);
}

const List<_BristolItem> _bristolScale = [
  _BristolItem(1, Icons.grain_rounded, 'Hard lumps', 'Separate hard lumps — quite constipated'),
  _BristolItem(2, Icons.dehaze_rounded, 'Lumpy', 'Lumpy and sausage-like — mildly constipated'),
  _BristolItem(3, Icons.view_stream_rounded, 'Cracked', 'Sausage with cracks — normal'),
  _BristolItem(4, Icons.remove_rounded, 'Smooth', 'Smooth and soft — ideal'),
  _BristolItem(5, Icons.blur_on_rounded, 'Soft blobs', 'Soft blobs, clear edges — lacking fibre'),
  _BristolItem(6, Icons.water_rounded, 'Mushy', 'Mushy, ragged edges — mild diarrhea'),
  _BristolItem(7, Icons.opacity_rounded, 'Liquid', 'Entirely liquid — diarrhea'),
];

/// Healthy band for the at-a-glance accent treatment (types 3–4 are ideal).
bool _isIdeal(int type) => type == 3 || type == 4;

/// Compact gut-health summary block for the Daily tab — a sibling to
/// [HydrationSummaryBlock]. Tap (or the "+") opens the one-tap Bristol picker.
class GutHealthCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const GutHealthCard({super.key, required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final state = ref.watch(digestionProvider);
    final count = state.todayCount;
    final last = state.lastBristolType;

    final surface = tc.surface;
    final accent = tc.accent;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final cardBorder = tc.cardBorder;

    final hasLog = count > 0;
    final lastItem = last != null
        ? _bristolScale.firstWhere((b) => b.type == last,
            orElse: () => _bristolScale[3])
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showGutHealthSheet(context: context, userId: userId),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'GUT HEALTH',
                      style:
                          ZType.lbl(13, color: textPrimary, letterSpacing: 1.5),
                    ),
                    const Spacer(),
                    if (hasLog)
                      Text(
                        count == 1 ? '1 today' : '$count today',
                        style: ZType.data(13, color: textPrimary),
                      ),
                    const SizedBox(width: 8),
                    // Quick-log "+" — opens the Bristol picker (the whole card
                    // taps to the same sheet, but the "+" mirrors the hydration
                    // card affordance).
                    ZealovaPlusButton(
                      size: 28,
                      onTap: () =>
                          showGutHealthSheet(context: context, userId: userId),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasLog && lastItem != null
                      ? 'Last: Type ${lastItem.type} · ${lastItem.label}'
                      : "Log today's bathroom visit — takes 5 seconds",
                  style: TextStyle(
                    fontSize: 12,
                    color: hasLog && lastItem != null && _isIdeal(lastItem.type)
                        ? AppColors.success
                        : textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      hasLog ? 'Tap to log again' : 'Tap to log',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Open the one-tap gut-health logger. Bristol 1–7 picker (signature glyphs,
/// no emoji), optional urgency / duration / tags / note, primary ZealovaButton
/// to log.
Future<void> showGutHealthSheet({
  required BuildContext context,
  required String userId,
}) async {
  await showGlassSheet<void>(
    context: context,
    builder: (_) => _GutHealthSheet(userId: userId),
  );
}

class _GutHealthSheet extends ConsumerStatefulWidget {
  final String userId;
  const _GutHealthSheet({required this.userId});

  @override
  ConsumerState<_GutHealthSheet> createState() => _GutHealthSheetState();
}

class _GutHealthSheetState extends ConsumerState<_GutHealthSheet> {
  int? _bristol;
  int? _urgency; // 1 relaxed · 2 normal · 3 urgent
  int? _durationMin;
  final Set<String> _tags = {};
  final TextEditingController _notes = TextEditingController();
  bool _saving = false;

  // Convenience tag suggestions — open vocabulary (the custom-tag chip is the
  // escape hatch); these are not a gate, just one-tap common cases.
  static const _suggestedTags = [
    'after coffee',
    'after meal',
    'bloated',
    'cramping',
    'urgent',
    'high fibre',
    'dairy',
    'travel',
  ];

  static const _urgencyLabels = ['Relaxed', 'Normal', 'Urgent'];
  static const _durationOptions = [1, 2, 5, 10];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    if (_bristol == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final ok = await ref.read(digestionProvider.notifier).logEntry(
          userId: widget.userId,
          bristolType: _bristol!,
          urgency: _urgency,
          durationSeconds: _durationMin != null ? _durationMin! * 60 : null,
          tags: _tags.toList(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    ref.read(posthogServiceProvider).capture(
      eventName: 'digestion_logged',
      properties: <String, Object>{
        'bristol_type': _bristol!,
        if (_urgency != null) 'urgency': _urgency!,
        'has_note': _notes.text.trim().isNotEmpty,
        'tag_count': _tags.length,
      },
    );
    Navigator.of(context).pop();
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged Type $_bristol'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GlassSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined,
                      color: tc.accent, size: 24),
                  const SizedBox(width: 10),
                  Text('LOG GUT HEALTH',
                      style: ZType.lbl(16,
                          color: tc.textPrimary, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Consistency — 1 (hard lumps) to 7 (liquid). 3–4 is the healthy range.',
                style: ZType.ser(13, color: tc.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'This is the Bristol scale, the standard doctors use to read digestion.',
                style: ZType.ser(11.5, color: tc.textMuted),
              ),
              const SizedBox(height: 16),

              // Bristol 1–7 selector — glyph tiles, NO emoji.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in _bristolScale)
                    _BristolTile(
                      item: b,
                      selected: _bristol == b.type,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _bristol = b.type);
                      },
                    ),
                ],
              ),

              // Inline hint for the selected type.
              if (_bristol != null) ...[
                const SizedBox(height: 10),
                Text(
                  _bristolScale
                      .firstWhere((b) => b.type == _bristol)
                      .hint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _isIdeal(_bristol!)
                        ? AppColors.success
                        : tc.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              _SectionLabel('URGENCY (OPTIONAL)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _urgencyLabels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleChip(
                        label: _urgencyLabels[i],
                        selected: _urgency == i + 1,
                        onTap: () => setState(
                            () => _urgency = _urgency == i + 1 ? null : i + 1),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 18),
              _SectionLabel('DURATION (OPTIONAL)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _durationOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleChip(
                        label: '${_durationOptions[i]}m',
                        selected: _durationMin == _durationOptions[i],
                        onTap: () => setState(() => _durationMin =
                            _durationMin == _durationOptions[i]
                                ? null
                                : _durationOptions[i]),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 18),
              _SectionLabel('TAGS (OPTIONAL)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in _suggestedTags)
                    ZealovaChip(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(() =>
                          _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                    ),
                ],
              ),

              const SizedBox(height: 18),
              _SectionLabel('NOTE (OPTIONAL)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                style: TextStyle(color: tc.textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Anything worth remembering…',
                  hintStyle: TextStyle(color: tc.textMuted),
                  filled: true,
                  fillColor: tc.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),
              Opacity(
                opacity: _bristol == null ? 0.4 : 1,
                child: ZealovaButton(
                  label: _saving ? 'Saving…' : 'Log entry',
                  onTap: _bristol == null || _saving ? null : _log,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One Bristol-scale glyph tile.
class _BristolTile extends StatelessWidget {
  final _BristolItem item;
  final bool selected;
  final VoidCallback onTap;
  const _BristolTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = selected ? tc.accent : tc.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? tc.accent.withValues(alpha: 0.10) : tc.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tc.accent : tc.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text('TYPE ${item.type}',
                style: ZType.lbl(9, color: fg, letterSpacing: 1)),
            const SizedBox(height: 6),
            Icon(item.icon, size: 22, color: fg),
            const SizedBox(height: 6),
            Text(
              item.label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small toggle pill for urgency / duration (mutually-exclusive within a row,
/// tap again to clear).
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final fg = selected ? tc.accent : tc.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tc.accent.withValues(alpha: 0.10) : tc.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? tc.accent : tc.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label.toUpperCase(),
            style: ZType.lbl(12, color: fg, letterSpacing: 1)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Text(text,
        style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.5));
  }
}
