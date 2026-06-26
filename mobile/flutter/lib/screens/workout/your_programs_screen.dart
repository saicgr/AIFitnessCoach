import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/program_template.dart';
import '../../data/models/user_program_assignment.dart';
import '../../data/providers/habit_provider.dart' show currentUserIdProvider;
import '../../data/providers/program_assignments_provider.dart';
import '../../data/providers/program_favorites_provider.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import 'program_detail_screen.dart';
import 'program_template_builder_screen.dart';
import 'widgets/ai_adaptive_plan_card.dart';
import 'widgets/program_library_card.dart';
import 'widgets/program_manage_sheet.dart';

/// Route metadata for the Your Programs hub.
class YourProgramsRoute {
  YourProgramsRoute._();
  static const String path = '/workout/your-programs';
}

/// The "Your Programs" hub — a single scroll with four sections:
///   • Active    — in-progress assignments (title, Week X/Y) → manage/active.
///   • Favorites — hearted library programs → detail page.
///   • Custom    — saved templates authored/duplicated → builder.
///   • AI-made   — saved templates parsed/imported/coach-generated → builder.
///
/// Signature-v2 (near-black, Anton masthead, orange accent). Each section has a
/// header + a horizontal rail and its own empty state — never a fake/mock row.
class YourProgramsScreen extends ConsumerStatefulWidget {
  const YourProgramsScreen({super.key});

  @override
  ConsumerState<YourProgramsScreen> createState() => _YourProgramsScreenState();
}

