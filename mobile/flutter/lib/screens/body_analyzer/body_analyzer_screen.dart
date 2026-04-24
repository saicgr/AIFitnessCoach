import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/body_analyzer.dart';
import '../../data/repositories/body_analyzer_repository.dart';
import 'body_analyzer_capture_screen.dart';
import 'widgets/body_age_badge.dart';
import 'widgets/body_analyzer_hero.dart';
import 'widgets/posture_findings_card.dart';
import 'widgets/retune_proposal_sheet.dart';
import 'widgets/score_ring.dart';
import 'widgets/share_body_analyzer_sheet.dart';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final results = await Future.wait([
        repo.latestSnapshot(),
        repo.listSnapshots(limit: 30),
        repo.bodyAge(),
      ]);
      if (!mounted) return;
      setState(() {
        _latest = results[0] as BodyAnalyzerSnapshot?;
        _history = results[1] as List<BodyAnalyzerSnapshot>;
        _bodyAge = results[2] as BodyAgeResult;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RetuneProposalSheet(proposal: proposal),
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
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.nearBlack
          : AppColorsLight.nearWhite,
      builder: (_) => ShareBodyAnalyzerSheet(snapshot: snap),
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
        title: const Text('Body Analyzer'),
        actions: [
          if (_latest != null)
            IconButton(
              tooltip: 'Share',
              onPressed: () => _share(_latest!),
              icon: const Icon(Icons.ios_share),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(textMuted)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_latest == null)
                          _buildEmptyState(textPrimary, textMuted)
                        else
                          _buildLatest(_latest!, textPrimary, textMuted, isDark),
                        if (_history.length > 1) ...[
                          const SizedBox(height: 24),
                          Text(
                            'History',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runNewAnalysis,
        backgroundColor: const Color(0xFFB24BF3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('New analysis'),
      ),
    );
  }

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
              TextButton(onPressed: _load, child: const Text('Retry')),
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
              'Get your Body Analyzer feedback',
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
              label: const Text('Start analysis'),
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
                label: 'Body Fat',
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
                label: 'Muscle Mass',
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
                label: 'Symmetry',
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
                  'Personalized tips',
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _creatingProposal ? null : () => _retuneProgram(snap),
            icon: _creatingProposal
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(
                _creatingProposal ? 'Creating proposal…' : 'Retune my program'),
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
