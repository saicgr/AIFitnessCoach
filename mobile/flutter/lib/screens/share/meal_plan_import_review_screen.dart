/// MealPlanImportReviewScreen — editable surface for a Gemini-extracted
/// multi-day meal plan (e.g. ChatGPT "Day 1 — breakfast: oatmeal …").
///
/// Pass-through v1: shows the days + meals from the extraction in a
/// read-only review, then routes the user to either the AI Coach chat
/// (with the structured plan as context) or saves a personal note. A
/// full first-class meal-plan persistence surface is a follow-up slice.
library meal_plan_import_review_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealPlanImportReviewScreen extends ConsumerWidget {
  const MealPlanImportReviewScreen({
    super.key,
    required this.sharedItemId,
    required this.initialPayload,
  });

  final String sharedItemId;
  final Map<String, dynamic> initialPayload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final days = _extractDays(initialPayload);
    return Scaffold(
      appBar: AppBar(title: const Text('Meal plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          if ((initialPayload['title'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                initialPayload['title'] as String,
                style: theme.textTheme.titleLarge,
              ),
            ),
          Text(
            'We pulled this meal plan out of the share. Tap a day to send it '
            'to your AI Coach for a real schedule.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          for (final d in days) ...[
            Text(d.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final meal in d.meals)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: theme.textTheme.bodyMedium),
                    Expanded(child: Text(meal, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    // Hand off the plan text to the AI Coach so the user
                    // can iterate ("turn this into a 1900-kcal version").
                    Navigator.of(context).pop('chat_with_plan');
                  },
                  child: const Text('Send to Coach'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Best-effort parse — accepts either a structured {days:[{title,meals[]}]}
  // payload from a future extractor, or falls back to splitting the raw
  // body into "Day 1: …" sections.
  List<_PlanDay> _extractDays(Map<String, dynamic> payload) {
    final structured = payload['days'];
    if (structured is List) {
      return [
        for (final d in structured.whereType<Map>())
          _PlanDay(
            title: (d['title'] as String?) ?? 'Day',
            meals: ((d['meals'] as List?) ?? const [])
                .map((m) => m.toString())
                .toList(),
          ),
      ];
    }
    final body = (payload['body'] ?? payload['transcript_preview'] ?? payload['text_preview']) as String?;
    if (body == null || body.isEmpty) return const [];
    final out = <_PlanDay>[];
    _PlanDay? current;
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final dayMatch = RegExp(r'^(Day\s*\d+|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
              caseSensitive: false)
          .firstMatch(line);
      if (dayMatch != null) {
        if (current != null) out.add(current);
        current = _PlanDay(title: line.split(':').first.trim(), meals: []);
        continue;
      }
      current ??= _PlanDay(title: 'Day 1', meals: []);
      if (line.startsWith('-') || line.startsWith('•') || RegExp(r'^\d+[.)]').hasMatch(line)) {
        current.meals.add(line.replaceFirst(RegExp(r'^[-•\d.)\s]+'), ''));
      } else if (current.meals.isNotEmpty || line.contains(':')) {
        current.meals.add(line);
      }
    }
    if (current != null) out.add(current);
    return out;
  }
}

class _PlanDay {
  _PlanDay({required this.title, required this.meals});
  final String title;
  final List<String> meals;
}
