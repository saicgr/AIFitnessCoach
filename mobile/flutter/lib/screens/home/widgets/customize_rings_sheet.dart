/// Bottom sheet that lets users pick which G1 rings appear on the home
/// screen and in what order. Reads/writes [ringVisibilityProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ring_catalog.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Show the customize-rings sheet. Returns when the sheet is dismissed.
Future<void> showCustomizeRingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CustomizeRingsSheet(),
  );
}

class _CustomizeRingsSheet extends ConsumerWidget {
  const _CustomizeRingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(ringVisibilityProvider);
    final hidden = ref.watch(hiddenRingsProvider);
    final notifier = ref.read(ringVisibilityProvider.notifier);

    final mediaQ = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQ.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAF8F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _grabber(),
                _header(context),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                        child: _SectionLabel(text: 'Showing'),
                      ),
                      SliverToBoxAdapter(
                        child: _ShowingList(
                          visible: visible,
                          notifier: notifier,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      if (hidden.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: _SectionLabel(text: 'Available to add'),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _HiddenTile(
                              kind: hidden[i],
                              onAdd: () => notifier.addRing(hidden[i]),
                            ),
                            childCount: hidden.length,
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _ResetButton(
                          onTap: notifier.resetToDefault,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _grabber() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF16161A).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).customizeRingsCustomizeYourRings,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16161A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Color(0xFF16161A)),
              tooltip: 'Close',
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Color(0xFF6B6A66),
        ),
      ),
    );
  }
}

class _ShowingList extends StatelessWidget {
  final List<RingKind> visible;
  final RingVisibilityNotifier notifier;

  const _ShowingList({required this.visible, required this.notifier});

  @override
  Widget build(BuildContext context) {
    // ReorderableListView needs a bounded height — use shrinkWrap so it
    // sizes to content inside the CustomScrollView.
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: visible.length,
      onReorder: (oldIndex, newIndex) {
        final reordered = List<RingKind>.of(visible);
        final idx = newIndex > oldIndex ? newIndex - 1 : newIndex;
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(idx, moved);
        notifier.setOrder(reordered);
      },
      itemBuilder: (context, i) {
        final kind = visible[i];
        return _ShowingTile(
          key: ValueKey('ring_${kind.id}'),
          kind: kind,
          index: i,
          canHide: !kind.isCore,
          onHide: () => notifier.removeRing(kind),
        );
      },
    );
  }
}

class _ShowingTile extends StatelessWidget {
  final RingKind kind;
  final int index;
  final bool canHide;
  final VoidCallback onHide;

  const _ShowingTile({
    super.key,
    required this.kind,
    required this.index,
    required this.canHide,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8E6E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _ColorDot(color: kind.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16161A),
                ),
              ),
            ),
            if (kind.isCore)
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  AppLocalizations.of(context).quizMuscleFocusCore,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A9892),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            if (canHide)
              IconButton(
                icon: const Icon(
                  Icons.visibility_off_outlined,
                  size: 20,
                  color: Color(0xFF6B6A66),
                ),
                tooltip: 'Hide',
                onPressed: onHide,
              ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.drag_indicator,
                  color: Color(0xFFBDBBB5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenTile extends StatelessWidget {
  final RingKind kind;
  final VoidCallback onAdd;
  const _HiddenTile({required this.kind, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8E6E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _ColorDot(color: kind.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16161A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppLocalizations.of(context).tilePickerAdd),
              style: TextButton.styleFrom(
                foregroundColor: kind.color,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(AppLocalizations.of(context).customizeRingsResetToDefault),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF16161A),
            side: const BorderSide(color: Color(0xFFE0DED7)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
