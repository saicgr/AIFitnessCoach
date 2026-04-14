/// Display-only time formatters. Always render in the device's local timezone
/// (read automatically by [DateTime.toLocal] from the OS) — never hardcode a
/// zone. The backend emits tz-aware UTC ISO (see `core/timezone_utils.to_utc_iso`);
/// here we convert for display.
class TimeFormatters {
  TimeFormatters._();

  /// `9:15 AM`-style time for food-log / activity rows. Accepts any DateTime —
  /// UTC or local — and routes it through [DateTime.toLocal] so the user sees
  /// wall-clock time on their current device zone.
  static String logTime(DateTime t) {
    final local = t.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${local.minute.toString().padLeft(2, '0')} $ampm';
  }
}
