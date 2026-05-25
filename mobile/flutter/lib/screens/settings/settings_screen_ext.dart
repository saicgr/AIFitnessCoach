part of 'settings_screen.dart';

/// Methods extracted from _SettingsScreenState
extension __SettingsScreenStateExt on _SettingsScreenState {

  Set<String> _computeMatchingSections(String query) {
    if (query.isEmpty) return {};

    final matches = <String>{};
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    for (final entry in _settingsSearchIndex.entries) {
      final sectionKey = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();

        if (keywordLower.contains(query) || query.contains(keywordLower)) {
          matches.add(sectionKey);
          break;
        }

        if (queryWords.length > 1) {
          int matchedWords = 0;
          for (final word in queryWords) {
            if (keywordLower.contains(word) || word.length > 2 && keywords.any((k) => k.toLowerCase().contains(word))) {
              matchedWords++;
            }
          }
          if (matchedWords >= (queryWords.length * 0.6).ceil()) {
            matches.add(sectionKey);
            break;
          }
        }
      }
    }

    return matches;
  }


  Widget _buildSearchFAB(bool isDark) {
    final accentColor = ref.colors(context).accent;

    return GestureDetector(
      key: const ValueKey('search_fab'),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isSearchExpanded = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.search,
            color: isDark ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }


  Widget _buildExpandedSearchBar(bool isDark, Color textPrimary, Color textMuted) {
    return ClipRRect(
      key: const ValueKey('search_bar'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.auto_awesome,
                color: textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).settingsScreenExtSearchSettings,
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _searchController.clear();
                  _onSearchChanged('');
                  _searchFocusNode.unfocus();
                  setState(() {
                    _isSearchExpanded = false;
                  });
                },
                child: Container(
                  width: 48,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    color: textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // --- Delete account dialog ---
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    showDeleteAccountFlow(context, ref).whenComplete(() {
      if (mounted) setState(() => _isDeleting = false);
    });
  }


  void _showReplayTutorialsSheet(BuildContext context, WidgetRef ref, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;

    // Each tour fires its first-run UI when at least one of the listed
    // SharedPrefs keys is absent. The two underlying systems use different
    // key formats (AppTour: has_seen_<id>; EmptyStateTipTour:
    // has_seen_empty_tour_<id>; tier-aware active workout: tour_seen_<tier>),
    // so we need to clear the right key per tour for "Replay" to actually
    // re-fire. Source of truth: lib/widgets/tooltips/tooltip_ids.dart.
    final tours = <(String, String, String, IconData, List<String>)>[
      (
        'nav_tour',
        'Home Navigation',
        'Home screen walkthrough',
        Icons.home_outlined,
        ['has_seen_nav_tour'],
      ),
      (
        'workout_tour',
        'Active Workout',
        'Easy / Simple / Advanced walkthroughs',
        Icons.fitness_center,
        ['tour_seen_easy', 'tour_seen_simple', 'tour_seen_advanced'],
      ),
      (
        'nutrition_tour',
        'Nutrition Tracking',
        'Log meals + swipe dates + My Foods',
        Icons.restaurant_outlined,
        // Legacy EmptyStateTipTour-backed; key prefix differs from AppTour.
        ['has_seen_empty_tour_nutrition_v1'],
      ),
      (
        'workouts_tab_tour',
        'Workouts Tab',
        'Quick actions + Today + library',
        Icons.calendar_view_week_rounded,
        ['has_seen_workouts_tab_tour', 'has_seen_empty_tour_workouts_v1'],
      ),
      (
        'discover_tour',
        'Discover',
        'Leaderboard + peer profiles walkthrough',
        Icons.public,
        ['has_seen_empty_tour_discover_v1'],
      ),
      (
        'schedule_tour',
        'Workout Schedule',
        'Calendar + workout card walkthrough',
        Icons.calendar_today_outlined,
        ['has_seen_schedule_tour'],
      ),
      (
        'profile_tour',
        'Profile',
        'Profile + stats walkthrough',
        Icons.person_outline,
        ['has_seen_profile_tour'],
      ),
    ];

    showGlassSheet<void>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).settingsTutorialsHints, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).settingsScreenExtReplayTheOnboardingWalkthro, style: TextStyle(fontSize: 13, color: textMuted)),
              const SizedBox(height: 16),
              // Primary: re-fire the entire first-run sequence the user saw at
              // onboarding. Clears every tour key + inline-hint flag in one
              // shot, then routes back to /home so the nav tour kicks off
              // immediately and follow-on tours fire as the user navigates.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    AppLocalizations.of(context).settingsScreenExtReplayOnboardingWalkthrough,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    for (final tour in tours) {
                      for (final key in tour.$5) {
                        await prefs.remove(key);
                      }
                    }
                    await Tooltips.resetAll();
                    ref.read(appTourControllerProvider.notifier).dismiss();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AppSnackBar.info(
                        context,
                        'Walkthrough reset — head to Home to start it again',
                      );
                      if (context.mounted) context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).settingsScreenExtReplayIndividualTours, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: tours.map((tour) {
                    final (tourId, label, subtitle, icon, keys) = tour;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(icon, color: textMuted, size: 22),
                        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted)),
                        trailing: TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            for (final key in keys) {
                              await prefs.remove(key);
                            }
                            ref.read(appTourControllerProvider.notifier).dismiss();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              AppSnackBar.info(context, '$label tutorial will replay on next visit');
                            }
                          },
                          child: Text(AppLocalizations.of(context).settingsScreenExtReplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: elevated.withValues(alpha: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: cardBorder.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).settingsScreenExtInlineHints, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).settingsScreenExtSmallEmptyStateHints,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.tips_and_updates_outlined, size: 18, color: textPrimary),
                  label: Text(AppLocalizations.of(context).settingsScreenExtResetInlineHints, style: TextStyle(fontSize: 14, color: textPrimary)),
                  onPressed: () async {
                    final cleared = await Tooltips.resetAll();
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    AppSnackBar.info(
                      context,
                      cleared == 0
                          ? 'No hints to reset — they will appear naturally as you use new screens.'
                          : 'Reset $cleared hint${cleared == 1 ? '' : 's'} — they\'ll show again on your next visit.',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('${Branding.appName}'),
          ],
        ),
        content: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.hasData
                ? AppLocalizations.of(context)!.settingsScreenExtVersion(snapshot.data!.version, snapshot.data!.buildNumber)
                : 'Loading version...';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).settingsScreenExtYourAiPoweredPersonal,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Onboarding v5.1: re-entry to the founder note for users who
                // either missed the auto-trigger or want to revisit it. Always
                // renders, never gated by seen-flags.
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pop(context);
                    FounderNoteSheet.showManual(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/founder_chetan.jpg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 32,
                              color: AppColors.orange.withValues(alpha: 0.2),
                              alignment: Alignment.center,
                              child: const Text(
                                'C',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context).settingsScreenExtANoteFromChetan,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.settingsScreenExtWhyIBuilt(Branding.appName),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColorsLight.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.orange,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).commonClose,
              style: TextStyle(
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _onVersionTap() {
    final now = DateTime.now();
    final isBeastModeUnlocked = ref.read(beastModeProvider);

    if (isBeastModeUnlocked) {
      AppSnackBar.info(context, 'Beast Mode is already unlocked!');
      return;
    }

    // Reset counter if more than 3 seconds since last tap
    if (_lastVersionTap != null &&
        now.difference(_lastVersionTap!).inSeconds >= 3) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount++;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _unlockBeastMode();
    } else if (_versionTapCount >= 3) {
      final remaining = 7 - _versionTapCount;
      AppSnackBar.info(context, '$remaining taps away from Beast Mode...');
      HapticService.light();
    }
  }

}
