import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
/// Phase 6 #16 — Lifetime training journal.
///
/// Unified searchable timeline across workouts + meals + progress photos + PRs.
/// The retention play: power users prove correlations to themselves ("my bench
/// plateaued every week I averaged <6h sleep"). Reads `GET /api/v1/journal`,
/// which aggregates existing sources (workout_logs, food_log, progress_photos).
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _searchCtl = TextEditingController();
  List<dynamic> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final q = _searchCtl.text.trim();
      final resp = await api.get(
        '/journal',
        queryParameters: q.isEmpty ? null : {'q': q},
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        setState(() {
          _items = (resp.data['items'] as List?) ?? const [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'HTTP ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(title: AppLocalizations.of(context).journalTitle),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtl,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).journalSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _load,
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorView(_error!, textSecondary)
                      : _items.isEmpty
                          ? _emptyView(textPrimary, textSecondary)
                          : AppRefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final raw = _items[i] as Map?;
                                  if (raw == null) return const SizedBox.shrink();
                                  return _JournalRow(
                                    data: Map<String, dynamic>.from(raw),
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 56, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).journalYourJournalIsEmpty,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).journalLogAWorkoutMeal,
              style: TextStyle(fontSize: 13, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String e, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: textSecondary),
            const SizedBox(height: 8),
            Text(e,
                style: TextStyle(color: textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).buttonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.data,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Map<String, dynamic> data;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final kind = (data['kind'] ?? '').toString();
    final at = (data['at'] ?? '').toString();
    final summary = (data['summary'] ?? '').toString();
    final icon = switch (kind) {
      'workout' => Icons.fitness_center_rounded,
      'meal' => Icons.restaurant_rounded,
      'photo' => Icons.image_rounded,
      _ => Icons.bookmark_rounded,
    };
    final color = switch (kind) {
      'workout' => const Color(0xFF22C55E),
      'meal' => const Color(0xFFF59E0B),
      'photo' => const Color(0xFF8B5CF6),
      _ => textSecondary,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtAt(at),
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
