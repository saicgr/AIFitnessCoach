/// Bottom sheet to enable/disable public sharing for a recipe + show the URL + counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/recipe_share.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    // Resolve the gym-aware accent the same way the rest of the sheet did.
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final tc = ThemeColors.of(context);
    final text = tc.textPrimary;
    final muted = tc.textMuted;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(_link != null ? Icons.public : Icons.share_outlined, size: 44, color: accent),
          const SizedBox(height: 14),
          Text(
            (_link != null
                    ? AppLocalizations.of(context).recipeShareRecipeIsPublic
                    : AppLocalizations.of(context).recipeShareSharePublicly)
                .toUpperCase(),
            style: ZType.disp(22, color: text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _link != null
                ? AppLocalizations.of(context)!.recipeShareSheetAnyoneWithTheLink(_link!.saveCount, _link!.viewCount)
                : 'Generate a link anyone can open. They can save a copy to their library.',
            style: TextStyle(color: muted, fontSize: 12.5, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (_link != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(_link!.url,
                      style: ZType.data(12.5, color: text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: muted),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _link!.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).recipeShareCopiedToClipboard)));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, size: 18, color: accent),
                  onPressed: () => Share.share(_link!.url, subject: 'Recipe'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ZealovaButton(
              label: AppLocalizations.of(context).recipeShareStopSharing,
              variant: ZealovaButtonVariant.ghost,
              onTap: _loading ? null : _disable,
            ),
          ] else
            ZealovaButton(
              label: AppLocalizations.of(context).recipeShareGenerateShareLink,
              trailingIcon: Icons.link,
              onTap: _loading ? null : _enable,
            ),
        ],
      ),
    );
  }
}
