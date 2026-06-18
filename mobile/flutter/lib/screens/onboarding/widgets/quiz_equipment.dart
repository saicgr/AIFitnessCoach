import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../workout/widgets/equipment_snap_flow.dart';
import 'onboarding_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

/// One-tap equipment preset that replaces the user's current selection.
///
/// Surfaces common combos (Bodyweight + Pullup Bar, Home + Dumbbells,
/// etc.) so users with simple setups don't have to hunt through 11
/// individual chips. Each preset's [equipmentIds] becomes the entire
/// selection on tap. The full chip grid stays editable below — presets
/// are an accelerator, not a constraint.
class _EquipmentPreset {
  final String id;
  final String label;
  final IconData icon;
  final List<String> equipmentIds;

  const _EquipmentPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.equipmentIds,
  });
}

/// Workout environment options for quick selection
class _WorkoutEnvironmentOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final List<String> defaultEquipment;

  const _WorkoutEnvironmentOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.defaultEquipment,
  });
}

/// A titled section in the visual equipment picker (e.g. "Free weights",
/// "Bands & accessories"). Groups related [items] under one band.
class _EquipmentCategory {
  final String title;
  final IconData icon;
  final List<_VisualItem> items;

  const _EquipmentCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// A single tappable equipment tile in the visual picker. [id] is the
/// canonical equipment id shared with the chip mode, so selection state is
/// identical regardless of which mode rendered the tile.
class _VisualItem {
  final String id;
  final String label;
  final IconData icon;

  const _VisualItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Follow-up suggestion shown after selecting certain equipment
class _FollowUp {
  final String suggest;
  final String title;
  final String subtitle;

  const _FollowUp({
    required this.suggest,
    required this.title,
    required this.subtitle,
  });
}

/// Equipment selection widget for quiz screens.
class QuizEquipment extends StatefulWidget {
  final Set<String> selectedEquipment;
  final int dumbbellCount;
  final int kettlebellCount;
  final ValueChanged<String> onEquipmentToggled;
  final ValueChanged<int> onDumbbellCountChanged;
  final ValueChanged<int> onKettlebellCountChanged;
  final Function(BuildContext, String, bool) onInfoTap;
  final VoidCallback? onOtherTap;
  final Set<String> otherSelectedEquipment;
  final String? selectedEnvironment;
  final ValueChanged<String>? onEnvironmentChanged;
  final bool showHeader;
  /// Optional callback fired when the user taps a quick-preset chip.
  /// Should REPLACE the parent's current selection with [ids]. When null,
  /// the preset row is hidden — keeps the API backwards-compatible for
  /// callers that haven't opted in yet (e.g. legacy edit screens).
  final ValueChanged<List<String>>? onPresetSelected;

  /// Kill-switch for the visual, categorized, searchable picker
  /// (`onboarding_equipment_visual`, default ON). When true (default) the
  /// step renders an always-visible search field plus a categorized grid
  /// of equipment tiles with icon thumbnails. When false, it renders the
  /// EXISTING two-column chip grid unchanged — the safe fallback. The
  /// parent resolves the flag and passes it in; both modes share the same
  /// [selectedEquipment] set, callbacks and custom-equipment flow, so the
  /// resulting selection is identical regardless of mode.
  final bool visualMode;

  const QuizEquipment({
    super.key,
    required this.selectedEquipment,
    required this.dumbbellCount,
    required this.kettlebellCount,
    required this.onEquipmentToggled,
    required this.onDumbbellCountChanged,
    required this.onKettlebellCountChanged,
    required this.onInfoTap,
    this.onOtherTap,
    this.otherSelectedEquipment = const {},
    this.selectedEnvironment,
    this.onEnvironmentChanged,
    this.showHeader = true,
    this.onPresetSelected,
    this.visualMode = true,
  });

