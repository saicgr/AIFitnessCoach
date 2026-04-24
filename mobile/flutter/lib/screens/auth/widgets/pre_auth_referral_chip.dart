import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/services/pending_referral_service.dart';
import '../../onboarding/widgets/onboarding_theme.dart';

/// Pre-auth chip shown on the sign-in screen: "Got a code from a friend?"
/// Tapping opens a bottom-sheet input. The entered code is stored via
/// [PendingReferralService] and applied automatically by
/// `AuthStateNotifier._flushPendingReferral()` after sign-in completes.
///
/// This is the only path for users who arrived WITHOUT tapping an invite
/// link (they heard about the code elsewhere — friend texted it, QR on a
/// poster, etc). Deep-link arrivals already seed the pending service;
/// this chip is their explicit entry point.
class PreAuthReferralChip extends StatefulWidget {
  const PreAuthReferralChip({super.key});

  @override
  State<PreAuthReferralChip> createState() => _PreAuthReferralChipState();
}

class _PreAuthReferralChipState extends State<PreAuthReferralChip> {
  String? _pendingCode;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final code = await PendingReferralService.read();
    if (!mounted) return;
    setState(() {
      _pendingCode = code;
      _loaded = true;
    });
  }

  Future<void> _openSheet() async {
    HapticFeedback.selectionClick();
    final entered = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReferralCodeSheet(initial: _pendingCode),
    );
    if (entered == null) return;

    if (entered.isEmpty) {
      // Explicit clear (user hit "Remove code").
      await PendingReferralService.clear();
    } else {
      final ok = await PendingReferralService.set(entered);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("That code doesn't look right — try again."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 24);
    final t = OnboardingTheme.of(context);
    final hasCode = _pendingCode != null && _pendingCode!.isNotEmpty;

    return GestureDetector(
      onTap: _openSheet,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasCode ? t.borderSelected : t.borderDefault,
                width: hasCode ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasCode ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                  size: 16,
                  color: hasCode ? t.selectionAccent : t.textMuted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hasCode
                        ? 'Code $_pendingCode will apply after signup'
                        : 'Got a code from a friend?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasCode ? t.textPrimary : t.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: t.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 900.ms);
  }
}

class _ReferralCodeSheet extends StatefulWidget {
  final String? initial;
  const _ReferralCodeSheet({this.initial});

  @override
  State<_ReferralCodeSheet> createState() => _ReferralCodeSheetState();
}

class _ReferralCodeSheetState extends State<_ReferralCodeSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final normalized = PendingReferralService.normalize(_controller.text);
    if (normalized == null) {
      setState(() => _error = "Invalid code. Check the letters and numbers.");
      return;
    }
    Navigator.of(context).pop(normalized);
  }

  void _remove() {
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          // Heavier blur so the content underneath reads as a frosted-glass
          // backdrop instead of a flat dark card.
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              // Layered gradient gives the sheet a top-to-bottom frosted
              // feel: brighter near the grabber, softer at the bottom.
              // Alpha is low enough (~0.35) that the blur actually shows
              // through, matching the glass sheets used elsewhere in the
              // app rather than the solid-black panel from before.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: t.isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.28),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.82),
                        Colors.white.withValues(alpha: 0.68),
                        Colors.white.withValues(alpha: 0.55),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: t.isDark ? 0.18 : 0.6),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: t.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: t.selectionAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Enter referral code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Get a bonus when your friend signs up you both win. Code '
                  'applies automatically after you finish sign-up.',
                  style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    TextInputFormatter.withFunction((old, newVal) =>
                        newVal.copyWith(text: newVal.text.toUpperCase())),
                  ],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: t.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                      color: t.textMuted.withValues(alpha: 0.4),
                      letterSpacing: 4,
                    ),
                    errorText: _error,
                    filled: true,
                    fillColor: t.cardFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.borderSelected, width: 2),
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if ((widget.initial ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: _remove,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: t.textMuted,
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.selectionAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14,
                        ),
                      ),
                    ),
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
