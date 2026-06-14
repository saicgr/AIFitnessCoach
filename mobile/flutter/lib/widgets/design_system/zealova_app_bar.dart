import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';

/// Signature screen masthead — an Anton uppercase title with optional back
/// chevron + trailing actions, on a transparent bar (hairline-led screens).
class ZealovaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? kicker;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double titleSize;

  const ZealovaAppBar({
    super.key,
    required this.title,
    this.kicker,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.titleSize = 30,
  });

  @override
  Size get preferredSize => Size.fromHeight(kicker != null ? 88 : 72);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: Icon(Icons.arrow_back,
                      size: 22, color: tc.textPrimary),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kicker != null)
                    Text(kicker!.toUpperCase(),
                        style:
                            ZType.lbl(10, color: tc.textMuted, letterSpacing: 2)),
                  Text(title.toUpperCase(),
                      style: ZType.disp(titleSize, color: tc.textPrimary)),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
