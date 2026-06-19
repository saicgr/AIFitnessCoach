import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/widgets/design_system/zealova.dart';
import 'package:fitwiz/widgets/design_system/section_header.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/liquid_glass_action_bar.dart';
import '../food_history_screen.dart';
import '../log_meal_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Defensive access to the new FoodLog signal columns (FE-E adds typed fields)
// ─────────────────────────────────────────────────────────────────────────────
//
// The `tags` / `symptoms` columns are added to the `FoodLog` model by a sibling
// agent (FE-E). To stay decoupled from the exact merge order we read them
// through `toJson()` rather than a hard field reference — this compiles whether
// or not the typed getters exist yet, and degrades to an empty list when the
// column is absent or null. Once FE-E lands the typed fields these helpers can
// be swapped for `log.tags` / `log.symptoms` directly (behaviour is identical).
extension _FoodLogSignals on FoodLog {
  List<String> get journalTags => _stringList(this, 'tags');
  List<String> get journalSymptoms => _stringList(this, 'symptoms');
}

List<String> _stringList(FoodLog log, String key) {
  try {
    final raw = log.toJson()[key];
    if (raw is List) {
      return raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    }
  } catch (_) {
    // toJson may not serialize an unknown key — treat as absent.
  }
  return const [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Range filter for the Feed view
// ─────────────────────────────────────────────────────────────────────────────

enum _JournalRange { today, week, month, all }

extension _JournalRangeLabel on _JournalRange {
  String get label {
    switch (this) {
      case _JournalRange.today:
        return 'Today';
      case _JournalRange.week:
        return 'Week';
      case _JournalRange.month:
        return 'Month';
      case _JournalRange.all:
        return 'All';
    }
  }

  /// (fromDate, toDate) as yyyy-MM-dd, or (null, null) for "all".
  (String?, String?) params() {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final tomorrow = fmt.format(now.add(const Duration(days: 1)));
    switch (this) {
      case _JournalRange.today:
        return (fmt.format(now), tomorrow);
      case _JournalRange.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (fmt.format(start), tomorrow);
      case _JournalRange.month:
        return (fmt.format(DateTime(now.year, now.month, 1)), tomorrow);
      case _JournalRange.all:
        return (null, null);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disk-cache key (cache-first instant paint, mirror of FoodHistoryScreen)
// ─────────────────────────────────────────────────────────────────────────────

const String _kJournalCacheKey = 'cachefirst::nutrition_journal::v1';

/// Warm, encouraging empty-state copy pool (≥4 variants per the dynamic-copy
/// rule — never a dead "nothing here").
const List<String> _kEmptyTitles = <String>[
  'Your food story starts here',
  'A blank page, waiting',
  'Nothing logged — yet',
  'Your journal is hungry',
];
const List<String> _kEmptySubtitles = <String>[
  'Snap your next meal and watch this space fill with color.',
  'Every photo you log becomes a memory you can scroll back through.',
  'Log a meal with a photo to begin your visual food diary.',
  'The first picture is the hardest. After that it gets satisfying.',
];

/// Image-first food Journal — the "what happened" memory surface that sits
/// between RECIPES and PATTERNS. Two internal views: a photo-collage Calendar
/// (default) and a scrapbook Feed, plus a collectible My Foods photo grid.
///
/// Reads only `getFoodLogs` (cross-date) + `getSavedFoods`; never mutates.
class NutritionJournalTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const NutritionJournalTab({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<NutritionJournalTab> createState() =>
      _NutritionJournalTabState();
}

class _NutritionJournalTabState extends ConsumerState<NutritionJournalTab>
    with AutomaticKeepAliveClientMixin {
  // 0 = Calendar, 1 = Feed, 2 = My Foods
  int _view = 0;

  // Calendar state.
  DateTime _calMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Feed state.
  _JournalRange _range = _JournalRange.all;

  // Shared cross-date logs (powers Calendar + Feed). Loaded once, cache-first.
  List<FoodLog> _logs = const [];
  bool _loadingLogs = true;
  bool _logsError = false;
  String? _scrollToDateKey; // set when a calendar day is tapped → Feed scroll
  // When non-null, the Feed is scoped to ONLY this yyyy-MM-dd day (set by
  // tapping a Calendar day). This OVERRIDES the `_range` filter so the user
  // sees exactly the day they tapped, with a "Showing <day>" banner + a
  // "Show all" affordance to return to the normal range view.
  String? _selectedDayKey;

  // Log IDs whose photo upload is in flight — drives the per-card loading state
  // on the "Add a photo" affordance so the user gets instant feedback.
  final Set<String> _attachingLogIds = <String>{};

  // My Foods grid.
  List<SavedFood> _savedFoods = const [];
  bool _loadingSaved = true;

  // Late-bound deterministic empty-copy index (stable per mount).
  late final int _emptySeed =
      DateTime.now().millisecondsSinceEpoch % _kEmptyTitles.length;

  @override
  bool get wantKeepAlive => true;

  String get _cacheKey => '$_kJournalCacheKey::${widget.userId}';

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    _loadLogs();
    _loadSaved();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final logsJson = decoded['logs'];
      if (logsJson is! List) return;
      final logs = logsJson
          .whereType<Map<String, dynamic>>()
          .map(FoodLog.fromJson)
          .toList();
      // Never overwrite fresher network data that may have already landed.
      if (!mounted || !_loadingLogs) return;
      setState(() {
        _logs = logs;
        _loadingLogs = false;
      });
    } catch (e) {
      debugPrint('💾 [Journal] cache hydrate failed: $e');
    }
  }

  Future<void> _writeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({'logs': _logs.take(200).map((l) => l.toJson()).toList()}),
      );
    } catch (e) {
      debugPrint('💾 [Journal] cache write failed: $e');
    }
  }

  Future<void> _loadLogs() async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      // Pull a wide cross-date window so both the month grid and the All feed
      // have material to render. 365 days × ~5 logs, capped.
      final now = DateTime.now();
      final from = DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 365)));
      final to =
          DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      final logs = await repo.getFoodLogs(
        widget.userId,
        limit: 500,
        fromDate: from,
        toDate: to,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loadingLogs = false;
        _logsError = false;
      });
      await _writeCache();
    } catch (e) {
      debugPrint('❌ [Journal] load logs failed: $e');
      if (!mounted) return;
      setState(() {
        _loadingLogs = false;
        // Only surface an error when there is genuinely nothing to show.
        _logsError = _logs.isEmpty;
      });
    }
  }

  Future<void> _loadSaved() async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final resp = await repo.getSavedFoods(
        userId: widget.userId,
        limit: 60,
        sortBy: 'times_logged',
        sortOrder: 'desc',
      );
      if (!mounted) return;
      setState(() {
        _savedFoods = resp.items;
        _loadingSaved = false;
      });
    } catch (e) {
      debugPrint('❌ [Journal] load saved failed: $e');
      if (!mounted) return;
      setState(() => _loadingSaved = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Local yyyy-MM-dd key for a log's day.
  String _dayKey(DateTime dt) {
    final l = dt.isUtc ? dt.toLocal() : dt;
    return DateFormat('yyyy-MM-dd').format(l);
  }

  /// First/most-prominent image for a log (the hero photo).
  String? _heroImage(FoodLog log) =>
      (log.imageUrl != null && log.imageUrl!.isNotEmpty) ? log.imageUrl : null;

  /// Best display name for a log — user query, else joined item names.
  String _logTitle(FoodLog log) {
    final q = log.userQuery;
    if (q != null && q.trim().isNotEmpty) return _cap(q.trim());
    final names = log.foodItems
        .map((e) => e.name)
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (names.isEmpty) return _cap(log.mealType);
    final shown = names.take(3).join(', ');
    final more = names.length - 3;
    return more > 0 ? '$shown +$more' : shown;
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _setView(int v) {
    HapticService.light();
    setState(() => _view = v);
  }

  void _openCoach() {
    HapticService.light();
    context.push(
      '/chat?source=nutrition_journal'
      '&prompt=${Uri.encodeComponent('Looking at my food journal — what patterns do you notice in what I eat and how it makes me feel?')}',
    );
  }

  void _onDayTapped(String dayKey) {
    HapticService.medium();
    setState(() {
      _selectedDayKey = dayKey; // scope the Feed to ONLY this day
      _scrollToDateKey = dayKey; // one-shot highlight of the matching card
      _view = 1; // jump to Feed
    });
  }

  /// CAMERA-FIRST — open the full log flow straight on the camera. After the
  /// sheet closes we refresh logs so a freshly snapped meal lands in the
  /// Calendar + Feed without a manual pull.
  Future<void> _snapMeal() async {
    HapticService.medium();
    await showLogMealSheet(context, ref, autoOpenCamera: true);
    if (!mounted) return;
    await _loadLogs();
  }

  /// Attach a photo to an EXISTING photo-less log. Defaults to the CAMERA but
  /// offers a gallery option via a tiny chooser. Optimistically flips the
  /// card into a loading state, uploads via the repo, then stamps the returned
  /// imageUrl onto the in-memory log so the photo appears INSTANTLY in both the
  /// Feed card and the Calendar day cell (both read the same `_logs`).
  Future<void> _attachPhotoToLog(FoodLog log) async {
    if (log.id.isEmpty) return;
    if (_attachingLogIds.contains(log.id)) return; // already uploading

    final source = await _pickPhotoSource();
    if (source == null || !mounted) return;

    HapticService.medium();
    XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('❌ [Journal] image pick failed: $e');
      if (!mounted) return;
      _showSnack('Could not access the camera or photos. Enable permission and try again.');
      return;
    }
    if (shot == null || !mounted) return; // user cancelled

    final logId = log.id;
    setState(() => _attachingLogIds.add(logId));
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final newUrl = await repo.attachPhotoToFoodLog(
        logId: logId,
        userId: widget.userId,
        image: File(shot.path),
      );
      if (!mounted) return;
      // Optimistic in-place update — replace the log entry with a copy carrying
      // the new imageUrl so Calendar + Feed repaint with the photo immediately.
      setState(() {
        _logs = [
          for (final l in _logs)
            (l.id == logId) ? l.copyWith(imageUrl: newUrl) : l,
        ];
        _attachingLogIds.remove(logId);
      });
      await _writeCache();
      HapticService.success();
    } catch (e) {
      debugPrint('❌ [Journal] attach photo failed: $e');
      if (!mounted) return;
      setState(() => _attachingLogIds.remove(logId));
      _showSnack('Could not attach the photo. Please try again.');
    }
  }

  /// Tiny source chooser — camera first, gallery second. Returns null on cancel.
  Future<ImageSource?> _pickPhotoSource() {
    final tc = ThemeColors.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: tc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: tc.accent),
              title: Text('Take a photo',
                  style: ZType.ser(15, color: tc.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: tc.accent),
              title: Text('Choose from library',
                  style: ZType.ser(15, color: tc.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tc = ThemeColors.of(context);

    if (widget.userId.isEmpty) {
      return Center(
        child: Text(
          'Sign in to see your journal',
          style: ZType.ser(15, color: tc.textMuted),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _JournalHeaderBar(
            view: _view,
            onViewChanged: _setView,
            onAskCoach: _openCoach,
          ),
          // CAMERA-FIRST — prominent "Snap a meal" CTA. The Journal renders
          // only REAL photos, so making capture obvious is how the calendar
          // fills with imagery over time.
          _SnapMealCta(onTap: _snapMeal),
          Expanded(
            child: IndexedStack(
              index: _view,
              children: [
                _buildCalendar(tc),
                _buildFeed(tc),
                _buildMyFoods(tc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar view ──────────────────────────────────────────────────────────

  Widget _buildCalendar(ThemeColors tc) {
    // Bucket logs by day for O(1) cell lookup.
    final byDay = <String, List<FoodLog>>{};
    for (final l in _logs) {
      byDay.putIfAbsent(_dayKey(l.loggedAt), () => []).add(l);
    }

    final bottomPad = MediaQuery.of(context).viewPadding.bottom +
        76 +
        kLiquidGlassActionBarHeight +
        16;

    if (_loadingLogs && _logs.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        children: const [_CalendarSkeleton()],
      );
    }
    if (_logsError && _logs.isEmpty) {
      return _ErrorRetry(message: "Couldn't load your journal", onRetry: () {
        setState(() => _loadingLogs = true);
        _loadLogs();
      });
    }
    if (_logs.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPad),
        children: [_emptyState(tc)],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      children: [
        _MonthNav(
          month: _calMonth,
          onStep: (dir) {
            HapticService.light();
            setState(() => _calMonth =
                DateTime(_calMonth.year, _calMonth.month + dir, 1));
          },
        ),
        const SizedBox(height: 12),
        _MonthGrid(
          month: _calMonth,
          byDay: byDay,
          heroImage: _heroImage,
          dayKey: _dayKey,
          onDayTapped: _onDayTapped,
        ),
      ],
    );
  }

  // ── Feed view ──────────────────────────────────────────────────────────────

  Widget _buildFeed(ThemeColors tc) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom +
        76 +
        kLiquidGlassActionBarHeight +
        16;

    if (_loadingLogs && _logs.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
        children: List.generate(3, (_) => const _FeedCardSkeleton()),
      );
    }

    // Filter the feed. When a Calendar day is selected we scope to ONLY that
    // day (ignoring `_range` entirely) — that is the calendar→feed contract.
    // Otherwise apply the normal range filter.
    final List<FoodLog> filtered;
    if (_selectedDayKey != null) {
      filtered = _logs
          .where((l) => _dayKey(l.loggedAt) == _selectedDayKey)
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    } else {
      final (fromStr, toStr) = _range.params();
      final from = fromStr != null ? DateTime.tryParse(fromStr) : null;
      filtered = _logs.where((l) {
        if (from == null) return true;
        final d = l.loggedAt.isUtc ? l.loggedAt.toLocal() : l.loggedAt;
        return !d.isBefore(DateTime(from.year, from.month, from.day));
      }).toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }

    // Group by day, newest first.
    final groups = <String, List<FoodLog>>{};
    for (final l in filtered) {
      groups.putIfAbsent(_dayKey(l.loggedAt), () => []).add(l);
    }
    final dayKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // Single-day mode shows a dismissible banner in place of the range
        // chips; range mode shows the chips exactly as before.
        if (_selectedDayKey != null)
          _SelectedDayBanner(
            label: _selectedDayLabel(_selectedDayKey!),
            onClear: () {
              HapticService.light();
              setState(() => _selectedDayKey = null);
            },
          )
        else
          _RangeChips(
            range: _range,
            onChanged: (r) {
              HapticService.light();
              setState(() {
                _range = r;
                _selectedDayKey = null; // picking a range exits single-day mode
              });
            },
          ),
        Expanded(
          child: (filtered.isEmpty)
              ? ListView(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPad),
                  children: [_emptyState(tc)],
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
                  itemCount: dayKeys.length,
                  itemBuilder: (ctx, i) {
                    final key = groups[dayKeys[i]]!;
                    final dt = key.first.loggedAt.isUtc
                        ? key.first.loggedAt.toLocal()
                        : key.first.loggedAt;
                    final highlight = _scrollToDateKey == dayKeys[i];
                    // Clear the one-shot highlight after first render.
                    if (highlight) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _scrollToDateKey == dayKeys[i]) {
                          setState(() => _scrollToDateKey = null);
                        }
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          label: _dayHeader(dt),
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                        ),
                        for (final log in key)
                          _FeedCard(
                            log: log,
                            title: _logTitle(log),
                            heroImage: _heroImage(log),
                            tags: log.journalTags,
                            symptoms: log.journalSymptoms,
                            highlight: highlight,
                            attaching: _attachingLogIds.contains(log.id),
                            onAddPhoto: () => _attachPhotoToLog(log),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _dayHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today · ${DateFormat('MMM d').format(dt)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · ${DateFormat('MMM d').format(dt)}';
    }
    return DateFormat('EEE, MMM d').format(dt);
  }

  /// Compact Today/Yesterday/`EEE, MMM d` label for the selected-day banner,
  /// derived from the yyyy-MM-dd `_selectedDayKey` (parsed back to a date).
  String _selectedDayLabel(String dayKey) {
    final parsed = DateTime.tryParse(dayKey);
    if (parsed == null) return dayKey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d == today) return 'Today, ${DateFormat('MMM d').format(parsed)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('MMM d').format(parsed)}';
    }
    return DateFormat('EEE, MMM d').format(parsed);
  }

  // ── My Foods grid ──────────────────────────────────────────────────────────

  Widget _buildMyFoods(ThemeColors tc) => _MyFoodsGrid(
        savedFoods: _savedFoods,
        loading: _loadingSaved,
        emptyTitle: _kEmptyTitles[_emptySeed],
        emptySubtitle: _kEmptySubtitles[_emptySeed],
      );

  // ── Shared empty state ─────────────────────────────────────────────────────

  Widget _emptyState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 48, color: tc.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            _kEmptyTitles[_emptySeed],
            textAlign: TextAlign.center,
            style: ZType.ser(18, color: tc.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _kEmptySubtitles[_emptySeed],
            textAlign: TextAlign.center,
            style: ZType.ser(14, color: tc.textMuted).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Header bar — Calendar/Feed/My Foods toggle + Ask-your-food action
// ═════════════════════════════════════════════════════════════════════════════

class _JournalHeaderBar extends StatelessWidget {
  final int view;
  final ValueChanged<int> onViewChanged;
  final VoidCallback onAskCoach;
  const _JournalHeaderBar({
    required this.view,
    required this.onViewChanged,
    required this.onAskCoach,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: tc.background,
      child: Row(
        children: [
          Expanded(
            child: ZealovaTextTabs(
              tabs: const ['Calendar', 'Feed', 'My Foods'],
              activeIndex: view,
              onChanged: onViewChanged,
            ),
          ),
          const SizedBox(width: 8),
          // "Ask about your food →" — deep-links into the nutrition coach.
          InkWell(
            onTap: onAskCoach,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: tc.accent.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: 13, color: tc.accent),
                  const SizedBox(width: 6),
                  Text('ASK',
                      style: ZType.lbl(10, color: tc.accent, letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Camera-first CTA — prominent "Snap a meal" bar under the header
// ═════════════════════════════════════════════════════════════════════════════

class _SnapMealCta extends StatelessWidget {
  final VoidCallback onTap;
  const _SnapMealCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      color: tc.background,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: tc.accent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_rounded,
                    size: 18, color: tc.accentContrast),
                const SizedBox(width: 10),
                Text(
                  'SNAP A MEAL',
                  style: ZType.lbl(12, color: tc.accentContrast, letterSpacing: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Calendar: month nav + photo-collage grid
// ═════════════════════════════════════════════════════════════════════════════

class _MonthNav extends StatelessWidget {
  final DateTime month;
  final ValueChanged<int> onStep;
  const _MonthNav({required this.month, required this.onStep});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    return Row(
      children: [
        _navArrow(tc, Icons.chevron_left, () => onStep(-1)),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: ZType.lbl(14, color: tc.textPrimary, letterSpacing: 1.5),
            ),
          ),
        ),
        // Don't let the user page into the future past the current month.
        Opacity(
          opacity: isCurrentMonth ? 0.3 : 1,
          child: _navArrow(
            tc,
            Icons.chevron_right,
            isCurrentMonth ? null : () => onStep(1),
          ),
        ),
      ],
    );
  }

  Widget _navArrow(ThemeColors tc, IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 36,
      height: 36,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Icon(icon, color: tc.textMuted, size: 22),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, List<FoodLog>> byDay;
  final String? Function(FoodLog) heroImage;
  final String Function(DateTime) dayKey;
  final void Function(String dayKey) onDayTapped;
  const _MonthGrid({
    required this.month,
    required this.byDay,
    required this.heroImage,
    required this.dayKey,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Monday-first columns.
    const dows = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: Mon=1..Sun=7 → leading blanks before day 1.
    final lead = first.weekday - 1;
    final cells = <Widget?>[];
    for (var i = 0; i < lead; i++) {
      cells.add(null);
    }
    final fmt = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = fmt.format(date);
      final logs = byDay[key] ?? const [];
      String? hero;
      for (final l in logs) {
        final img = heroImage(l);
        if (img != null) {
          hero = img;
          break;
        }
      }
      final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
      cells.add(_DayCell(
        day: day,
        hero: hero,
        hasLogs: logs.isNotEmpty,
        isToday: date.year == today.year &&
            date.month == today.month &&
            date.day == today.day,
        isFuture: isFuture,
        onTap: logs.isNotEmpty ? () => onDayTapped(key) : null,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final d in dows)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: ZType.lbl(11,
                          color: tc.textMuted, letterSpacing: 1)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: [
            for (final c in cells) c ?? const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String? hero;
  final bool hasLogs;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;
  const _DayCell({
    required this.day,
    required this.hero,
    required this.hasLogs,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final border = isToday
        ? Border.all(color: tc.accent, width: 1.5)
        : Border.all(color: AppColors.cardBorder);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(10),
            border: border,
            image: hero != null
                ? DecorationImage(
                    image: NetworkImage(hero!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.28),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              // No-photo, has-logs marker: a tasteful icon tile.
              if (hero == null && hasLogs)
                Center(
                  child: Icon(Icons.restaurant_outlined,
                      size: 16, color: tc.accent.withValues(alpha: 0.7)),
                ),
              // Date number overlay (top-left).
              Positioned(
                left: 5,
                top: 4,
                child: Text(
                  '$day',
                  style: ZType.data(
                    11,
                    color: hero != null
                        ? Colors.white
                        : (isFuture
                            ? tc.textMuted.withValues(alpha: 0.4)
                            : tc.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SkeletonBox(width: 140, height: 18)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          children: List.generate(
            35,
            (_) => const SkeletonBox(width: 40, height: 40, radius: 10),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Feed: range chips + scrapbook cards
// ═════════════════════════════════════════════════════════════════════════════

class _RangeChips extends StatelessWidget {
  final _JournalRange range;
  final ValueChanged<_JournalRange> onChanged;
  const _RangeChips({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (final r in _JournalRange.values) ...[
            ZealovaChip(
              label: r.label,
              selected: r == range,
              onTap: () => onChanged(r),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Single-day scope banner shown atop the Feed when a Calendar day is tapped.
/// Reads "Showing [day]" with a tappable ✕ / "Show all" affordance that
/// returns the Feed to the normal range view.
class _SelectedDayBanner extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _SelectedDayBanner({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: tc.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tc.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 14, color: tc.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing $label',
                style: ZType.lbl(11, color: tc.accent, letterSpacing: 0.8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('SHOW ALL',
                        style: ZType.lbl(10,
                            color: tc.accent, letterSpacing: 1.2)),
                    const SizedBox(width: 4),
                    Icon(Icons.close, size: 13, color: tc.accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FoodLog log;
  final String title;
  final String? heroImage;
  final List<String> tags;
  final List<String> symptoms;
  final bool highlight;
  final bool attaching;
  final VoidCallback onAddPhoto;
  const _FeedCard({
    required this.log,
    required this.title,
    required this.heroImage,
    required this.tags,
    required this.symptoms,
    required this.highlight,
    required this.attaching,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final loggedLocal =
        log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
    final timeStr = DateFormat('h:mm a').format(loggedLocal);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? tc.accent : AppColors.cardBorder,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero photo (full-width) or "add a photo" affordance ──
          if (heroImage != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  heroImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _AddPhotoBanner(
                    tc: tc,
                    compact: false,
                    loading: attaching,
                    onTap: onAddPhoto,
                  ),
                ),
              ),
            )
          else
            _AddPhotoBanner(
              tc: tc,
              compact: false,
              loading: attaching,
              onTap: onAddPhoto,
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + score.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: ZType.ser(16, color: tc.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (log.healthScore != null) ...[
                      const SizedBox(width: 8),
                      _ScorePill(score: log.healthScore!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Time + meal type telemetry.
                Text(
                  '${_cap(log.mealType)} · $timeStr',
                  style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1),
                ),
                // Notes as a quote.
                if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: tc.accent, width: 2),
                      ),
                    ),
                    child: Text(
                      '"${log.notes!.trim()}"',
                      style: ZType.ser(14, color: tc.textSecondary)
                          .copyWith(height: 1.4, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                // Chip row: mood, energy, tags, symptoms.
                if (_hasChips) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (log.moodAfter != null &&
                          log.moodAfter!.trim().isNotEmpty)
                        _MetaChip(
                          icon: Icons.sentiment_satisfied_outlined,
                          label: log.moodAfter!,
                          color: tc.accent,
                        ),
                      if (log.energyLevel != null)
                        _MetaChip(
                          icon: Icons.bolt_outlined,
                          label: 'Energy ${log.energyLevel}',
                          color: AppColors.limeGreen,
                        ),
                      for (final t in tags)
                        _MetaChip(
                          icon: Icons.sell_outlined,
                          label: t,
                          color: tc.textMuted,
                        ),
                      for (final s in symptoms)
                        _MetaChip(
                          icon: Icons.monitor_heart_outlined,
                          label: s,
                          color: AppColors.macroFat,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasChips =>
      (log.moodAfter != null && log.moodAfter!.trim().isNotEmpty) ||
      log.energyLevel != null ||
      tags.isNotEmpty ||
      symptoms.isNotEmpty;

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Gentle "add a photo" affordance for photo-less entries (image-first
/// principle — the journal should always fill in visually).
class _AddPhotoBanner extends StatelessWidget {
  final ThemeColors tc;
  final bool compact;
  final bool loading;
  final VoidCallback? onTap;
  const _AddPhotoBanner({
    required this.tc,
    required this.compact,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Material(
        color: tc.elevated,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: SizedBox(
            height: compact ? 64 : 120,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: compact ? 20 : 24,
                    height: compact ? 20 : 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                    ),
                  )
                else
                  Icon(Icons.add_a_photo_outlined,
                      size: compact ? 22 : 28, color: tc.accent),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  Text(
                    loading ? 'Adding photo…' : 'Add a photo',
                    style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label.toUpperCase(),
              style: ZType.lbl(10, color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  Color _scoreColor() {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.macroCarbs;
    if (score >= 40) return AppColors.macroFat;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final c = _scoreColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text('$score',
          style: ZType.data(12, color: c, weight: FontWeight.w700)),
    );
  }
}

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 120, height: 14),
          SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: SkeletonBox(width: double.infinity, height: 200, radius: 14),
          ),
          SizedBox(height: 12),
          SkeletonBox(width: 180, height: 14),
          SizedBox(height: 8),
          SkeletonBox(width: 120, height: 11),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// My Foods: searchable + tag-filterable photo grid (the collectible album)
// ═════════════════════════════════════════════════════════════════════════════

class _MyFoodsGrid extends StatefulWidget {
  final List<SavedFood> savedFoods;
  final bool loading;
  final String emptyTitle;
  final String emptySubtitle;
  const _MyFoodsGrid({
    required this.savedFoods,
    required this.loading,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  State<_MyFoodsGrid> createState() => _MyFoodsGridState();
}

class _MyFoodsGridState extends State<_MyFoodsGrid> {
  String _query = '';
  String? _tagFilter;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _allTags {
    final set = <String>{};
    for (final f in widget.savedFoods) {
      for (final t in (f.tags ?? const <String>[])) {
        if (t.trim().isNotEmpty) set.add(t);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<SavedFood> get _filtered {
    return widget.savedFoods.where((f) {
      if (_query.isNotEmpty &&
          !f.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_tagFilter != null && !(f.tags ?? const []).contains(_tagFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom +
        76 +
        kLiquidGlassActionBarHeight +
        16;

    if (widget.loading && widget.savedFoods.isEmpty) {
      return GridView.count(
        crossAxisCount: 3,
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: List.generate(
          9,
          (_) => const SkeletonBox(width: 100, height: 100, radius: 14),
        ),
      );
    }

    if (widget.savedFoods.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 40, 16, bottomPad),
        children: [
          Column(
            children: [
              Icon(Icons.bookmark_border,
                  size: 48, color: tc.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(widget.emptyTitle,
                  textAlign: TextAlign.center,
                  style: ZType.ser(18, color: tc.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Foods you save and re-log build your personal album here.',
                textAlign: TextAlign.center,
                style: ZType.ser(14, color: tc.textMuted).copyWith(height: 1.4),
              ),
            ],
          ),
        ],
      );
    }

    final tags = _allTags;
    final filtered = _filtered;

    return Column(
      children: [
        // Search field.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              style: ZType.ser(14, color: tc.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search your foods',
                hintStyle: ZType.ser(14, color: tc.textMuted),
                prefixIcon: Icon(Icons.search, size: 18, color: tc.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16, color: tc.textMuted),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ),
        // Tag filter row.
        if (tags.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                ZealovaChip(
                  label: 'All',
                  selected: _tagFilter == null,
                  onTap: () => setState(() => _tagFilter = null),
                ),
                const SizedBox(width: 8),
                for (final t in tags) ...[
                  ZealovaChip(
                    label: t,
                    selected: _tagFilter == t,
                    onTap: () => setState(
                        () => _tagFilter = _tagFilter == t ? null : t),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No foods match.',
                    style: ZType.ser(14, color: tc.textMuted),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 3,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    for (final f in filtered) _SavedFoodTile(food: f),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SavedFoodTile extends StatelessWidget {
  final SavedFood food;
  const _SavedFoodTile({required this.food});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(food.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.35),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            if (!hasImage)
              Center(
                child: Icon(Icons.restaurant_outlined,
                    size: 26, color: tc.textMuted.withValues(alpha: 0.6)),
              ),
            // Name overlay at the bottom.
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ZType.lbl(
                  10,
                  color: hasImage ? Colors.white : tc.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (food.timesLogged > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${food.timesLogged}×',
                      style: ZType.data(9, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared: error retry + (kept import warm) full-search link to FoodHistoryScreen
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: tc.textMuted),
          const SizedBox(height: 12),
          Text(message, style: ZType.ser(15, color: tc.textPrimary)),
          const SizedBox(height: 12),
          ZealovaButton(label: 'Retry', onTap: onRetry, expand: false),
        ],
      ),
    );
  }
}

/// Reachable full-search entry point so users can jump to the legacy
/// [FoodHistoryScreen] (search + advanced filters) from the Journal. Wired by
/// the header "ASK" affordance's sibling — kept here so the import is load-
/// bearing and the consolidation (Patterns drops its History section) does not
/// strand the search surface.
void openFullFoodSearch(BuildContext context, String userId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FoodHistoryScreen(userId: userId),
    ),
  );
}
