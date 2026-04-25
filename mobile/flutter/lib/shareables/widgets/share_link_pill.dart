import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pill-style row showing a public share URL with [Copy] / [Open] actions.
/// Displayed in the unified share sheet for `ShareableKind.workoutComplete`.
class ShareLinkPill extends StatelessWidget {
  final String? url;
  final VoidCallback? onGenerate;
  final bool isGenerating;

  const ShareLinkPill({
    super.key,
    this.url,
    this.onGenerate,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final fg = isDark ? Colors.white : Colors.black;

    if (url == null) {
      return InkWell(
        onTap: isGenerating ? null : onGenerate,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGenerating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg.withValues(alpha: 0.7),
                  ),
                )
              else
                Icon(Icons.link_rounded,
                    size: 16, color: fg.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Text(
                isGenerating ? 'Generating link…' : 'Get share link',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final display = url!.replaceFirst(RegExp(r'^https?://'), '');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 16, color: fg.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _IconAction(
            icon: Icons.copy_rounded,
            onTap: () async {
              HapticFeedback.lightImpact();
              await Clipboard.setData(ClipboardData(text: url!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          _IconAction(
            icon: Icons.open_in_new_rounded,
            onTap: () async {
              HapticFeedback.selectionClick();
              final uri = Uri.parse(url!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: fg.withValues(alpha: 0.85)),
      ),
    );
  }
}
