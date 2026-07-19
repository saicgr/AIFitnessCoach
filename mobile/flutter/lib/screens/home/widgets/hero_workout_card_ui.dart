part of 'hero_workout_card.dart';

/// UI builder methods extracted from _HeroWorkoutCardState
extension _HeroWorkoutCardStateUI on _HeroWorkoutCardState {

  /// Completed-state overlay. Branches on synced (cyan, Apple-Health style,
  /// no Repeat / Share — those buttons assume Zealova-shaped data) vs
  /// Zealova-completed (green, full action set). Replaces the previous
  /// inline overlay that rendered identical green "Workout Complete" UI
  /// for both, which made synced cardio look like a finished Zealova plan.
  Widget _buildCompletedOverlay({
    required Workout workout,
    required bool isDark,
  }) {
    final synced = workout.isSyncedFromHealthApp;
    final accent = synced ? AppColors.cyan : AppColors.success;
    final headline = synced
        ? 'Synced from ${workout.syncedPlatformLabel}'
        : 'Workout Complete';
    final iconData = synced ? Icons.favorite_rounded : Icons.check_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      // A5/perf: blur a COPY of the hero background (one image, GPU-cached by
      // URL via CachedNetworkImage) instead of a BackdropFilter, which
      // saveLayer()s the entire scene behind the card every frame it's on
      // screen — a steady-state scroll cost since a completed today-workout
      // hero shows this overlay on Home. Mirrors the completed-hero background
      // in unified_home_widgets (`_buildCompletedBackground`).
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: _buildBackground(isDark),
          ),
          DecoratedBox(
          // Dark-accent legibility scrim (was a flat 20-25% tint that left the
          // headline + name unreadable over light blurred art). White text now
          // clears contrast in both themes, so the labels below are forced
          // white rather than theme-aware black.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.black.withValues(alpha: 0.30), accent)
                    .withValues(alpha: 0.82),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.52), accent)
                    .withValues(alpha: 0.88),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 36,
                  weight: 800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workout.name ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Synced rows: Repeat (no Zealova plan to clone) and
                  // Share (backend share-link rejects non-Zealova workouts)
                  // are hidden — only Summary remains.
                  if (!synced)
                    _buildOverlayButton(
                      icon: Icons.replay,
                      label: AppLocalizations.of(context).heroWorkoutCardRepeat,
                      onTap: _repeatWorkout,
                      isDark: isDark,
                    ),
                  if (!synced && workout.completionMethod == 'marked_done')
                    _buildOverlayButton(
                      icon: Icons.undo,
                      label: AppLocalizations.of(context).workoutUiBuildersUndo,
                      onTap: _markAsUndone,
                      isDark: isDark,
                    ),
                  _buildOverlayButton(
                    icon: Icons.bar_chart,
                    label: AppLocalizations.of(context).workoutCompleteSummary,
                    onTap: _viewSummary,
                    isDark: isDark,
                  ),
                  if (!synced)
                    _buildOverlayButton(
                      icon: Icons.ios_share_rounded,
                      label: AppLocalizations.of(context).commonShare,
                      onTap: _shareCompletedWorkout,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
          ),
          ],
        ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // Frosted-white pills over the dark scrim — white in both themes so
          // the icon + label stay legible (the scrim is dark regardless of
          // theme now).
          color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBackground(bool isDark) {
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    if (_isLoadingImage) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFF0F4F8), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Prefer the PER-EXERCISE illustration (matches the Home hero card in
    // unified_home_widgets.dart, which the user expects this surface to mirror).
    // The bundled per-workout-type art (`strength.png` etc.) is only the
    // fail-soft fallback when the workout's first exercise has no image — that
    // way a "Gentle Upper Strength" card shows the actual exercise, not the
    // generic squat figure. Final fallback is the accent gradient.
    if (_backgroundImageUrl != null) {
      return _wrapHeroWithFigureFade(
        isDark: isDark,
        accentColor: accentColor,
        child: CachedNetworkImage(
          imageUrl: _backgroundImageUrl!,
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, 0.32),
          memCacheWidth: 400,
          memCacheHeight: 400,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholder: (_, __) => const SizedBox.shrink(),
          // No per-exercise image after all → fall through to the bundled
          // type art if one is mapped, else nothing (gradient shows behind).
          errorWidget: (_, __, ___) => _typeAssetPath != null
              ? Image.asset(
                  _typeAssetPath!,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.0, 0.32),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    // No per-exercise image resolved (empty workout / unnamed first exercise /
    // lookup pending or failed) — fall back to the bundled per-workout-type
    // illustration (Upper / Lower / Cardio / HIIT / Yoga / etc.).
    if (_typeAssetPath != null) {
      return _wrapHeroWithFigureFade(
        isDark: isDark,
        accentColor: accentColor,
        child: Image.asset(
          _typeAssetPath!,
          fit: BoxFit.cover,
          // Bias the crop so the figure's TORSO sits center-frame and any
          // overflow happens at the top edge (where the head fade hides it).
          alignment: const Alignment(0.0, 0.32),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    return _buildFallbackBackground(isDark);
  }

  /// Common wrapper used by both the per-workout-type asset path and the
  /// per-exercise network image path: paints the accent-tinted background
  /// gradient behind the figure, lays the image on top, and overlays a
  /// top-fade gradient that masks the upper ~40% of the image (the region
  /// where the figure's head ends up when the source illustration is
  /// taller than the card crop window). Combined with `Alignment(0, 0.55)`
  /// the result reads as a faded, top-soft figure rather than a hard
  /// "headless torso" cut.
  Widget _wrapHeroWithFigureFade({
    required bool isDark,
    required Color accentColor,
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient behind the figure.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Color.lerp(const Color(0xFF1a1a2e), accentColor, 0.1)!,
                      const Color(0xFF0f0f1a),
                    ]
                  : [
                      Color.lerp(Colors.white, accentColor, 0.05)!,
                      Color.lerp(const Color(0xFFF0F4F8), accentColor, 0.1)!,
                    ],
            ),
          ),
        ),
        child,
        // Top fade — opaque accent-tinted at the very top, transparent
        // around 45% down. Hides the headless-torso crop that the
        // existing /exercise-images illustrations produce when shown as
        // a wide hero. Mirrors the dark-mode background so the fade is
        // seamless against whichever surface the figure sits on.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.22, 0.55],
                // Lighter accent-tinted top fade so the illustration is not
                // ghosted by the theme colour (was 0.15/0.10 dark, 0.18/0.10
                // light). Just enough to soften the top-edge crop.
                colors: isDark
                    ? [
                        Color.lerp(const Color(0xFF1a1a2e), accentColor, 0.06)!,
                        Color.lerp(const Color(0xFF1a1a2e), accentColor, 0.04)!
                            .withValues(alpha: 0.35),
                        Colors.transparent,
                      ]
                    : [
                        Color.lerp(Colors.white, accentColor, 0.07)!,
                        Color.lerp(Colors.white, accentColor, 0.04)!
                            .withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildFallbackBackground(bool isDark) {
    // Get accent color for consistent theming
    final accentColorEnum = ref.read(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    if (isDark) {
      // Dark mode - deep, rich gradient with accent tint
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              Color.lerp(const Color(0xFF16213e), accentColor, 0.15)!,
              const Color(0xFF0f0f1a),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [accentColor, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Faint icon
            Center(
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.fitness_center,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Light mode - clean white/gray with subtle accent glow
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF8F9FA),
              const Color(0xFFF0F2F5),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle accent glow at top
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle bottom glow
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Faint icon
            Center(
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.fitness_center,
                  size: 200,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

}
