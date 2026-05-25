import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../widgets/section_header.dart';

/// Phase 5 — language picker. Surfaces 36 locales (Gravl-parity 8 plus the
/// 28 added 2026-05-24). Display names are in each locale's native script so
/// the picker is self-identifying ("Español" not "Spanish"). Writes to
/// `localeProvider`, which drives MaterialApp.locale + persists to SharedPreferences.
///
/// Sheet height grows past one screen; users scroll. That's intentional —
/// Material picker spec for >12 options is "scrollable list", not "search".
class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  /// Ordered (System default first, then Gravl-parity 8 alphabetical, then
  /// new locales grouped by region for scan-ability). Each entry is
  /// `code → native-script name`. RTL languages keep their native scripts.
  static const _localeNames = <String?, String>{
    null: 'System default',
    // Gravl-parity 8
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'it': 'Italiano',
    'pt': 'Português',
    'cs': 'Čeština',
    'pl': 'Polski',
    // CJK
    'zh': '中文 (简体)',
    'ja': '日本語',
    'ko': '한국어',
    // Indian subcontinent (Devanagari/Bengali/Dravidian/Gurmukhi/Odia)
    'hi': 'हिन्दी',
    'mr': 'मराठी',
    'ne': 'नेपाली',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'pa': 'ਪੰਜਾਬੀ',
    'or': 'ଓଡ଼ିଆ',
    // Southeast Asian
    'vi': 'Tiếng Việt',
    'id': 'Bahasa Indonesia',
    'jv': 'Basa Jawa',
    'th': 'ไทย',
    'ms': 'Bahasa Melayu',
    'tl': 'Tagalog',
    // Middle Eastern (RTL)
    'ar': 'العربية',
    'ur': 'اردو',
    // European
    'ru': 'Русский',
    'tr': 'Türkçe',
    'sv': 'Svenska',
    'nl': 'Nederlands',
    'fi': 'Suomi',
    // African
    'sw': 'Kiswahili',
    'ha': 'Hausa',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final selectedCode = ref.watch(localeProvider).locale?.languageCode;
    final selectedName =
        _localeNames[selectedCode] ?? selectedCode ?? 'System default';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'LANGUAGE'),
        const SizedBox(height: 12),
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _picker(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardBorder.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.language_rounded,
                        color: textPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(selectedName,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _picker(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollCtl) {
            return Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtl,
                      children: _localeNames.entries.map((e) {
                        final selectedNow =
                            ref.read(localeProvider).locale?.languageCode ==
                                e.key;
                        return ListTile(
                          title: Text(
                            e.value,
                            // Force LTR direction on the picker rows so the
                            // RTL native scripts (Arabic, Urdu) render
                            // correctly inside this LTR shell.
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: Icon(
                            selectedNow ? Icons.check_rounded : null,
                          ),
                          onTap: () =>
                              Navigator.pop(ctx, e.key ?? const Object()),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    if (picked is String) {
      await ref.read(localeProvider.notifier).setLocale(Locale(picked));
    } else {
      // sentinel for "System default"
      await ref.read(localeProvider.notifier).setLocale(null);
    }
  }
}
