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
                    hintText: 'Search settings...',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DialogBulletPoint(
              text: 'Your account and profile',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All workout history',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All saved preferences',
              color: AppColors.error,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'You will need to sign up again to use the app.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, ref);
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // Concurrent double-tap guard. Capture-then-set so we never lose the
    // setState even if the second tap arrives before the first dialog opens.
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Pre-flight: warn if there's an active paid subscription. Google
    // doesn't auto-cancel Play subscriptions when an auth user is deleted —
    // the user keeps getting charged. Surface this BEFORE we destroy data.
    final subscription = ref.read(subscriptionProvider);
    if (subscription.tier != SubscriptionTier.free &&
        subscription.tier != SubscriptionTier.lifetime) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Active subscription'),
          content: const Text(
            'Deleting your account does NOT cancel your Play Store subscription. '
            'You will continue to be billed unless you cancel from the Play Store first.\n\n'
            'Cancel your subscription, then come back here to delete your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Open Play Store'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) {
        // Send them to manage subscriptions in Play Store and bail.
        await launchUrl(
          Uri.parse('https://play.google.com/store/account/subscriptions'),
          mode: LaunchMode.externalApplication,
        );
        if (mounted) setState(() => _isDeleting = false);
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null || userId.isEmpty) {
        throw Exception('User not found');
      }

      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      navigator.pop();

      if (response.statusCode == 200) {
        // Server confirmed the auth user is gone. Now scrub local state in
        // dependency order: RC first (so we don't leak the customer ID into
        // the next sign-in on this device), then analytics identities, then
        // SharedPreferences, then auth.
        // Guard against the Swift `EXC_BREAKPOINT` fatal that fires when
        // Purchases.* is called before `Purchases.configure(...)` has
        // completed (rare on a delete-account path, but possible if
        // configure failed silently at startup — e.g., missing API key).
        if (SubscriptionNotifier.isRevenueCatReady) {
          try {
            await Purchases.logOut();
          } catch (e) {
            // RC logOut throws if no user was identified; harmless here.
            debugPrint('RevenueCat logOut after delete: $e');
          }
        } else {
          debugPrint('⚠️ Skipping Purchases.logOut — RC not configured');
        }

        try {
          await Sentry.configureScope((scope) => scope.setUser(null));
        } catch (_) {}

        try {
          ref.read(posthogServiceProvider).reset();
        } catch (_) {}

        final prefs = await SharedPreferences.getInstance();
        // Preserve tour flags so tutorials don't replay after reset
        final tourFlags = <String, bool>{};
        for (final key in prefs.getKeys()) {
          if (key.startsWith('has_seen_')) {
            tourFlags[key] = prefs.getBool(key) ?? false;
          }
        }
        await prefs.clear();
        for (final entry in tourFlags.entries) {
          await prefs.setBool(entry.key, entry.value);
        }
        ref.read(onboardingStateProvider.notifier).reset();
        await ref.read(authStateProvider.notifier).signOut();
        router.go('/intro');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      try {
        navigator.pop();
      } catch (_) {}

      // Recognize the "wrong password / re-auth required" branch and route
      // the user toward password reset instead of dropping a generic error.
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') ||
          msg.contains('invalid password') ||
          msg.contains('re-authentication')) {
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Re-authentication required'),
              content: const Text(
                'We could not verify your password. Reset your password first, then try deleting your account again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    // No standalone /forgot-password route — sign out and
                    // route to /intro; the email sign-in screen has the
                    // "Forgot Password?" entry point.
                    await ref.read(authStateProvider.notifier).signOut();
                    router.go('/intro');
                  },
                  child: const Text('Reset password'),
                ),
              ],
            ),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }


  /// Reset Tips — clears every dismissed onboarding tour across BOTH
  /// tooltip systems (`EmptyStateTipTour` first-run hints AND
  /// `AppTour` multi-screen flows) so the next time the user lands on
  /// any tour-bearing screen the spotlights reappear. Single entry
  /// point so future tour systems hook in here once and the user
  /// keeps a single button.
  Future<void> _resetEmptyStateTips(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    final cleared = await Tooltips.resetAll();
    if (!context.mounted) return;
    final msg = cleared == 0
        ? 'No tips to reset.'
        : 'Reset $cleared tip${cleared == 1 ? '' : 's'} — they\'ll show again on your next visit.';
    scaffold.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showReplayTutorialsSheet(BuildContext context, WidgetRef ref, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    const tours = [
      ('nav_tour', 'Home Navigation', 'Home screen walkthrough', Icons.home_outlined),
      ('workout_tour', 'Active Workout', 'Workout screen walkthrough', Icons.fitness_center),
      ('nutrition_tour', 'Nutrition Tracking', 'Nutrition screen walkthrough', Icons.restaurant_outlined),
      ('schedule_tour', 'Workout Schedule', 'Schedule screen walkthrough', Icons.calendar_today_outlined),
      ('profile_tour', 'Profile', 'Profile screen walkthrough', Icons.person_outline),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Replay Tutorials', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 4),
              Text('Tap a tutorial to replay it next time you visit that screen', style: TextStyle(fontSize: 13, color: textMuted)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: tours.map((tour) {
                    final (tourId, label, subtitle, icon) = tour;
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
                            await prefs.remove('has_seen_$tourId');
                            ref.read(appTourControllerProvider.notifier).dismiss();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              AppSnackBar.info(context, '$label tutorial will replay on next visit');
                            }
                          },
                          child: Text('Replay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: elevated.withValues(alpha: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    for (final tour in tours) {
                      await prefs.remove('has_seen_${tour.$1}');
                    }
                    ref.read(appTourControllerProvider.notifier).dismiss();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AppSnackBar.info(context, 'All tutorials will replay on next visit');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Reset All Tutorials', style: TextStyle(fontSize: 14, color: textPrimary)),
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
                ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
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
                  'Your AI-powered personal fitness coach. Get personalized workout plans, track your progress, and achieve your fitness goals.',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    height: 1.5,
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
              'Close',
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