  static List<_WorkoutEnvironmentOption> _buildEnvironments(AppLocalizations l10n) => [
    _WorkoutEnvironmentOption(
      id: 'commercial_gym',
      label: l10n.quizEquipmentGym,
      emoji: '\u{1F3E2}',
      description: l10n.quizEquipmentFullGymWithMachines,
      defaultEquipment: const ['full_gym'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home',
      label: l10n.quizEquipmentHome,
      emoji: '\u{1F3E1}',
      description: l10n.quizEquipmentMinimalEquipmentBodyweight,
      defaultEquipment: const ['bodyweight'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home_gym',
      label: l10n.quizEquipmentHomeGym,
      emoji: '\u{1F3E0}',
      description: l10n.quizEquipmentDedicatedSpaceWithDumbbells,
      defaultEquipment: const ['bodyweight', 'dumbbells', 'barbell', 'resistance_bands', 'pull_up_bar', 'kettlebell'],
    ),
    _WorkoutEnvironmentOption(
      id: 'hotel',
      label: l10n.quizEquipmentHotel,
      emoji: '\u{1F9F3}',
      description: l10n.quizEquipmentTravelFriendlyDumbbellsC,
      defaultEquipment: const ['bodyweight', 'dumbbells', 'resistance_bands'],
    ),
  ];

  /// Common-combo presets surfaced as a horizontal-scroll row above the
  /// 11-chip grid. Each preset's [equipmentIds] REPLACES the user's
  /// selection on tap. After a tap, individual chip toggles still work —
  /// a tap that diverges from the preset just means "I'm now custom".
  ///
  /// Order matters: the first preset that exact-matches the current
  /// selection gets the active highlight (see `_activePresetId`).
  static List<_EquipmentPreset> _buildPresets(AppLocalizations l10n) => [
    _EquipmentPreset(
      id: 'preset_bodyweight_only',
      label: l10n.quizEquipmentBodyweightOnly,
      icon: Icons.accessibility_new,
      equipmentIds: const ['bodyweight'],
    ),
    _EquipmentPreset(
      id: 'preset_bodyweight_pullup',
      label: l10n.quizEquipmentBodyweightPullUpBar,
      icon: Icons.sports_gymnastics,
      equipmentIds: const ['bodyweight', 'pull_up_bar'],
    ),
    _EquipmentPreset(
      id: 'preset_bodyweight_bands',
      label: l10n.quizEquipmentBodyweightBands,
      icon: Icons.cable,
      equipmentIds: const ['bodyweight', 'resistance_bands'],
    ),
    _EquipmentPreset(
      id: 'preset_home_dumbbells_bench',
      label: l10n.quizEquipmentHomeDumbbellsBench,
      icon: Icons.fitness_center,
      equipmentIds: const ['bodyweight', 'dumbbells', 'bench'],
    ),
    _EquipmentPreset(
      id: 'preset_home_kettlebell',
      label: l10n.quizEquipmentHomeKettlebell,
      icon: Icons.sports_handball,
      equipmentIds: const ['bodyweight', 'kettlebell'],
    ),
    _EquipmentPreset(
      id: 'preset_apartment_minimal',
      label: l10n.quizEquipmentApartmentFriendly,
      icon: Icons.home_outlined,
      equipmentIds: const ['bodyweight', 'resistance_bands', 'kettlebell'],
    ),
    _EquipmentPreset(
      id: 'preset_full_gym',
      label: l10n.quizEquipmentFullGym,
      icon: Icons.store,
      equipmentIds: const ['full_gym'],
    ),
  ];

  /// Pure-data preset map used for logic (e.g. `_activePresetId`) that needs
  /// no BuildContext / l10n. Mirrors the order of `_buildPresets`.
  static const _presetEquipmentIds = <String, List<String>>{
    'preset_bodyweight_only': ['bodyweight'],
    'preset_bodyweight_pullup': ['bodyweight', 'pull_up_bar'],
    'preset_bodyweight_bands': ['bodyweight', 'resistance_bands'],
    'preset_home_dumbbells_bench': ['bodyweight', 'dumbbells', 'bench'],
    'preset_home_kettlebell': ['bodyweight', 'kettlebell'],
    'preset_apartment_minimal': ['bodyweight', 'resistance_bands', 'kettlebell'],
    'preset_full_gym': ['full_gym'],
  };

  static const _allEquipmentIds = [
    'bodyweight',
    'dumbbells',
    'barbell',
    'resistance_bands',
    'pull_up_bar',
    'kettlebell',
    'cable_machine',
    'bench',
    'squat_rack',
    'medicine_ball',
    'trx',
  ];

  static List<Map<String, Object>> _buildEquipment(AppLocalizations l10n) => [
    {'id': 'full_gym', 'label': l10n.quizEquipmentFullGymAccess, 'icon': Icons.store},
    {'id': 'bodyweight', 'label': l10n.quizEquipmentBodyweightOnly2, 'icon': Icons.accessibility_new},
    {'id': 'dumbbells', 'label': l10n.quizEquipmentDumbbells, 'icon': Icons.fitness_center, 'hasQuantity': true},
    {'id': 'barbell', 'label': l10n.quizEquipmentBarbell, 'icon': Icons.line_weight},
    {'id': 'bench', 'label': l10n.quizEquipmentFlatBench, 'icon': Icons.weekend, 'subtitle': l10n.quizEquipmentEnablesChestPress},
    {'id': 'squat_rack', 'label': l10n.quizEquipmentSquatRack, 'icon': Icons.fitness_center, 'subtitle': l10n.quizEquipmentNeededForBarbell},
    {'id': 'resistance_bands', 'label': l10n.quizEquipmentResistanceBands, 'icon': Icons.cable},
    {'id': 'pull_up_bar', 'label': l10n.quizEquipmentPullUpBar, 'icon': Icons.sports_gymnastics},
    {'id': 'kettlebell', 'label': l10n.quizEquipmentKettlebell, 'icon': Icons.sports_handball, 'hasQuantity': true},
    {'id': 'cable_machine', 'label': l10n.quizEquipmentCableMachine, 'icon': Icons.settings_ethernet},
    {'id': 'medicine_ball', 'label': l10n.quizEquipmentMedicineBall, 'icon': Icons.circle},
    {'id': 'trx', 'label': l10n.quizEquipmentTrxSuspension, 'icon': Icons.swap_vert},
  ];

  /// Visual-mode category grouping. Each section is a titled band of
  /// equipment tiles (icon thumbnail + label). The IDs reference the same
  /// canonical equipment set used everywhere else (`_buildEquipment`), so
  /// tapping a tile toggles the identical `selectedEquipment` entry the
  /// chip mode would. `full_gym` is intentionally surfaced as its own
  /// "Quick access" entry — selecting it collapses to a full-gym setup via
  /// the existing `_hasFullGym` logic.
  static List<_EquipmentCategory> _buildVisualCategories(AppLocalizations l10n) => [
    _EquipmentCategory(
      title: 'Essentials',
      icon: Icons.star_outline,
      items: [
        _VisualItem(id: 'full_gym', label: l10n.quizEquipmentFullGymAccess, icon: Icons.store),
        _VisualItem(id: 'bodyweight', label: l10n.quizEquipmentBodyweightOnly2, icon: Icons.accessibility_new),
      ],
    ),
    _EquipmentCategory(
      title: 'Free weights',
      icon: Icons.fitness_center,
      items: [
        _VisualItem(id: 'dumbbells', label: l10n.quizEquipmentDumbbells, icon: Icons.fitness_center),
        _VisualItem(id: 'barbell', label: l10n.quizEquipmentBarbell, icon: Icons.line_weight),
        _VisualItem(id: 'kettlebell', label: l10n.quizEquipmentKettlebell, icon: Icons.sports_handball),
        _VisualItem(id: 'medicine_ball', label: l10n.quizEquipmentMedicineBall, icon: Icons.circle),
      ],
    ),
    _EquipmentCategory(
      title: 'Benches & racks',
      icon: Icons.weekend,
      items: [
        _VisualItem(id: 'bench', label: l10n.quizEquipmentFlatBench, icon: Icons.weekend),
        _VisualItem(id: 'squat_rack', label: l10n.quizEquipmentSquatRack, icon: Icons.grid_on),
      ],
    ),
    _EquipmentCategory(
      title: 'Machines & cables',
      icon: Icons.settings_ethernet,
      items: [
        _VisualItem(id: 'cable_machine', label: l10n.quizEquipmentCableMachine, icon: Icons.settings_ethernet),
      ],
    ),
    _EquipmentCategory(
      title: 'Bands & accessories',
      icon: Icons.cable,
      items: [
        _VisualItem(id: 'resistance_bands', label: l10n.quizEquipmentResistanceBands, icon: Icons.cable),
        _VisualItem(id: 'pull_up_bar', label: l10n.quizEquipmentPullUpBar, icon: Icons.sports_gymnastics),
        _VisualItem(id: 'trx', label: l10n.quizEquipmentTrxSuspension, icon: Icons.swap_vert),
      ],
    ),
  ];

  /// Follow-up suggestions: selecting a primary equipment suggests a secondary
  static Map<String, _FollowUp> _buildEquipmentFollowUps(AppLocalizations l10n) => {
    'dumbbells': _FollowUp(
      suggest: 'bench',
      title: l10n.quizEquipmentDoYouHaveA,
      subtitle: l10n.quizEquipmentUnlocksBenchPressIncline,
    ),
    'kettlebell': _FollowUp(
      suggest: 'bench',
      title: l10n.quizEquipmentDoYouHaveA,
      subtitle: l10n.quizEquipmentUnlocksChestSupportedKb,
    ),
    'barbell': _FollowUp(
      suggest: 'squat_rack',
      title: l10n.quizEquipmentDoYouHaveA2,
      subtitle: l10n.quizEquipmentRequiredForBarbellSquat,
    ),
  };

  @override
  State<QuizEquipment> createState() => _QuizEquipmentState();
}

class _QuizEquipmentState extends State<QuizEquipment> {
  final _shownFollowUps = <String>{};

  // Always-visible search field (visual mode only). Filters the categorized
  // grid by label/id; an empty query shows every category.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Maps equipment ID → suggested follow-up equipment ID (for logic only, no i18n needed).
  static const _followUpSuggest = {
    'dumbbells': 'bench',
    'kettlebell': 'bench',
    'barbell': 'squat_rack',
  };

  bool get _hasFullGym =>
      widget.selectedEquipment.contains('full_gym') ||
      QuizEquipment._allEquipmentIds.every((id) => widget.selectedEquipment.contains(id));

  /// Check if a chip should show the "Recommended" badge
  bool _isRecommended(String chipId) {
    if (_hasFullGym || widget.selectedEquipment.contains(chipId)) return false;
    for (final entry in _followUpSuggest.entries) {
      if (entry.value == chipId && widget.selectedEquipment.contains(entry.key)) {
        return true;
      }
    }
    return false;
  }

  void _handleChipTap(String id) {
    HapticFeedback.selectionClick();
    final wasSelected = widget.selectedEquipment.contains(id);
    widget.onEquipmentToggled(id);
    // After toggling ON, check for follow-up
    if (!wasSelected) {
      _checkFollowUp(context, id);
    }
  }

  void _checkFollowUp(BuildContext context, String itemId) {
    final followUps = QuizEquipment._buildEquipmentFollowUps(AppLocalizations.of(context)!);
    final followUp = followUps[itemId];
    if (followUp == null) return;
    if (widget.selectedEquipment.contains(followUp.suggest)) return;
    if (_hasFullGym) return;
    if (_shownFollowUps.contains(itemId)) return;
    _shownFollowUps.add(itemId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showFollowUpDialog(context, followUp);
    });
  }

  void _showFollowUpDialog(BuildContext context, _FollowUp followUp) {
    final t = OnboardingTheme.of(context);
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  followUp.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  followUp.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: t.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: t.cardFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.borderDefault),
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.onboardingSkip,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.onEquipmentToggled(followUp.suggest);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: t.selectionAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.quizEquipmentYesAddIt,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            _buildTitle(context, t),
            const SizedBox(height: 6),
            _buildSubtitle(context, t),
            const SizedBox(height: 12),
          ],
          // Environment quick selection chips
          if (widget.onEnvironmentChanged != null) ...[
            _buildEnvironmentSection(context, t),
            const SizedBox(height: 12),
          ],
          // Snap-your-gym tile: opens the existing EquipmentSnapFlow in
          // identify mode, then maps identified canonical equipment names
          // into the onboarding preset IDs. Only shown when the parent
          // opted into preset/replace semantics — same gate as the preset
          // row so legacy callers (edit screens) stay unaffected.
          if (widget.onPresetSelected != null) ...[
            _buildSnapGymTile(context, t),
            const SizedBox(height: 12),
          ],
          // Quick-preset chips: one tap to pick a common combo. Hidden
          // when the parent didn't opt in via [onPresetSelected]. Kept on
          // TOP in BOTH modes — the fast path always wins.
          if (widget.onPresetSelected != null) ...[
            _buildPresetSection(context, t),
            const SizedBox(height: 12),
          ],
          // Always-visible search (visual mode only). Promotes the
          // formerly sheet-only search to the surface, Gravl-style.
          if (widget.visualMode) ...[
            _buildSearchField(context, t),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual categorized grid vs. legacy two-column chips.
                  // Both bind to the SAME selection set + callbacks.
                  if (widget.visualMode)
                    _buildVisualGrid(context, t)
                  else
                    _buildTwoColumnGrid(context, t),
                  // Quantity selectors shown below the grid when applicable
                  if (widget.selectedEquipment.contains('dumbbells') && !_hasFullGym) ...[
                    const SizedBox(height: 12),
                    _QuantityRow(
                      label: AppLocalizations.of(context)!.quizEquipmentDumbbells,
                      isSingle: widget.dumbbellCount == 1,
                      onSingle: () => widget.onDumbbellCountChanged(1),
                      onMultiple: () => widget.onDumbbellCountChanged(2),
                      onInfo: () => widget.onInfoTap(context, 'dumbbells', true),
                      icon: Icons.fitness_center,
                    ),
                  ],
                  if (widget.selectedEquipment.contains('kettlebell') && !_hasFullGym) ...[
                    const SizedBox(height: 8),
                    _QuantityRow(
                      label: AppLocalizations.of(context)!.quizEquipmentKettlebell,
                      isSingle: widget.kettlebellCount == 1,
                      onSingle: () => widget.onKettlebellCountChanged(1),
                      onMultiple: () => widget.onKettlebellCountChanged(2),
                      onInfo: () => widget.onInfoTap(context, 'kettlebell', true),
                      icon: Icons.sports_handball,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Visual mode: search + categorized tile grid ────────────────────

  /// Always-visible search field that filters the categorized grid.
  Widget _buildSearchField(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.borderDefault),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: TextStyle(color: t.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.settingsCardPartSearchEquipment,
              hintStyle: TextStyle(color: t.textSecondary, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: t.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: t.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  /// Categorized grid of equipment tiles. Each section title bands a small
  /// group of icon tiles. A trailing "Other equipment" section preserves
  /// the existing custom-equipment search sheet (`onOtherTap`). When the
  /// search query matches nothing in the canonical set, we surface a
  /// "See all equipment" affordance into that same custom flow so the user
  /// can still find the long-tail (sandbags, machines, traditional kit).
  Widget _buildVisualGrid(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context);
    final query = _searchQuery.trim().toLowerCase();
    final categories = QuizEquipment._buildVisualCategories(l10n);

    final sections = <Widget>[];
    var visibleItemCount = 0;
    for (final category in categories) {
      final items = query.isEmpty
          ? category.items
          : category.items
              .where((it) =>
                  it.label.toLowerCase().contains(query) ||
                  it.id.toLowerCase().contains(query))
              .toList();
      if (items.isEmpty) continue;
      visibleItemCount += items.length;
      if (sections.isNotEmpty) sections.add(const SizedBox(height: 16));
      sections.add(_buildCategorySection(context, t, category, items));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections,
        // "Other equipment" affordance: always present (opens the existing
        // searchable custom sheet). When a search returns no canonical
        // matches, this becomes the primary call-to-action so nothing is
        // a dead end.
        if (widget.onOtherTap != null) ...[
          if (sections.isNotEmpty) const SizedBox(height: 16),
          _buildOtherSection(context, t, noCanonicalMatch: visibleItemCount == 0),
        ] else if (visibleItemCount == 0) ...[
          const SizedBox(height: 24),
          _buildNoResults(context, t),
        ],
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    OnboardingTheme t,
    _EquipmentCategory category,
    List<_VisualItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              Icon(category.icon, size: 15, color: t.textSecondary),
              const SizedBox(width: 6),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Wrap (not a fixed Row) so tiles reflow on an iPhone SE without
        // overflowing. Each tile is a fixed-aspect icon thumbnail + label.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => _buildVisualTile(context, t, item))
              .toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildVisualTile(
    BuildContext context,
    OnboardingTheme t,
    _VisualItem item,
  ) {
    final isFullGymOption = item.id == 'full_gym';
    final isSelected =
        isFullGymOption ? _hasFullGym : widget.selectedEquipment.contains(item.id);
    final recommended = _isRecommended(item.id);

    // 3-up on the narrowest phone: (screen - 40 padding - 2*10 spacing) / 3.
    final tileWidth = (MediaQuery.of(context).size.width - 40 - 20) / 3;

    return GestureDetector(
      onTap: () => _handleChipTap(item.id),
      child: SizedBox(
        width: tileWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: t.cardSelectedGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : t.cardFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? t.borderSelected
                          : recommended
                              ? t.checkBorderUnselected
                              : t.borderDefault,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon thumbnail puck.
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.selectionAccent.withValues(alpha: 0.18)
                              : t.textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? t.selectionAccent
                              : t.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Selected check badge, top-right.
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: t.checkBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: t.checkIcon, size: 13),
                ),
              ),
            // "Recommended" badge for follow-up suggestions.
            if (recommended && !isSelected)
              Positioned(
                top: -6,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: t.selectionAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).quizEquipmentRecommended,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: t.badgeText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "Other equipment" section reusing the existing custom-equipment flow
  /// (`onOtherTap` → searchable sheet). Doubles as the search empty-state
  /// when no canonical tile matched the query.
  Widget _buildOtherSection(
    BuildContext context,
    OnboardingTheme t, {
    required bool noCanonicalMatch,
  }) {
    final l10n = AppLocalizations.of(context);
    final hasOtherSelected = widget.otherSelectedEquipment.isNotEmpty;
    final title = noCanonicalMatch
        ? l10n.quizEquipmentNoEquipmentIdentifiedPick
        : (hasOtherSelected
            ? l10n.quizEquipmentOtherCount(widget.otherSelectedEquipment.length)
            : l10n.quizEquipmentOtherEquipment);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onOtherTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: hasOtherSelected
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasOtherSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasOtherSelected
                    ? t.borderSelected
                    : (noCanonicalMatch
                        ? t.selectionAccent.withValues(alpha: 0.4)
                        : t.borderDefault),
                width: hasOtherSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    noCanonicalMatch ? Icons.search : Icons.more_horiz,
                    color: hasOtherSelected ? t.textPrimary : t.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: hasOtherSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: t.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.equipmentSearchSearchFrom100Equipment,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: t.textSecondary,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: t.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 240.ms);
  }

  /// Empty-state shown only when the custom flow is unavailable (legacy
  /// callers without `onOtherTap`) and a search returns no canonical match.
  Widget _buildNoResults(BuildContext context, OnboardingTheme t) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.search_off, size: 40, color: t.textSecondary),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).equipmentSearchNoEquipmentFound,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Maps a snap-flow canonical equipment name (e.g. `lat_pulldown`,
  /// `dumbbell`, `barbell_back_squat_rack`) to the onboarding preset ID
  /// space (`dumbbells`, `barbell`, `squat_rack`, …). Anything machine-y
  /// (lat pulldown, leg press, cable column, smith machine, etc.) maps
  /// to `full_gym`. Unmatched canonicals are dropped — the user can
  /// always add them manually below.
  static const Map<String, String> _canonicalToOnboardingId = {
    'bodyweight': 'bodyweight',
    'dumbbell': 'dumbbells',
    'dumbbells': 'dumbbells',
    'barbell': 'barbell',
    'olympic_barbell': 'barbell',
    'ez_bar': 'barbell',
    'flat_bench': 'bench',
    'bench': 'bench',
    'adjustable_bench': 'bench',
    'incline_bench': 'bench',
    'squat_rack': 'squat_rack',
    'power_rack': 'squat_rack',
    'rack': 'squat_rack',
    'resistance_band': 'resistance_bands',
    'resistance_bands': 'resistance_bands',
    'pull_up_bar': 'pull_up_bar',
    'kettlebell': 'kettlebell',
    'medicine_ball': 'medicine_ball',
    'trx': 'trx',
    'suspension_trainer': 'trx',
    // Machine-class canonicals → imply a full-gym setup.
    'cable_machine': 'cable_machine',
    'cable_crossover': 'cable_machine',
    'lat_pulldown': 'full_gym',
    'seated_row_machine': 'full_gym',
    'leg_press': 'full_gym',
    'leg_extension': 'full_gym',
    'leg_curl': 'full_gym',
    'smith_machine': 'full_gym',
    'hack_squat': 'full_gym',
    'chest_press_machine': 'full_gym',
    'shoulder_press_machine': 'full_gym',
    'pec_deck': 'full_gym',
    'preacher_curl_bench': 'full_gym',
  };

  Future<void> _launchSnapFlow(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    try {
      // identify mode pops with null and writes the snapped equipment
      // server-side; we then GET the list and translate canonicals.
      await showEquipmentSnapFlow(
        context,
        ref,
        mode: SnapMode.identify,
      );
    } catch (e) {
      // Most commonly: camera permission denied — the snap flow handles
      // its own user-facing prompt, but if anything escapes, we show a
      // toast and silently fall back to the presets/manual grid.
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.quizEquipmentCouldnTOpenThe),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;

    // After the snap flow closes, fetch the user's snapped equipment list
    // and union the mapped IDs into the current selection. The user can
    // still deselect any false positive in the grid below — that
    // satisfies the "confirmation step" requirement (the grid IS the
    // confirm UI) and preserves the existing Skip behavior.
    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null || userId.isEmpty) return;
      final resp = await api.get(
        '${ApiConstants.apiBaseUrl}/users/$userId/snapped-equipment',
        queryParameters: {'limit': 100},
      );
      final data = resp.data;
      if (data is! Map) return;
      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      if (items.isEmpty) {
        // Nothing came back — surface a gentle toast so the user knows
        // why the grid didn't update, and falls through to manual.
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.quizEquipmentNoEquipmentIdentifiedPick),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      final ids = <String>{};
      // Always include bodyweight — every gym includes the user.
      ids.add('bodyweight');
      for (final item in items) {
        final canonical = (item['canonical_name'] ?? '').toString().toLowerCase();
        final mapped = _canonicalToOnboardingId[canonical];
        if (mapped != null) ids.add(mapped);
      }
      // If full_gym got added, collapse to just full_gym (matches how the
      // Full Gym preset behaves — see `_hasFullGym`).
      final selection = ids.contains('full_gym') ? ['full_gym'] : ids.toList();
      if (!mounted || !context.mounted) return;
      widget.onPresetSelected?.call(selection);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.quizEquipmentIdentifiedCount(selection.length),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Don't block onboarding — keep the user moving via the manual grid.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.quizEquipmentCouldnTLoadIdentified),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSnapGymTile(BuildContext context, OnboardingTheme t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return Consumer(
      builder: (context, ref, _) {
        return GestureDetector(
          onTap: () => _launchSnapFlow(context, ref),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.quizEquipmentU1f4f8SnapYour,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.quizEquipmentRecommended,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.quizEquipmentTakeAFewPhotos,
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: t.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _buildEnvironmentSection(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final environments = QuizEquipment._buildEnvironments(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.quizEquipmentWhereDoYouWorkout,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showEnvironmentInfo(context, t),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: t.textMuted,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: environments.map((env) {
              final isSelected = widget.selectedEnvironment == env.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onEnvironmentChanged?.call(env.id);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: t.cardSelectedGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : t.cardFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? t.borderSelected : t.borderDefault,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              env.emoji,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              env.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: t.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
        if (widget.selectedEnvironment != null) ...[
          const SizedBox(height: 8),
          Text(
            environments.firstWhere((e) => e.id == widget.selectedEnvironment).description,
            style: TextStyle(
              fontSize: 12,
              color: t.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(),
        ],
      ],
    );
  }

  /// Returns the preset whose [equipmentIds] exactly equal the current
  /// selection, ignoring 'full_gym' bookkeeping for the Full Gym tile.
  /// Returns null when the user's selection diverges from every preset
  /// — that's the "Custom" state and no preset chip highlights.
  String? get _activePresetId {
    final current = widget.selectedEquipment;
    for (final entry in QuizEquipment._presetEquipmentIds.entries) {
      final presetSet = entry.value.toSet();
      if (presetSet.length == current.length && presetSet.containsAll(current)) {
        return entry.key;
      }
    }
    return null;
  }

  Widget _buildPresetSection(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final presets = QuizEquipment._buildPresets(l10n);
    final activeId = _activePresetId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            l10n.quizEquipmentQuickPresets,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset.id == activeId;
              return _PresetChip(
                preset: preset,
                isActive: isActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onPresetSelected?.call(preset.equipmentIds);
                  // After replacing the selection, fire any follow-up
                  // prompts that would have applied if the user had
                  // toggled these chips one-by-one (e.g. dumbbells →
                  // "do you have a bench?"). Skip presets that ALREADY
                  // include the follow-up's `suggest` to avoid asking
                  // about something that's already selected.
                  final followUpsMap = QuizEquipment._buildEquipmentFollowUps(AppLocalizations.of(context)!);
                  for (final id in preset.equipmentIds) {
                    final followUp = followUpsMap[id];
                    if (followUp != null &&
                        !preset.equipmentIds.contains(followUp.suggest) &&
                        !_shownFollowUps.contains(id)) {
                      _shownFollowUps.add(id);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _showFollowUpDialog(context, followUp);
                      });
                      break; // one prompt at a time
                    }
                  }
                },
                theme: t,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEnvironmentInfo(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final environments = QuizEquipment._buildEnvironments(l10n);
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                l10n.quizEquipmentWorkoutEnvironment,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.quizEquipmentSelectingYourWorkoutEnviron,
                style: TextStyle(
                  fontSize: 14,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ...environments.map((env) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(env.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            env.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            env.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              Text(
                l10n.quizEquipmentYouCanCustomizeEquipment,
                style: TextStyle(
                  fontSize: 12,
                  color: t.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.quizEquipmentWhatEquipmentDoYou,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: t.textPrimary,
        height: 1.2,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.quizEquipmentSelectAllThatApply,
      style: TextStyle(
        fontSize: 13,
        color: t.textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTwoColumnGrid(BuildContext context, OnboardingTheme t) {
    final l10n = AppLocalizations.of(context)!;
    final chips = [
      ...QuizEquipment._buildEquipment(l10n).map((item) =>
        _buildEquipmentChip(context, item, t),
      ),
      _buildOtherChip(context, t),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < chips.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chips[i]),
              const SizedBox(width: 8),
              i + 1 < chips.length
                  ? Expanded(child: chips[i + 1])
                  : const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildEquipmentChip(
    BuildContext context,
    Map<String, dynamic> item,
    OnboardingTheme t,
  ) {
    final id = item['id'] as String;
    final isFullGymOption = id == 'full_gym';
    final isSelected = isFullGymOption ? _hasFullGym : widget.selectedEquipment.contains(id);
    final subtitle = item['subtitle'] as String?;
    final recommended = _isRecommended(id);

    return GestureDetector(
        onTap: () => _handleChipTap(id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: t.cardSelectedGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : t.cardFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? t.borderSelected
                          : recommended
                              ? t.checkBorderUnselected
                              : t.borderDefault,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: t.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: t.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? t.checkBg : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: t.borderDefault,
                                  width: 1.5,
                                ),
                        ),
                        child: isSelected ? Icon(Icons.check, color: t.checkIcon, size: 13) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // "Recommended" badge
            if (recommended)
              Positioned(
                top: -6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: t.selectionAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.quizEquipmentRecommended,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: t.badgeText,
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildOtherChip(BuildContext context, OnboardingTheme t) {
    final hasOtherSelected = widget.otherSelectedEquipment.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onOtherTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: hasOtherSelected
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasOtherSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasOtherSelected ? t.borderSelected : t.borderDefault,
                width: hasOtherSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.more_horiz,
                  color: hasOtherSelected ? t.textPrimary : t.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hasOtherSelected
                        ? AppLocalizations.of(context)!.quizEquipmentOtherCount(widget.otherSelectedEquipment.length)
                        : AppLocalizations.of(context)!.quizEquipmentOtherEquipment,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasOtherSelected ? FontWeight.w600 : FontWeight.w500,
                      color: t.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.search,
                  color: t.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick-preset chip rendered in the horizontal-scroll row above the
/// equipment grid. Active state = the user's current selection exactly
/// matches this preset. Tapping fires [onTap], which the parent uses to
/// REPLACE the entire selection.
class _PresetChip extends StatelessWidget {
  final _EquipmentPreset preset;
  final bool isActive;
  final VoidCallback onTap;
  final OnboardingTheme theme;

  const _PresetChip({
    required this.preset,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.cyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : Colors.white.withValues(alpha: 0.10),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              preset.icon,
              size: 16,
              color: isActive ? activeColor : theme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact quantity toggle row shown below the chip grid
class _QuantityRow extends StatelessWidget {
  final String label;
  final bool isSingle;
  final VoidCallback onSingle;
  final VoidCallback onMultiple;
  final VoidCallback onInfo;
  final IconData icon;

  const _QuantityRow({
    required this.label,
    required this.isSingle,
    required this.onSingle,
    required this.onMultiple,
    required this.onInfo,
    this.icon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: t.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: t.cardFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: t.borderDefault,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSingle();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSingle ? t.checkBg : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                      ),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: isSingle ? t.textPrimary : t.textSecondary,
                          fontSize: 13,
                          fontWeight: isSingle ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: t.borderDefault,
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onMultiple();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: !isSingle ? t.checkBg : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                      ),
                      child: Text(
                        '1+',
                        style: TextStyle(
                          color: !isSingle ? t.textPrimary : t.textSecondary,
                          fontSize: 13,
                          fontWeight: !isSingle ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onInfo,
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: t.textMuted,
          ),
        ),
      ],
    );
  }
}
