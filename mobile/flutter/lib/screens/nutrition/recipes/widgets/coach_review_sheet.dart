/// AI nutrition-pro review sheet — shared by recipe detail and meal planner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/coach_review.dart';
import '../../../../data/repositories/recipe_repository.dart';

class CoachReviewSheet extends ConsumerStatefulWidget {
  final CoachReviewSubject subjectType;
  final String subjectId;
  final String userId;
  final bool isDark;
  const CoachReviewSheet({
    super.key,
    required this.subjectType,
    required this.subjectId,
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<CoachReviewSheet> createState() => _CoachReviewSheetState();
}

class _CoachReviewSheetState extends ConsumerState<CoachReviewSheet> {
  CoachReview? _review;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(recipeRepositoryProvider);
      CoachReview? r;
      if (!fresh) {
        r = await repo.latestReview(widget.subjectType, widget.subjectId);
      }
      r ??= widget.subjectType == CoachReviewSubject.recipe
          ? await repo.reviewRecipe(widget.userId, widget.subjectId)
          : await repo.reviewMealPlan(widget.userId, widget.subjectId);
      if (mounted) setState(() { _review = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.psychology_outlined, color: accent),
              const SizedBox(width: 8),
              Text('Coach review', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(fresh: true)),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: muted)))
                      : _review == null
                          ? Center(child: Text('No review yet — tap refresh to generate', style: TextStyle(color: muted)))
                          : ListView(controller: controller, children: _buildReview(_review!, accent, text, muted)),
            ),
            OutlinedButton(
              onPressed: _review == null ? null : () async {
                try {
                  await ref.read(recipeRepositoryProvider).requestHumanProReview(_review!.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('We\'ll notify you when human reviewers launch')),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('Request human pro review'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReview(CoachReview r, Color accent, Color text, Color muted) {
    final score = r.overallScore ?? 0;
    final scoreColor = score >= 75 ? AppColors.success : score >= 50 ? AppColors.yellow : AppColors.error;
    return [
      // Score donut + status
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 64, height: 64, child: CircularProgressIndicator(
              value: score / 100, strokeWidth: 6, color: scoreColor,
              backgroundColor: scoreColor.withValues(alpha: 0.18),
            )),
            Text('$score', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Overall score', style: TextStyle(color: muted, fontSize: 11)),
              if (r.isStale)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Out of date', style: TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Allergen flags (red banner if present)
      if (r.allergenFlags.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text('Allergen alert: ${r.allergenFlags.join(", ")}',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
          ]),
        ),
      const SizedBox(height: 16),
      if (r.macroBalanceNotes != null) ...[
        Text('Macro balance', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(r.macroBalanceNotes!, style: TextStyle(color: muted, height: 1.4)),
        const SizedBox(height: 16),
      ],
      if (r.micronutrientGaps.isNotEmpty) ...[
        Text('Micronutrient gaps', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ...r.micronutrientGaps.map((g) => ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: AppColors.yellow.withValues(alpha: 0.2),
            child: Text('${g.deficitPct}%', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          ),
          title: Text(g.nutrient, style: TextStyle(color: text)),
          subtitle: g.suggestion != null ? Text(g.suggestion!) : null,
        )),
        const SizedBox(height: 16),
      ],
      if (r.swapSuggestions.isNotEmpty) ...[
        Text('Suggested swaps', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...r.swapSuggestions.map((s) => Card(
          child: ListTile(
            title: Text('${s.targetLabel} → ${s.suggestedLabel}'),
            subtitle: Text(s.rationale),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apply swap — coming with planner integration')));
              },
              child: const Text('Apply'),
            ),
          ),
        )),
        const SizedBox(height: 16),
      ],
      if (r.fullFeedback != null) ...[
        Text('Full feedback', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(r.fullFeedback!, style: TextStyle(color: muted, height: 1.5)),
      ],
    ];
  }
}
