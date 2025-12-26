import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/personal_goals_service.dart';
import '../../../../data/services/haptic_service.dart';

/// A card displaying weekly personal goals summary on the home screen
class WeeklyGoalsCard extends ConsumerStatefulWidget {
  final bool isDark;

  const WeeklyGoalsCard({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<WeeklyGoalsCard> createState() => _WeeklyGoalsCardState();
}

class _WeeklyGoalsCardState extends ConsumerState<WeeklyGoalsCard> {
  late PersonalGoalsService _goalsService;
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final apiClient = ref.read(apiClientProvider);
    _goalsService = PersonalGoalsService(apiClient);
    final userId = await apiClient.getUserId();

    if (userId != null) {
      _loadSummary(userId);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSummary(String userId) async {
    try {
      final summary = await _goalsService.getSummary(userId: userId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [WeeklyGoalsCard] Failed to load summary: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevatedColor =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final activeGoals = _summary?['active_goals'] ?? 0;
    final prsThisWeek = _summary?['prs_this_week'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/personal-goals');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeGoals > 0
                    ? AppColors.cyan.withValues(alpha: 0.3)
                    : cardBorder,
              ),
            ),
            child: activeGoals > 0
                ? _buildActiveGoalsContent(
                    activeGoals,
                    prsThisWeek,
                    textPrimary,
                    textSecondary,
                    textMuted,
                  )
                : _buildEmptyState(textSecondary, textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveGoalsContent(
    int activeGoals,
    int prsThisWeek,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Row(
      children: [
        // Goal icon with badge
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flag,
                color: AppColors.cyan,
                size: 24,
              ),
            ),
            if (prsThisWeek > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$prsThisWeek',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$activeGoals active ${activeGoals == 1 ? 'goal' : 'goals'}${prsThisWeek > 0 ? ' • $prsThisWeek new PR${prsThisWeek == 1 ? '' : 's'}!' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: prsThisWeek > 0 ? AppColors.orange : textSecondary,
                  fontWeight: prsThisWeek > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        // Arrow
        Icon(
          Icons.chevron_right,
          color: textMuted,
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textSecondary, Color textMuted) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            color: AppColors.purple.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set a challenge to push your limits!',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.add_circle_outline,
          color: AppColors.purple.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
