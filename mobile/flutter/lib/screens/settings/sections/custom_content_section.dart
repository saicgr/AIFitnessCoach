import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/services/api_client.dart';
import '../widgets/section_header.dart';
import '../../../widgets/glass_sheet.dart';

part 'custom_content_section_part_custom_content_card.dart';
part 'custom_content_section_part_add_exercise_dialog.dart';


/// Section for managing user's custom content: equipment, exercises, workouts.
///
/// Allows users to add and manage content not in the predefined lists.
class CustomContentSection extends StatelessWidget {
  const CustomContentSection({super.key});

  /// Help items explaining custom content options
  static const List<Map<String, dynamic>> _customContentHelpItems = [
    {
      'icon': Icons.fitness_center,
      'title': 'My Equipment',
      'description': 'Add equipment that is not in our standard list. The AI will then be able to suggest exercises using your custom equipment in your workouts.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.sports_gymnastics,
      'title': 'My Exercises',
      'description': 'Create custom exercises or combine existing ones into supersets. These can be included in your AI-generated workouts alongside standard exercises.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'How It Works',
      'description': 'When the AI generates your workouts, it considers your custom equipment and exercises, mixing them with our exercise library to create personalized workouts.',
      'color': AppColors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'MY CUSTOM CONTENT',
          subtitle: 'Add your own equipment and exercises',
          helpTitle: 'Custom Content Explained',
          helpItems: _customContentHelpItems,
        ),
        const SizedBox(height: 12),
        const _CustomContentCard(),
      ],
    );
  }
}

/// Custom exercise data model
class CustomExercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final String equipment;
  final String instructions;
  final int defaultSets;
  final int? defaultReps;
  final bool isCompound;
  final String createdAt;

  CustomExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    required this.instructions,
    required this.defaultSets,
    this.defaultReps,
    required this.isCompound,
    required this.createdAt,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscle: json['primary_muscle'] as String,
      equipment: json['equipment'] as String,
      instructions: json['instructions'] as String? ?? '',
      defaultSets: json['default_sets'] as int? ?? 3,
      defaultReps: json['default_reps'] as int?,
      isCompound: json['is_compound'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }
}
