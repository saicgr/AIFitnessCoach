import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/branded_program.dart';
import 'program_carousel_card.dart';

/// A horizontal carousel section for displaying programs
/// Netflix-style layout with section header and horizontal scroll
class ProgramCarouselSection extends StatelessWidget {
  final String title;
  final List<BrandedProgram> programs;
  final VoidCallback? onSeeAll;
  final bool isFeatured;

  const ProgramCarouselSection({
    super.key,
    required this.title,
    required this.programs,
    this.onSeeAll,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Card dimensions - slightly smaller to prevent overflow
    final cardWidth = isFeatured ? 180.0 : 150.0;
    final cardHeight = isFeatured ? 220.0 : 180.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isFeatured ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSeeAll != null && programs.length > 3)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal carousel
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none,
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < programs.length - 1 ? 10 : 0,
                ),
                child: ProgramCarouselCard(
                  program: program,
                  width: cardWidth,
                  height: cardHeight,
                  isFeatured: isFeatured,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
