/// Bottom sheet to enable/disable public sharing for a recipe + show the URL + counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe_share.dart';
import '../../../data/repositories/recipe_repository.dart';

class RecipeShareSheet extends ConsumerStatefulWidget {
  final String recipeId;
  final String userId;
  final bool isDark;
  const RecipeShareSheet({super.key, required this.recipeId, required this.userId, required this.isDark});
  @override
  ConsumerState<RecipeShareSheet> createState() => _RecipeShareSheetState();
}

class _RecipeShareSheetState extends ConsumerState<RecipeShareSheet> {
  ShareLink? _link;
  bool _loading = false;

  Future<void> _enable() async {
    setState(() => _loading = true);
    try {
      _link = await ref.read(recipeRepositoryProvider).enableShare(widget.userId, widget.recipeId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _loading = true);
    try {
      await ref.read(recipeRepositoryProvider).disableShare(widget.userId, widget.recipeId);
      _link = null;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unshare failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_link != null ? Icons.public : Icons.share_outlined, size: 48, color: accent),
          const SizedBox(height: 12),
          Text(_link != null ? 'Recipe is public' : 'Share publicly',
              style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            _link != null
                ? 'Anyone with the link can view. Saves to libraries: ${_link!.saveCount} · Views: ${_link!.viewCount}'
                : 'Generate a link anyone can open. They can save a copy to their library.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_link != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Expanded(child: Text(_link!.url, style: TextStyle(color: text, fontSize: 12))),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _link!.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, size: 18, color: accent),
                  onPressed: () => Share.share(_link!.url, subject: 'Recipe'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loading ? null : _disable, child: const Text('Stop sharing')),
          ] else
            ElevatedButton.icon(
              onPressed: _loading ? null : _enable,
              icon: const Icon(Icons.link),
              label: const Text('Generate share link'),
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
