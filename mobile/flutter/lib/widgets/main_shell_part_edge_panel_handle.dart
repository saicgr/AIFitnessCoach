part of 'main_shell.dart';


/// Samsung Edge Panel style handle for AI Coach access
/// A subtle, semi-transparent vertical bar on the right edge.
/// Tap or swipe left to open AI Coach. Draggable vertically.
class _EdgePanelHandle extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const _EdgePanelHandle({required this.onTap});

  @override
  ConsumerState<_EdgePanelHandle> createState() => _EdgePanelHandleState();
}


class _EdgePanelHandleState extends ConsumerState<_EdgePanelHandle> {
  double _verticalPosition = 0.3; // 0.0 = top, 1.0 = bottom
  bool _isDragging = false;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    // Load saved position after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _verticalPosition = ref.read(edgeHandlePositionProvider);
      });
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _horizontalDragDistance = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Track horizontal drag for swipe detection
    _horizontalDragDistance += details.delta.dx;

    // Update vertical position
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top + 100;
    const safeBottom = 180; // Above nav bar
    final usableHeight = screenHeight - safeTop - safeBottom;

    setState(() {
      _verticalPosition += details.delta.dy / usableHeight;
      _verticalPosition = _verticalPosition.clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    // Check for swipe left gesture (negative horizontal distance or velocity)
    final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
    if (_horizontalDragDistance < -30 || horizontalVelocity < -200) {
      // Swiped left - open AI Coach
      widget.onTap();
    }

    // Save position (persisted to SharedPreferences)
    ref.read(edgeHandlePositionProvider.notifier).setPosition(_verticalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(edgeHandleEnabledProvider);
    final isNavBarVisible = ref.watch(floatingNavBarVisibleProvider);

    // Don't show if disabled or nav bar is hidden (e.g., bottom sheet open)
    if (!isEnabled || !isNavBarVisible) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top + 100;
    const safeBottom = 180;
    final usableHeight = screenHeight - safeTop - safeBottom;
    final topOffset = safeTop + (usableHeight * _verticalPosition);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 0,
      top: topOffset,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Larger touch area for easier interaction
          width: 32,
          height: 90,
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _isDragging ? 22 : 16,
                height: _isDragging ? 58 : 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: _isDragging ? 0.2 : 0.12)
                      : Colors.white.withValues(alpha: _isDragging ? 0.7 : 0.55),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: _isDragging ? 0.3 : 0.15)
                        : Colors.black.withValues(alpha: _isDragging ? 0.12 : 0.06),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    size: _isDragging ? 18 : 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: _isDragging ? 0.7 : 0.5)
                        : Colors.black.withValues(alpha: _isDragging ? 0.45 : 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Minimal floating nav bar - expandable items show label when selected
class _FloatingNavBarWithAI extends ConsumerWidget {
  final int selectedIndex;
  final bool isSecondaryPage;
  final Function(int) onItemTapped;

  const _FloatingNavBarWithAI({
    required this.selectedIndex,
    required this.isSecondaryPage,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Compact nav bar dimensions (single source: chrome_constants.dart)
    const navBarHeight = kMainNavBarHeight;
    const fadeHeight = kMainNavFadeHeight;

    // Clean pill bar colors
    final pillBarColor = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.92)
        : Colors.grey.shade100.withValues(alpha: 0.95);

    // Unselected tabs read on the app's own muted-text token (#71717A in both
    // themes — byte-identical to the mockup's light `--t3`), NOT raw Material
    // greys. `Colors.grey.shade400` (#BDBDBD) on the white light background
    // measured ~2.0:1, so four of the five tabs read as DISABLED rather than
    // merely unselected.
    final iconMuted = ThemeColors.of(context).textMuted;

    // Signature nav: a seamless FROSTED-GLASS bar — docked full-width but
    // translucent + blurred so the scrolling content shows softly through it
    // (no hard opaque bar, only a whisper-thin top edge). Home-indicator inset
    // padded inside so the glass runs to the very bottom.
    return SizedBox(
      height: navBarHeight + bottomPadding + fadeHeight,
      child: Stack(
        children: [
          // NO blur (a BackdropFilter draws a hard-edged box). Just a soft fade —
          // transparent at the top → solid bg by the time it reaches the icons —
          // so the content scrolls and dissolves behind the nav with no edge/line.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0.0),
                      backgroundColor.withValues(alpha: 0.85),
                      backgroundColor,
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.4, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Docked icon row at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            child: SizedBox(
              height: navBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              // Tab order (2026-08 redesign): Home · Workout · Health
              // (center) · Nutrition · You. Coach left the bar — it is the
              // global ✦ pill beside Quick Log now — and Health took the slot
              // so sleep, recovery and body data get a top-level home. The
              // leaderboard lives in You › Stats & Rewards; selected icons are
              // the plain filled family.
              child: Row(
                children: [
                  Expanded(
                    child: _ExpandableNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: AppLocalizations.of(context).navHome,
                      isSelected: selectedIndex == 0,
                      onTap: () => onItemTapped(0),
                      accentColor: accentColor,
                      mutedColor: iconMuted,
                      isDark: isDark,
                    ),
                  ),
                  // GlobalKeys attached via KeyedSubtree instead of directly on
                  // the StatelessWidget — the nav bar is inside an
                  // AnimatedSlide/AnimatedOpacity that can hold two element
                  // trees mid-transition, and a GlobalKey mounted on the widget
                  // itself fires "Duplicate GlobalKey" during those frames.
                  // KeyedSubtree gives the key its own stable element boundary.
                  Expanded(
                    child: KeyedSubtree(
                      key: AppTourKeys.workoutNavKey,
                      child: _ExpandableNavItem(
                        icon: Icons.fitness_center_outlined,
                        label: AppLocalizations.of(context).navWorkout,
                        isSelected: selectedIndex == 1,
                        onTap: () => onItemTapped(1),
                        accentColor: accentColor,
                        mutedColor: iconMuted,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: AppTourKeys.healthNavKey,
                      // Heart-pulse glyph (a heart with an ECG trace through
                      // it), per the mockup — not a plain heart, which reads
                      // as "favourites", and not a generic activity icon.
                      //
                      // No badge: the unread-coach count moved to the global
                      // ✦ pill (`coach_floating_button.dart`), which is
                      // visible on EVERY tab rather than only while some other
                      // tab is selected. Health has no unread semantics of its
                      // own, and inventing one here would be a lie.
                      child: _ExpandableNavItem(
                        icon: Icons.monitor_heart_outlined,
                        label: AppLocalizations.of(context).navHealth,
                        isSelected: selectedIndex == 2,
                        onTap: () => onItemTapped(2),
                        accentColor: accentColor,
                        mutedColor: iconMuted,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: AppTourKeys.nutritionNavKey,
                      child: _ExpandableNavItem(
                        icon: Icons.restaurant_outlined,
                        label: AppLocalizations.of(context).navNutrition,
                        isSelected: selectedIndex == 3,
                        onTap: () => onItemTapped(3),
                        accentColor: accentColor,
                        mutedColor: iconMuted,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: AppTourKeys.communityNavKey,
                      // STEP 2 OF THE NAV EVOLUTION (recorded 2026-06-11):
                      // "Future Social = stage 1 inside You; stage 2 (if
                      // earned) You→Community tab, profile behind header
                      // avatar." Social earned it, so the You slot CONVERTS —
                      // the bar stays at five, a sixth tab was never on the
                      // table (Material 3 caps bottom nav at 5).
                      //
                      // The You hub is not deleted and `/profile` is not
                      // moved: it still lives in this same branch and is
                      // reached from the Community masthead avatar, so all ~40
                      // `/profile?tab=…` deep links keep landing exactly where
                      // they did.
                      child: _ExpandableNavItem(
                        // Two-person glyph, matching the mockup's Community
                        // tab (a pair of heads), not the single "You" head.
                        icon: Icons.people_outline,
                        label: AppLocalizations.of(context).navCommunity,
                        isSelected: selectedIndex == 4,
                        onTap: () => onItemTapped(4),
                        accentColor: accentColor,
                        mutedColor: iconMuted,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ),
          ],
        ),
      );
  }
}


/// Nav item — icon over an always-visible label. Every tab is named (not
/// just the selected one); the selected tab is accent-tinted.
class _ExpandableNavItem extends StatelessWidget {
  final IconData icon;

  /// Glyph swapped in while selected. Optional — when omitted the tab keeps
  /// its OUTLINED glyph when selected and is distinguished by the accent tint
  /// + the underline alone, which is what the mockup does for every tab except
  /// Home (`.tab.on` still carries `fill="none" stroke="currentColor"`).
  /// Home is the one deliberate exception: its house fills.
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Color mutedColor;
  final bool isDark;

  // The unread-count badge that used to live here went with the Coach tab
  // (2026-08 nav redesign). It now rides the global ✦ pill
  // (`coach_floating_button.dart`), which is visible on EVERY tab rather than
  // only while some other tab happens to be selected — a strictly better home
  // for it. No nav item has unread semantics any more.

  const _ExpandableNavItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? accentColor : mutedColor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      // Center the pill within an Expanded slot so the active-state fill
      // hugs the icon/label instead of stretching the entire slot width.
      child: Align(
        alignment: Alignment.center,
        child: AnimatedContainer(
        duration: kMotionStandard,
        curve: kMotionCurve,
        // 6, not 10. The tap target is the WHOLE Expanded slot (the
        // GestureDetector wraps the slot-filling Align, not this box), so the
        // padding only buys visual air — and the tracking below needs the
        // width more than the air does.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        // Signature: no pill fill — the accent-tinted icon + Barlow label +
        // the accent underline carry the active state (reserved accent).
        decoration: const BoxDecoration(),
        // Icon over an always-visible Barlow Condensed uppercase label; the
        // selected tab gets an accent underline THE WIDTH OF ITS OWN LABEL.
        //
        // `IntrinsicWidth` is what makes that true: it sizes the column to its
        // widest child (always the label — even "HOME" at 10 px Barlow
        // Condensed + 1.5 tracking is wider than the 21 px icon), and
        // `CrossAxisAlignment.stretch` then hands that exact width to the
        // underline. Previously the bar was a fixed 16 px stub under every
        // tab, so it read as a generic dot rather than the mockup's
        // `.tab.on .nl::after{left:-1px;right:-1px}` label rule that grows
        // under "NUTRITION" and shrinks under "YOU". One extra intrinsic pass
        // for five short strings — immaterial.
        child: IntrinsicWidth(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IconSpinPop(
              isSelected: isSelected,
              child: Icon(
                isSelected ? (selectedIcon ?? icon) : icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                color: color,
                fontSize: 10,
                // 1.5, per `.tab .nl{letter-spacing:1.5px}`. This tracking is
                // what makes the label read as the Barlow-condensed system
                // rather than a generic tab bar; it was cut to 0.5 to keep
                // "NUTRITION" on one line, and the horizontal padding above
                // (10 → 6) is what pays for it instead.
                letterSpacing: 1.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 5),
            // Colour cross-fade, not a width tween: the width is now the
            // label's (see IntrinsicWidth above), so there is nothing left to
            // animate horizontally.
            AnimatedContainer(
              duration: kMotionStandard,
              curve: kMotionCurve,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }
}

/// Plays a combined 360° rotation + bouncy scale pop when `isSelected`
/// transitions false→true. Used to make the nav-bar icon feel alive on
/// selection, mimicking the signature "snap-in" animation used in TikTok
/// / Instagram tab bars.
class _IconSpinPop extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const _IconSpinPop({
    required this.child,
    required this.isSelected,
  });

  @override
  State<_IconSpinPop> createState() => _IconSpinPopState();
}

class _IconSpinPopState extends State<_IconSpinPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMotionExpressive,
    );
    // Full 360° spin, eased out so it decelerates into rest.
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Bouncy scale: 1.0 → 1.3 → 1.0 with an overshoot at the peak so the
    // icon feels "alive." Two-stage TweenSequence for the overshoot.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _IconSpinPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      // Expressive motion respects the OS reduce-motion setting.
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value * 2 * math.pi,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}


/// Plus button with slight protrusion above the nav bar
class _ProtrudingPlusButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final bool isDark;
  final Color accentColor;

  const _ProtrudingPlusButton({
    required this.size,
    required this.onTap,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use dynamic accent color
    final buttonColor = accentColor;
    // Contrast icon: for colored accents use white, for monochrome use opposite
    final iconColor = _getContrastColor(buttonColor);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}


/// AI Coach button with coach avatar - reactive to coach persona
class _AICoachButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _AICoachButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch AI settings to reactively update when coach changes
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    return CoachAvatar(
      coach: coach,
      size: 56,
      showBorder: true,
      borderWidth: 3,
      showShadow: true,
      enableTapToView: false, // Tap opens chat
      onTap: onTap,
    );
  }
}


/// Individual navigation item with fluid expand animation
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool labelsExpanded;
  final VoidCallback onTap;
  final double itemHeight;
  final Color selectedColor;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.labelsExpanded,
    required this.onTap,
    required this.itemHeight,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Show label only when selected AND labels are expanded (not on secondary pages)
    final showLabel = isSelected && labelsExpanded;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: itemHeight,
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(itemHeight / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? selectedColor : textMuted,
                  size: 22,
                ),
              ),
              // Animated label - only shows when selected AND labels expanded
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: showLabel
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Floating back button for secondary pages - appears to the left of nav bar (like AI button)
class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyanColor = context.accentColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cyanColor,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: cyanColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}


/// Plus button for quick actions in the center of nav bar
class _PlusButton extends StatelessWidget {
  final double itemHeight;
  final VoidCallback onTap;

  const _PlusButton({
    required this.itemHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleColor = context.accentColor;

    return Semantics(
      label: AppLocalizations.of(context).mainShellPartQuickActions,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: itemHeight,
          width: itemHeight,
          decoration: BoxDecoration(
            color: purpleColor,
            borderRadius: BorderRadius.circular(itemHeight / 2),
            boxShadow: [
              BoxShadow(
                color: purpleColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}


/// Anchored nav item for standard bottom navigation bar (like Fitbod)
class _AnchoredNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double itemHeight;
  final Color selectedColor;
  final bool isDark;

  const _AnchoredNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.itemHeight,
    required this.selectedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeColor = isSelected ? selectedColor : textMuted;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: itemHeight,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: activeColor,
                size: 22,
              ),
              // Only show label when selected
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Anchored plus button for standard bottom navigation bar
class _AnchoredPlusButton extends StatelessWidget {
  final double itemHeight;
  final VoidCallback onTap;

  const _AnchoredPlusButton({
    required this.itemHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: AppLocalizations.of(context).mainShellPartQuickActions,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}


/// Elevated FAB that sits above the nav bar (like Fitbod/reference designs)
class _ElevatedFAB extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final bool isDark;

  const _ElevatedFAB({
    required this.size,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Use app's purple color for the FAB
    final fabColor = context.accentColor;

    return Semantics(
      label: AppLocalizations.of(context).mainShellPartQuickActions,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fabColor,
            shape: BoxShape.circle,
            // No shadow - clean look
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}


/// Anchored back button for secondary pages
class _AnchoredBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final double itemHeight;
  final bool isDark;

  const _AnchoredBackButton({
    required this.onTap,
    required this.itemHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cyanColor = context.accentColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: cyanColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).commonBack,
              style: TextStyle(
                color: cyanColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