class _YourProgramsScreenState extends ConsumerState<YourProgramsScreen> {
  /// The user's saved templates (Custom + AI-made are partitions of this).
  Future<List<ProgramTemplate>>? _templates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTemplates());
  }

  void _loadTemplates() {
    final userId = ref.read(currentUserIdProvider);
    final repo = ref.read(programTemplateRepositoryProvider);
    setState(() {
      _templates = userId == null
          ? Future.error(StateError('not_signed_in'))
          : repo.listForUser(userId);
    });
  }

  void _back() {
    HapticService.light();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 14, bottom: 32),
                children: [
                  _buildActiveSection(),
                  _buildFavoritesSection(),
                  _buildCustomSection(),
                  _buildAiSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(bottom: BorderSide(color: AppColors.hairlineStrong)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 13),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 8, top: 2, bottom: 2),
              child: Text(
                '‹',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  height: 1.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'YOUR PROGRAMS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.disp(28, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Active — in-progress assignments.
  // -------------------------------------------------------------------------

  Widget _buildActiveSection() {
    final async = ref.watch(programAssignmentsProvider);
    return _Section(
      title: 'ACTIVE',
      child: async.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const _RailSkeleton(),
        error: (_, __) => const _SectionEmpty(
          icon: Icons.error_outline_rounded,
          label: 'Could not load your active programs.',
        ),
        data: (assignments) {
          final active = assignments
              .where((a) => a.status == 'active' && a.isActive)
              .toList(growable: false);
          // No assigned PRIMARY program → the AI Coach adaptive plan is what
          // actually drives the user's home workout, so surface it FIRST. This
          // means Active is never empty (real programs and/or the AI card).
          final hasActivePrimary =
              assignments.any((a) => a.isPrimary && a.isActive);

          final cards = <Widget>[
            if (!hasActivePrimary)
              const SizedBox(width: 260, child: AiAdaptivePlanCard()),
            for (final assignment in active)
              _ActiveProgramCard(
                assignment: assignment,
                onTap: () {
                  HapticService.light();
                  // Open the shared manage sheet (pause / resume / edit / end).
                  showProgramManageSheet(context, ref, assignment);
                },
              ),
          ];

          return _HorizontalRail(
            itemCount: cards.length,
            itemBuilder: (context, i) => cards[i],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Favorites — hearted library programs.
  // -------------------------------------------------------------------------

  Widget _buildFavoritesSection() {
    final async = ref.watch(favoriteProgramsProvider);
    return _Section(
      title: 'FAVORITES',
      child: async.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const _RailSkeleton(),
        error: (_, __) => const _SectionEmpty(
          icon: Icons.error_outline_rounded,
          label: 'Could not load your favorites.',
        ),
        data: (programs) {
          if (programs.isEmpty) {
            return const _SectionEmpty(
              icon: Icons.favorite_border_rounded,
              label: 'No favorites yet. Tap the heart on any program.',
            );
          }
          return _HorizontalRail(
            itemCount: programs.length,
            itemBuilder: (context, i) {
              final p = programs[i];
              return SizedBox(
                width: 150,
                child: ProgramLibraryCardTile(
                  data: p,
                  showFavorite: true,
                  onTap: () {
                    HapticService.light();
                    context.push(ProgramDetailRoute.path, extra: {'card': p});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Custom + AI-made — partitions of the saved templates.
  // -------------------------------------------------------------------------

  static const _kCustomSources = {'authored', 'duplicated'};
  static const _kAiSources = {'parsed', 'imported', 'coach_generated'};

  Widget _buildCustomSection() {
    return _buildTemplateSection(
      title: 'CUSTOM',
      sources: _kCustomSources,
      emptyIcon: Icons.edit_calendar_rounded,
      emptyLabel: 'No custom programs yet. Build one from scratch.',
    );
  }

  Widget _buildAiSection() {
    return _buildTemplateSection(
      title: 'AI-MADE',
      sources: _kAiSources,
      emptyIcon: Icons.auto_awesome_rounded,
      emptyLabel: 'No AI-made programs yet. Generate one with AI.',
    );
  }

  Widget _buildTemplateSection({
    required String title,
    required Set<String> sources,
    required IconData emptyIcon,
    required String emptyLabel,
  }) {
    return _Section(
      title: title,
      child: FutureBuilder<List<ProgramTemplate>>(
        future: _templates,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _RailSkeleton();
          }
          if (snapshot.hasError) {
            return const _SectionEmpty(
              icon: Icons.error_outline_rounded,
              label: 'Could not load your saved programs.',
            );
          }
          final all = snapshot.data ?? const <ProgramTemplate>[];
          final matched = all
              .where((t) => sources.contains(t.source))
              .toList(growable: false);
          if (matched.isEmpty) {
            return _SectionEmpty(icon: emptyIcon, label: emptyLabel);
          }
          return _HorizontalRail(
            itemCount: matched.length,
            itemBuilder: (context, i) {
              final t = matched[i];
              return SizedBox(
                width: 150,
                child: ProgramLibraryCardTile(
                  data: programCardFromTemplate(t),
                  onTap: () {
                    HapticService.light();
                    context.push(ProgramBuilderRoute.path, extra: t);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Section scaffold + rail + empty + skeleton.
// ===========================================================================

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 11),
            child: Text(
              title,
              style: ZType.lbl(14,
                  color: AppColors.textPrimary, letterSpacing: 1.8),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HorizontalRail extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _HorizontalRail({required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionEmpty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: ZType.sans(13,
                  color: AppColors.textSecondary, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, __) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Active program card — title + Week X/Y + a thin progress bar.
// ===========================================================================

class _ActiveProgramCard extends StatelessWidget {
  final UserProgramAssignment assignment;
  final VoidCallback onTap;

  const _ActiveProgramCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (assignment.progressPercentage.clamp(0, 100)) / 100.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (assignment.isAddon)
                  _slotPill('ADD-ON')
                else
                  _slotPill('PRIMARY'),
              ],
            ),
            const Spacer(),
            Text(
              assignment.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ZType.sans(17,
                  color: AppColors.textPrimary, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              assignment.weekLabel,
              style: ZType.data(11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            // Thin progress bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: ZType.lbl(9.5, color: AppColors.orange, letterSpacing: 1.2)),
    );
  }
}
