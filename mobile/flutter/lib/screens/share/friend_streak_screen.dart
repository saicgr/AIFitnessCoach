import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/repositories/share_growth_repository.dart';
import '../../widgets/design_system/section_header.dart';

/// F14 — Friend Streak. A 1:1 shared streak (workout or food logging) kept
/// alive when both friends log. Three surfaces:
///   - invite a friend (mints a streak invite + shares the https link),
///   - accept an invite (paste the code from a friend's link),
///   - a list of your active / pending streaks.
///
/// No public feed (project_gamification_role) — strictly 1:1.
class FriendStreakScreen extends ConsumerStatefulWidget {
  const FriendStreakScreen({super.key});

  @override
  ConsumerState<FriendStreakScreen> createState() => _FriendStreakScreenState();
}

class _FriendStreakScreenState extends ConsumerState<FriendStreakScreen> {
  List<FriendStreak> _streaks = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final streaks =
          await ref.read(shareGrowthRepositoryProvider).listStreaks();
      if (!mounted) return;
      setState(() {
        _streaks = streaks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your streaks. Pull to retry.';
      });
    }
  }

  Future<void> _invite(String kind) async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final res =
          await ref.read(shareGrowthRepositoryProvider).createStreakInvite(kind: kind);
      final link = (res['web_url'] as String?) ??
          (res['share_url'] as String?) ??
          '';
      final code = res['invite_code'] as String?;
      if (link.isEmpty && (code == null || code.isEmpty)) {
        throw Exception('No invite link');
      }
      final kindLabel = kind == 'food' ? 'food-logging' : 'workout';
      final msg = link.isNotEmpty
          ? "Let's keep a $kindLabel streak on Zealova — we both log daily: $link"
          : "Join my $kindLabel streak on Zealova with code $code";
      await Share.share(msg);
      await _load();
    } catch (e) {
      if (mounted) _toast("Couldn't create an invite. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptDialog() async {
    final ctrl = TextEditingController();
    final c = ThemeColors.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.elevated,
        title: Text('Join a streak', style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Paste the invite code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    await _accept(code);
  }

  Future<void> _accept(String code) async {
    setState(() => _busy = true);
    try {
      await ref.read(shareGrowthRepositoryProvider).acceptStreakInvite(code);
      _toast('Streak started!');
      await _load();
    } catch (e) {
      if (mounted) _toast('That code is invalid or expired.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Friend Streaks'),
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Join with a code',
            icon: const Icon(Icons.input_rounded),
            onPressed: _busy ? null : _acceptDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SizedBox(height: 8),
            Text(
              'Keep a 1:1 streak alive — it stays lit only when you both log.',
              style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary),
            ),
            const SectionHeader(label: 'Start a streak'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _inviteButton(
                        c, accent, 'Workout', Icons.fitness_center_rounded,
                        () => _invite('workout')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inviteButton(c, accent, 'Food log',
                        Icons.restaurant_rounded, () => _invite('food')),
                  ),
                ],
              ),
            ),
            const SectionHeader(label: 'Your streaks'),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: TextStyle(color: c.textMuted, fontSize: 14)),
              )
            else if (_streaks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No streaks yet. Invite a friend to start one.',
                  style: TextStyle(color: c.textMuted, fontSize: 14),
                ),
              )
            else
              ..._streaks.map((s) => _streakTile(c, accent, s)),
          ],
        ),
      ),
    );
  }

  Widget _inviteButton(ThemeColors c, Color accent, String label, IconData icon,
      VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _streakTile(ThemeColors c, Color accent, FriendStreak s) {
    final active = s.status == 'active';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: active ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                active ? '🔥' : '⏳',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.kind == 'food' ? 'Food-logging streak' : 'Workout streak',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active
                        ? '${s.currentStreak} day${s.currentStreak == 1 ? '' : 's'} · best ${s.longestStreak}'
                        : 'Waiting for your friend to join',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (s.status == 'pending' && s.inviteCode != null)
              IconButton(
                tooltip: 'Reshare invite',
                icon: Icon(Icons.ios_share_rounded, color: c.textMuted),
                onPressed: () => Share.share(
                    'Join my Zealova streak with code ${s.inviteCode}'),
              ),
          ],
        ),
      ),
    );
  }
}
