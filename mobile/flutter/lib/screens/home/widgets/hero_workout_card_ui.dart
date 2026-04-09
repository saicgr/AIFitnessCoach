part of 'hero_workout_card.dart';

/// UI builder methods extracted from _HeroWorkoutCardState
extension _HeroWorkoutCardStateUI on _HeroWorkoutCardState {

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
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
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

    if (_backgroundImageUrl != null) {
      // Image with a nice gradient background behind it (accent-tinted)
      return Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient with accent color tint
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
          // The actual image
          CachedNetworkImage(
            imageUrl: _backgroundImageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            // Perf fix 2.2: limit decoded image size in memory cache
            memCacheWidth: 400,
            memCacheHeight: 400,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    return _buildFallbackBackground(isDark);
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
