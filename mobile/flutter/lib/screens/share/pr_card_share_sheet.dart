/// Bottom sheet that renders a "PR Card" the user can share to socials.
/// Triggered by tapping the share icon on an `achievement_chip` in the
/// Timeline (TimelineEntryDetailSheet → Share button → this sheet).
///
/// Renders a 1080×1920 (Instagram story) PNG via RepaintBoundary capture
/// + share_plus. Falls back to text-only share when image generation
/// fails (sandboxed simulators sometimes can't write to a temp file).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/timeline_entry.dart';
import '../../widgets/glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
class PRCardShareSheet extends StatefulWidget {
  final TimelineEntry entry;
  final TimelineAchievement achievement;
  final String? userName;

  const PRCardShareSheet({
    super.key,
    required this.entry,
    required this.achievement,
    this.userName,
  });

  static Future<void> show(
    BuildContext context, {
    required TimelineEntry entry,
    required TimelineAchievement achievement,
    String? userName,
  }) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        showHandle: false,
        child: PRCardShareSheet(
          entry: entry,
          achievement: achievement,
          userName: userName,
        ),
      ),
    );
  }

  @override
  State<PRCardShareSheet> createState() => _PRCardShareSheetState();
}

class _PRCardShareSheetState extends State<PRCardShareSheet> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _captureKey,
              child: _PRCardCanvas(
                entry: widget.entry,
                achievement: widget.achievement,
                userName: widget.userName,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(_sharing ? AppLocalizations.of(context).prCardSharePreparing : AppLocalizations.of(context).prCardShareSharePr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Future<void> _onShare() async {
    setState(() => _sharing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('No capture boundary');
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw Exception('Capture failed');
      }
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: 'zealova_pr_${widget.achievement.kind}.png',
            mimeType: 'image/png',
          ),
        ],
        text: '${widget.achievement.label} 💪 — Logged with Zealova',
      );
    } catch (_) {
      await Share.share(
        '${widget.achievement.label} 💪 — Logged with Zealova',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _PRCardCanvas extends StatelessWidget {
  final TimelineEntry entry;
  final TimelineAchievement achievement;
  final String? userName;

  const _PRCardCanvas({
    required this.entry,
    required this.achievement,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 540,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade400,
            Colors.deepOrange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).workoutShowcaseNewPr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.emoji_events, color: Colors.white, size: 28),
            ],
          ),
          const Spacer(),
          Text(
            achievement.label.replaceAll(AppLocalizations.of(context).prCardShareNewPr2, '').replaceAll(AppLocalizations.of(context).prCardShareE1rm, ''),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (userName != null)
            Text(
              userName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).prCardShareZealovaAiFitnessCoach,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                AppLocalizations.of(context).prCardShareZealovaCom,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
