import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/providers/beast_mode_provider.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/glass_back_button.dart';
import 'beast_mode_constants.dart';
import 'widgets/about_section.dart';
import 'widgets/beast_header_card.dart';
import 'widgets/data_sync_section.dart';
import 'widgets/difficulty_card.dart';
import 'widgets/freshness_decay_card.dart';
import 'widgets/mood_card.dart';
import 'widgets/recovery_section.dart';
import 'widgets/rest_timer_card.dart';
import 'widgets/rpe_card.dart';
import 'widgets/scoring_card.dart';
import 'widgets/custom_color_lab_card.dart';
import 'widgets/font_scale_card.dart';
import 'widgets/rep_progression_card.dart';
import 'widgets/superset_algorithm_card.dart';
import 'widgets/template_section.dart';
import 'widgets/volume_progression_card.dart';
import 'widgets/warmup_cooldown_card.dart';
import 'widgets/weight_increments_card.dart';

class BeastModeScreen extends ConsumerWidget {
  const BeastModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = BeastThemeData.of(context);
    final backgroundColor =
        t.isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final isPremium = ref.watch(
      subscriptionProvider.select((s) => s.isPremiumOrHigher),
    );

    // Show sync error snackbar if present
    final notifier = ref.read(beastModeConfigProvider.notifier);
    final syncError = notifier.lastSyncError;
    if (syncError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Sync failed: $syncError');
          notifier.clearSyncError();
        }
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const GlassBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department,
                color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              'Beast Mode',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: t.textPrimary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              BeastHeaderCard(isDark: t.isDark),
              const SizedBox(height: 24),

              // === ALGORITHM INSPECTOR ===
              _sectionTitle('ALGORITHM INSPECTOR',
                  'See the math behind your workouts', t),
              const SizedBox(height: 12),
              _premiumGatedCard(ScoringCard(theme: t), isPremium, t),
              const SizedBox(height: 12),
              FreshnessDecayCard(theme: t),
              const SizedBox(height: 12),
              DifficultyCard(theme: t),
              const SizedBox(height: 12),
              _premiumGatedCard(MoodCard(theme: t), isPremium, t),
              const SizedBox(height: 12),
              RestTimerCard(theme: t),

              const SizedBox(height: 24),

              // === RECOVERY & PROGRESSION ===
              _sectionTitle(
                  'RECOVERY & PROGRESSION',
                  "Visualize your body's recovery and forecast growth",
                  t),
              const SizedBox(height: 12),
              RecoverySection(theme: t),
              const SizedBox(height: 12),
              _premiumGatedCard(VolumeProgressionCard(theme: t), isPremium, t),
              const SizedBox(height: 12),
              _premiumGatedCard(RpeCard(theme: t), isPremium, t),

              const SizedBox(height: 24),

              // === CUSTOMIZATION LAB ===
              _sectionTitle('CUSTOMIZATION LAB',
                  'Advanced color and font controls', t),
              const SizedBox(height: 12),
              CustomColorLabCard(theme: t),
              const SizedBox(height: 12),
              FontScaleCard(theme: t),

              const SizedBox(height: 24),

              // === WORKOUT ALGORITHM ===
              _sectionTitle('WORKOUT ALGORITHM',
                  'Deep control over workout generation', t),
              const SizedBox(height: 12),
              SupersetAlgorithmCard(theme: t),
              const SizedBox(height: 12),
              RepProgressionCard(theme: t),
              const SizedBox(height: 12),
              WarmupCooldownCard(theme: t),
              const SizedBox(height: 12),
              WeightIncrementsCard(theme: t),

              const SizedBox(height: 24),

              // === DATA & SYNC TOOLS ===
              _sectionTitle('DATA & SYNC TOOLS',
                  'Debug sync issues and manage your data', t),
              const SizedBox(height: 12),
              DataSyncSection(theme: t),

              const SizedBox(height: 24),

              // === WORKOUT TEMPLATES ===
              _sectionTitle('WORKOUT TEMPLATES',
                  'Custom workout structure presets', t),
              const SizedBox(height: 12),
              TemplateSection(theme: t),

              const SizedBox(height: 24),

              // === ABOUT BEAST MODE ===
              _sectionTitle('ABOUT BEAST MODE',
                  'Build information and controls', t),
              const SizedBox(height: 12),
              AboutSection(theme: t),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps a card with a premium overlay when user is on free tier.
  Widget _premiumGatedCard(Widget card, bool isPremium, BeastThemeData t) {
    if (isPremium) return card;
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: IgnorePointer(child: card)),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Premium',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle, BeastThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.orange,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: t.textMuted)),
      ],
    );
  }
}
