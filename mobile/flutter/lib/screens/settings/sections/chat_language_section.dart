import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/chat_locale_provider.dart';
import '../widgets/section_header.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Settings section for AI Coach chat language.
///
/// Separate from [LanguageSection] (app UI language). Users can keep the app
/// in English while asking the AI Coach to reply in Telugu, Hindi, etc.
///
/// "Same as app language" (null chat_locale) is shown as the first item and is
/// the default state. Selecting it clears the chat_locale override.
class ChatLanguageSection extends ConsumerWidget {
  const ChatLanguageSection({super.key});

  /// Ordered list of (code → native-script name). Null = "Same as app".
  /// Mirrors the ordering in LanguageSection for UX consistency.
  static const _localeNames = <String?, String>{
    null: 'Same as app language',
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
    // Indian subcontinent
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

    final chatLocaleState = ref.watch(chatLocaleProvider);
    final selectedCode = chatLocaleState.locale?.languageCode;
    final selectedName = _localeNames[selectedCode] ??
        selectedCode ??
        AppLocalizations.of(context).settingsChatLanguageSameAsApp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title:
                AppLocalizations.of(context).settingsChatLanguageTitle),
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
                    child: Icon(Icons.smart_toy_rounded,
                        color: textPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .settingsChatLanguageTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedName,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)
                              .settingsChatLanguageDescription,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
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
                    width: 40,
                    height: 4,
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
                            ref.read(chatLocaleProvider).locale?.languageCode ==
                                e.key;
                        return ListTile(
                          title: Text(
                            e.value,
                            // Force LTR direction so RTL native scripts
                            // (Arabic, Urdu) render correctly inside the
                            // LTR picker shell.
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
      await ref
          .read(chatLocaleProvider.notifier)
          .setLocale(Locale(picked));
    } else {
      // Sentinel for "Same as app language" (null locale).
      await ref.read(chatLocaleProvider.notifier).clear();
    }
  }
}
