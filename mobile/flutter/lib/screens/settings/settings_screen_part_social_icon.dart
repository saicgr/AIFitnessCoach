part of 'settings_screen.dart';

/// Ordered locale list shared between the app-language and chat-language
/// pickers in the settings screen. Null key = "System default" or "Same as
/// app language" depending on the picker. Mirrors LanguageSection ordering.
const _kSettingsLocaleNames = <String?, String>{
  null: 'System default',
  'en': 'English', 'es': 'Español', 'de': 'Deutsch', 'fr': 'Français',
  'it': 'Italiano', 'pt': 'Português', 'cs': 'Čeština', 'pl': 'Polski',
  'zh': '中文 (简体)', 'ja': '日本語', 'ko': '한국어',
  'hi': 'हिन्दी', 'mr': 'मराठी', 'ne': 'नेपाली', 'bn': 'বাংলা',
  'ta': 'தமிழ்', 'te': 'తెలుగు', 'kn': 'ಕನ್ನಡ', 'ml': 'മലയാളം',
  'pa': 'ਪੰਜਾਬੀ', 'or': 'ଓଡ଼ିଆ',
  'vi': 'Tiếng Việt', 'id': 'Bahasa Indonesia', 'jv': 'Basa Jawa',
  'th': 'ไทย', 'ms': 'Bahasa Melayu', 'tl': 'Tagalog',
  'ar': 'العربية', 'ur': 'اردو',
  'ru': 'Русский', 'tr': 'Türkçe', 'sv': 'Svenska',
  'nl': 'Nederlands', 'fi': 'Suomi',
  'sw': 'Kiswahili', 'ha': 'Hausa',
};

/// A single row in the settings screen
class _SocialIcon {
  // font_awesome_flutter 11 returns FaIconData (not an IconData subtype, since
  // IconData became a final class) — these rows are FA-only, rendered via FaIcon.
  final FaIconData icon;
  final Color color;
  final String label;
  const _SocialIcon(this.icon, this.color, this.label);
}


class _SettingsRow {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? value;
  final String route;
  final List<String> sectionKeys;
  final bool isThemeRow;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.title,
    this.value,
    this.route = '',
    required this.sectionKeys,
    this.isThemeRow = false,
    this.onTap,
  });
}


/// A labeled group of rows
class _SettingsSection {
  final String label;
  final List<_SettingsRow> rows;

  const _SettingsSection({required this.label, required this.rows});

  List<String> get allSectionKeys =>
      rows.expand((r) => r.sectionKeys).toList();
}

