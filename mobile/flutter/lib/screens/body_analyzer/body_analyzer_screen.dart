import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/body_analyzer.dart';
import '../../data/repositories/body_analyzer_repository.dart';
import 'body_analyzer_capture_screen.dart';
import '../../data/repositories/slideshow_repository.dart';
import '../shareables/transformation_video_screen.dart';
import 'widgets/body_age_badge.dart';
import 'widgets/body_analyzer_hero.dart';
import 'widgets/posture_findings_card.dart';
import 'widgets/retune_proposal_sheet.dart';
import 'widgets/score_ring.dart';
import 'widgets/share_body_analyzer_sheet.dart';
import '../../widgets/glass_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
class BodyAnalyzerScreen extends ConsumerStatefulWidget {
  const BodyAnalyzerScreen({super.key});

  @override
  ConsumerState<BodyAnalyzerScreen> createState() => _BodyAnalyzerScreenState();
}

class _BodyAnalyzerScreenState extends ConsumerState<BodyAnalyzerScreen> {
  BodyAnalyzerSnapshot? _latest;
  List<BodyAnalyzerSnapshot> _history = [];
  BodyAgeResult? _bodyAge;
  bool _loading = true;
  bool _applyingCorrectives = false;
  bool _creatingProposal = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Disk-cache key. Versioned so a payload-shape change drops stale blobs.
  /// Not user-scoped here: the Body Analyzer repository is auth-scoped
  /// server-side and the cache is wiped on logout via SharedPreferences
  /// clear, but we still TTL-bound it to 24 h so it can't go badly stale.
  static const String _diskCacheKey = 'body_analyzer_overview::v1';
  static const Duration _diskTtl = Duration(hours: 24);

