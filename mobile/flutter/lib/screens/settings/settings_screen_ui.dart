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
            AppLocalizations.of(context).settingsScreenUiNoSettingsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).settingsScreenUiTryDifferentKeywordsLike,
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


  // --- Section label (Signature Barlow group kicker) ---
  Widget _buildSectionLabel(String label, Color color) {
    return ZealovaSectionKicker(
      label,
      padding: const EdgeInsetsDirectional.only(start: 2),
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

    // Signature hairline list — no boxed card; rows divided only by hairlines.
    return Column(
      children: [
        for (int i = 0; i < visibleRows.length; i++)
          _buildRow(visibleRows[i], isDark, textPrimary, textMuted, themeMode),
      ],
    );
  }


  // --- Single row (Signature framed-glyph hairline row) ---
  Widget _buildRow(
    _SettingsRow row,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    ThemeMode themeMode,
  ) {
    void handleTap() {
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
    }

    // Theme rows keep the inline theme segmented control as their trailing.
    if (row.isThemeRow) {
      return ZealovaListRow(
        icon: row.icon,
        label: row.title,
        showChevron: false,
        trailing: InlineThemeSelector(
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
        ),
      );
    }

    return ZealovaListRow(
      icon: row.icon,
      label: row.title,
      value: row.value,
      onTap: handleTap,
    );
  }

}
