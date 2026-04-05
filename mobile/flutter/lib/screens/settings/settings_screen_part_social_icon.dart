part of 'settings_screen.dart';


/// A single row in the settings screen
class _SocialIcon {
  final IconData icon;
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