  /// Read the persisted overview (latest + history + body age). Returns null
  /// on miss / expiry / corruption. Best-effort — never throws.
  Future<Map<String, dynamic>?> _readDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diskCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final cachedAt = decoded['cachedAt'];
      if (cachedAt is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age < 0 || age >= _diskTtl.inMilliseconds) {
        await prefs.remove(_diskCacheKey);
        return null;
      }
      final data = decoded['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('💾 [BodyAnalyzer] disk read failed: $e');
      return null;
    }
  }

  /// Write-through the freshly fetched overview. Best-effort.
  Future<void> _writeDiskCache(
    BodyAnalyzerSnapshot? latest,
    List<BodyAnalyzerSnapshot> history,
    BodyAgeResult? bodyAge,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _diskCacheKey,
        jsonEncode({
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'data': {
            'latest': latest?.toJson(),
            'history': history.map((s) => s.toJson()).toList(),
            // BodyAgeResult has no toJson — persist its three ints by hand.
            'bodyAge': bodyAge == null
                ? null
                : {
                    'body_age': bodyAge.bodyAge,
                    'chronological_age': bodyAge.chronologicalAge,
                    'delta': bodyAge.delta,
                  },
          },
        }),
      );
    } catch (e) {
      debugPrint('💾 [BodyAnalyzer] disk write failed: $e');
    }
  }

  /// Load the Body Analyzer overview cache-first (disk SWR).
  ///
  /// Step 1: read the disk cache — if a valid blob exists, paint it
  /// immediately with `_loading:false` so a cold start renders instantly
  /// (skeleton stays hidden). Step 2: fetch fresh from the network and
  /// overwrite. On a disk miss we keep `_loading:true` so the screen shows
  /// its layout-matched skeleton until first content arrives.
  Future<void> _load() async {
    var servedFromCache = false;
    final cached = await _readDiskCache();
    if (cached != null && mounted) {
      try {
        final latestJson = cached['latest'] as Map<String, dynamic>?;
        final historyJson = (cached['history'] as List?) ?? const [];
        final bodyAgeJson = cached['bodyAge'] as Map<String, dynamic>?;
        servedFromCache = true;
        setState(() {
          _latest = latestJson == null
              ? null
              : BodyAnalyzerSnapshot.fromJson(latestJson);
          _history = historyJson
              .map((j) =>
                  BodyAnalyzerSnapshot.fromJson(j as Map<String, dynamic>))
              .toList();
          _bodyAge =
              bodyAgeJson == null ? null : BodyAgeResult.fromJson(bodyAgeJson);
          _loading = false;
          _error = null;
        });
      } catch (e) {
        debugPrint('💾 [BodyAnalyzer] disk decode failed: $e');
        servedFromCache = false;
      }
    }
    if (!servedFromCache) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final results = await Future.wait([
        repo.latestSnapshot(),
        repo.listSnapshots(limit: 30),
        repo.bodyAge(),
      ]);
      if (!mounted) return;
      final latest = results[0] as BodyAnalyzerSnapshot?;
      final history = results[1] as List<BodyAnalyzerSnapshot>;
      final bodyAge = results[2] as BodyAgeResult;
      setState(() {
        _latest = latest;
        _history = history;
        _bodyAge = bodyAge;
        _loading = false;
      });
      // Write-through so the next cold start is instant.
      await _writeDiskCache(latest, history, bodyAge);
    } catch (e) {
      // Keep any cached overview on screen; only surface the error if we
      // have nothing else to show.
      if (mounted) {
        setState(() {
          if (!servedFromCache) _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _runNewAnalysis() async {
    final result = await Navigator.of(context).push<BodyAnalyzerSnapshot>(
      MaterialPageRoute(builder: (_) => const BodyAnalyzerCaptureScreen()),
    );
    if (result != null) _load();
  }

  Future<void> _applyCorrectives(BodyAnalyzerSnapshot snap) async {
    setState(() => _applyingCorrectives = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final res = await repo.applyPostureCorrectives(
        bodyAnalyzerSnapshotId: snap.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${res.exercisesAdded.length} corrective exercises queued for the next program',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _applyingCorrectives = false);
    }
  }

  Future<void> _retuneProgram(BodyAnalyzerSnapshot snap) async {
    setState(() => _creatingProposal = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final proposal =
          await repo.createRetuneProposal(bodyAnalyzerSnapshotId: snap.id);
      if (!mounted) return;
      await showGlassSheet<void>(
        context: context,
        builder: (_) => GlassSheet(child: RetuneProposalSheet(proposal: proposal)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retune failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingProposal = false);
    }
  }

  void _share(BodyAnalyzerSnapshot snap) {
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(child: ShareBodyAnalyzerSheet(snapshot: snap)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppLocalizations.of(context).commonBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(AppLocalizations.of(context).progressScreenUiBodyAnalyzer),
        actions: [
          IconButton(
            tooltip: 'Transformation video',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransformationVideoScreen(
                  source: SlideshowSource.progressPhotos,
                ),
              ),
            ),
            icon: const Icon(Icons.movie_creation_outlined),
          ),
          if (_latest != null)
            IconButton(
              tooltip: AppLocalizations.of(context).commonShare,
              onPressed: () => _share(_latest!),
              icon: const Icon(Icons.ios_share),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildSkeleton()
            : _error != null
                ? _buildError(textMuted)
                : AppRefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                          16, 16, 16, _latest != null ? 24 : 16),
                      children: [
                        if (_latest == null)
                          _buildEmptyState(textPrimary, textMuted)
                        else
                          _buildLatest(_latest!, textPrimary, textMuted, isDark),
                        if (_history.length > 1) ...[
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.of(context).workoutHistory,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._history.skip(1).map(
                            (s) => _historyTile(s, textPrimary, textMuted, isDark),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar:
          (_latest != null && !_loading) ? _buildActionBar(isDark) : null,
    );
  }

  /// Cold-start skeleton — layout-matches `_buildLatest`: a hero score card,
  /// a row of three composition rings, and two stacked text cards. Only ever
  /// shown on a genuine first-ever open (no disk cache); returning users
  /// rehydrate the real overview instantly from the disk SWR layer.
  Widget _buildSkeleton() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: const [
          // Hero score card.
          SkeletonBox(height: 150, radius: 18),
          SizedBox(height: 12),
          // Body-type chip + body-age badge row.
          SkeletonBox(height: 34, radius: 10),
          SizedBox(height: 16),
          // Three composition rings.
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 120, radius: 14)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 120, radius: 14)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 120, radius: 14)),
            ],
          ),
          SizedBox(height: 16),
          // Feedback + tips cards.
          SkeletonBox(height: 90, radius: 14),
          SizedBox(height: 12),
          SkeletonBox(height: 110, radius: 14),
        ],
      );

  Widget _buildError(Color textMuted) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text('Couldn\'t load Body Analyzer: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMuted)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: Text(AppLocalizations.of(context).buttonRetry)),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(Color textPrimary, Color textMuted) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.assessment_outlined, size: 64, color: Color(0xFFB24BF3)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).bodyAnalyzerGetYourBodyAnalyzer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Upload 1–4 progress photos (front, back, side). Gemini Vision '
                'fuses them with your latest measurements for a detailed '
                '/100 rating, composition rings, and personalized program '
                'retune suggestions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _runNewAnalysis,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(AppLocalizations.of(context).bodyAnalyzerStartAnalysis),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB24BF3),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );

  Widget _buildLatest(
    BodyAnalyzerSnapshot snap,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final bodyAge = _bodyAge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BodyAnalyzerHero(
          score: snap.overallRating ?? 0,
          trendText: _trendTextFor(snap),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (snap.bodyType != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB24BF3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  snap.bodyType![0].toUpperCase() + snap.bodyType!.substring(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB24BF3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (bodyAge != null)
              Expanded(
                child: BodyAgeBadge(
                  bodyAge: bodyAge.bodyAge,
                  chronologicalAge: bodyAge.chronologicalAge,
                  isDark: isDark,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ScoreRing(
                label: AppLocalizations.of(context).shareBodyAnalyzerBodyFat,
                value:
                    '${(snap.bodyFatPercent ?? 0).toStringAsFixed(0)}%',
                fill: ((snap.bodyFatPercent ?? 0) / 40).clamp(0.0, 1.0),
                color: const Color(0xFF3498DB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreRing(
                label: AppLocalizations.of(context).shareBodyAnalyzerMuscleMass,
                value:
                    '${(snap.muscleMassPercent ?? 0).toStringAsFixed(0)}%',
                fill: ((snap.muscleMassPercent ?? 0) / 60).clamp(0.0, 1.0),
                color: const Color(0xFFF5A623),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ScoreRing(
                label: AppLocalizations.of(context).shareBodyAnalyzerSymmetry,
                value: '${((snap.symmetryScore ?? 0) / 10).round()}/10',
                fill: ((snap.symmetryScore ?? 0) / 100).clamp(0.0, 1.0),
                color: const Color(0xFFB24BF3),
                isDark: isDark,
              ),
            ),
          ],
        ),
        if (snap.feedbackText != null && snap.feedbackText!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.elevated
                  : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              snap.feedbackText!,
              style: TextStyle(
                  fontSize: 13, color: textPrimary, height: 1.5),
            ),
          ),
        ],
        if (snap.improvementTips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.elevated
                  : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).bodyAnalyzerPersonalizedTips,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...snap.improvementTips.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right_rounded,
                              size: 18, color: Color(0xFF2ECC71)),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        PostureFindingsCard(
          findings: snap.postureFindings,
          isDark: isDark,
          onApplyCorrectives: snap.postureFindings.isEmpty
              ? null
              : () => _applyCorrectives(snap),
          isApplying: _applyingCorrectives,
        ),
      ],
    );
  }

  Widget _buildActionBar(bool isDark) {
    final snap = _latest!;
    final barBg = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _runNewAnalysis,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(AppLocalizations.of(context).bodyAnalyzerNewAnalysis),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB24BF3),
                  side: const BorderSide(color: Color(0xFFB24BF3), width: 1.4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _creatingProposal ? null : () => _retuneProgram(snap),
                  icon: _creatingProposal
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_creatingProposal
                      ? AppLocalizations.of(context).bodyAnalyzerCreatingProposal
                      : 'Retune my program'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB24BF3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _trendTextFor(BodyAnalyzerSnapshot latest) {
    if (_history.length < 2) return null;
    final prev = _history[1];
    final cur = latest.overallRating;
    final p = prev.overallRating;
    if (cur == null || p == null) return null;
    final diff = cur - p;
    if (diff == 0) return 'Holding steady';
    final arrow = diff > 0 ? '↑' : '↓';
    return '$arrow ${diff.abs()} pts vs last analysis';
  }

  Widget _historyTile(
    BodyAnalyzerSnapshot snap,
    Color primary,
    Color muted,
    bool isDark,
  ) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFB24BF3).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${snap.overallRating ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB24BF3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _prettyDate(snap.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BF ${(snap.bodyFatPercent ?? 0).toStringAsFixed(0)}%  ·  '
                    'MM ${(snap.muscleMassPercent ?? 0).toStringAsFixed(0)}%  ·  '
                    'Sym ${((snap.symmetryScore ?? 0) / 10).round()}/10',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _prettyDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
