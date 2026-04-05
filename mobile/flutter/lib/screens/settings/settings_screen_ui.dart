part of 'settings_screen.dart';

/// UI builder methods extracted from _SettingsScreenState
extension _SettingsScreenStateUI on _SettingsScreenState {

  Widget _buildNoResultsMessage(BuildContext context, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No settings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords like "theme", "notifications", or "ai voice"',
            style: TextStyle(
              fontSize: 14,
              color: textMuted.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  // --- Section label ---
  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


  // --- Social media icon row ---
  Widget _buildSocialRow(bool isDark) {
    const allSocials = [
      _SocialIcon(FontAwesomeIcons.discord, Color(0xFF5865F2), 'discord'),
      _SocialIcon(FontAwesomeIcons.reddit, Color(0xFFFF4500), 'reddit'),
      _SocialIcon(FontAwesomeIcons.xTwitter, Color(0xFF14171A), 'twitter'),
      _SocialIcon(FontAwesomeIcons.instagram, Color(0xFFE4405F), 'instagram'),
      _SocialIcon(FontAwesomeIcons.tiktok, Color(0xFF010101), 'tiktok'),
    ];

    // Map label keys to AppLinks URLs
    const urlMap = {
      'discord': AppLinks.discord,
      'reddit': AppLinks.reddit,
      'twitter': AppLinks.twitter,
      'instagram': AppLinks.instagram,
      'tiktok': AppLinks.tiktok,
    };

    // Only show icons that have a URL configured
    final socials = allSocials.where((s) {
      final url = urlMap[s.label] ?? '';
      return url.isNotEmpty;
    }).toList();

    if (socials.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socials.map((s) {
        final iconColor = isDark && s.color.computeLuminance() < 0.1
            ? Colors.white
            : s.color;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () {
              final url = urlMap[s.label] ?? '';
              if (url.isNotEmpty) _launchExternalUrl(url);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(s.icon, color: iconColor, size: 20),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  // --- Group card containing rows ---
  Widget _buildGroupCard(
    List<_SettingsRow> rows,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    ThemeMode themeMode,
  ) {
    // Filter rows based on search
    final visibleRows = _searchQuery.isEmpty
        ? rows
        : rows.where((r) => r.sectionKeys.any((k) => _matchingSections.contains(k))).toList();

    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < visibleRows.length; i++) ...[
            _buildRow(visibleRows[i], isDark, textPrimary, textMuted, themeMode),
            if (i < visibleRows.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: cardBorder,
              ),
          ],
        ],
      ),
    );
  }


  // --- Single row ---
  Widget _buildRow(
    _SettingsRow row,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    ThemeMode themeMode,
  ) {
    final iconBg = (row.iconColor ?? (isDark ? AppColors.cyan : AppColorsLight.cyan))
        .withValues(alpha: 0.15);
    final iconFg = row.iconColor ?? (isDark ? AppColors.cyan : AppColorsLight.cyan);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(posthogServiceProvider).capture(
          eventName: 'setting_changed',
          properties: <String, Object>{
            'setting_name': row.title,
            'new_value': row.route,
          },
        );
        if (row.onTap != null) {
          row.onTap!();
        } else {
          context.push(row.route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(row.icon, color: iconFg, size: 18),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                row.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            // Theme selector or value text
            if (row.isThemeRow)
              InlineThemeSelector(
                currentMode: themeMode,
                onChanged: (mode) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                  ref.read(posthogServiceProvider).capture(
                    eventName: 'theme_changed',
                    properties: <String, Object>{
                      'setting_name': 'theme',
                      'new_value': mode.name,
                    },
                  );
                },
              )
            else if (row.value != null) ...[
              Flexible(
                flex: 0,
                child: Text(
                  row.value!,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: textMuted, size: 18),
            ] else
              Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

}
