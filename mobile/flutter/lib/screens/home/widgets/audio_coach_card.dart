import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/body_analyzer.dart';
import '../../../data/repositories/body_analyzer_repository.dart';

/// Home-screen tile that plays a 15–20 s personalised audio brief.
///
/// Off by default — the card only renders when the user has opted in via
/// Settings > AI features > "Daily audio coach" (SharedPreferences flag
/// `audio_coach_enabled`).
class AudioCoachCard extends ConsumerStatefulWidget {
  const AudioCoachCard({super.key});

  @override
  ConsumerState<AudioCoachCard> createState() => _AudioCoachCardState();
}

class _AudioCoachCardState extends ConsumerState<AudioCoachCard> {
  AudioCoachBrief? _brief;
  bool _loading = true;
  bool _playing = false;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(audioCoachRepositoryProvider);
      final brief = await repo.dailyBrief();
      if (mounted) setState(() => _brief = brief);
    } catch (_) {
      // Silent — audio coach is opt-in; failure hides the card.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final b = _brief;
    if (b == null || b.audioUrl == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    await _player.play(UrlSource(b.audioUrl!));
    try {
      await ref.read(audioCoachRepositoryProvider).markListened(b.briefId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final b = _brief;
    if (b == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: b.audioUrl == null ? null : _toggle,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFB24BF3).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFFB24BF3),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Today\'s coach brief',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.scriptText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    height: 1.35,
                  ),
                ),
                if (b.audioUrl == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Audio synthesis disabled — showing text only.',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
