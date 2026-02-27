import 'package:flutter/material.dart';

enum ChatActionBehavior { sendPrompt, openMediaPicker }

enum ChatMediaMode { camera, gallery, video, recordVideo }

class ChatQuickAction {
  final String id;
  final String label;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final ChatActionBehavior behavior;
  final String? prompt;
  final ChatMediaMode? mediaMode;
  final String? examplePrompt;

  const ChatQuickAction({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.behavior,
    this.prompt,
    this.mediaMode,
    this.examplePrompt,
  });
}

const chatQuickActionRegistry = <String, ChatQuickAction>{
  'check_form': ChatQuickAction(
    id: 'check_form',
    label: 'Check My Form',
    description: 'Record an exercise for AI form feedback',
    category: 'Form Analysis',
    icon: Icons.videocam_outlined,
    color: Color(0xFFF97316),
    behavior: ChatActionBehavior.openMediaPicker,
    mediaMode: ChatMediaMode.video,
    examplePrompt: 'Please check my exercise form',
  ),
  'scan_food': ChatQuickAction(
    id: 'scan_food',
    label: 'Scan Food',
    description: 'Snap a photo for instant calorie estimates',
    category: 'Nutrition',
    icon: Icons.camera_alt_outlined,
    color: Color(0xFF22C55E),
    behavior: ChatActionBehavior.openMediaPicker,
    mediaMode: ChatMediaMode.camera,
    examplePrompt: 'Analyze this food and estimate calories',
  ),
  'analyze_menu': ChatQuickAction(
    id: 'analyze_menu',
    label: 'Analyze Menu',
    description: 'Photograph a menu for smart picks',
    category: 'Nutrition',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF14B8A6),
    behavior: ChatActionBehavior.openMediaPicker,
    mediaMode: ChatMediaMode.gallery,
    examplePrompt: 'Analyze this menu and suggest healthy options',
  ),
  'quick_workout': ChatQuickAction(
    id: 'quick_workout',
    label: 'Quick Workout',
    description: 'Generate a fast workout on the fly',
    category: 'Workout',
    icon: Icons.flash_on_outlined,
    color: Color(0xFF06B6D4),
    behavior: ChatActionBehavior.sendPrompt,
    prompt: 'Create a quick 15-minute workout for me',
  ),
  'nutrition_advice': ChatQuickAction(
    id: 'nutrition_advice',
    label: 'Nutrition Tips',
    description: 'Get personalized nutrition guidance',
    category: 'Nutrition',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFA855F7),
    behavior: ChatActionBehavior.sendPrompt,
    prompt: 'What should I eat based on my fitness goals?',
  ),
  'compare_form': ChatQuickAction(
    id: 'compare_form',
    label: 'Compare Form',
    description: 'Compare two videos of the same exercise',
    category: 'Form Analysis',
    icon: Icons.compare_outlined,
    color: Color(0xFFF97316),
    behavior: ChatActionBehavior.openMediaPicker,
    mediaMode: ChatMediaMode.video,
    examplePrompt: 'Compare my exercise form between these videos',
  ),
  'recovery_tips': ChatQuickAction(
    id: 'recovery_tips',
    label: 'Recovery Help',
    description: 'Get recovery and rest day advice',
    category: 'Recovery',
    icon: Icons.self_improvement_outlined,
    color: Color(0xFF3B82F6),
    behavior: ChatActionBehavior.sendPrompt,
    prompt: 'I need recovery advice for my muscles',
  ),
  'meal_prep': ChatQuickAction(
    id: 'meal_prep',
    label: 'Meal Prep',
    description: 'Plan your meals for the week',
    category: 'Workout',
    icon: Icons.lunch_dining_outlined,
    color: Color(0xFF22C55E),
    behavior: ChatActionBehavior.sendPrompt,
    prompt: 'Give me a simple high-protein meal prep plan',
  ),
  'injury_help': ChatQuickAction(
    id: 'injury_help',
    label: 'Injury Advice',
    description: 'Get guidance on pain and injuries',
    category: 'Recovery',
    icon: Icons.healing_outlined,
    color: Color(0xFFEF4444),
    behavior: ChatActionBehavior.sendPrompt,
    prompt: 'I have pain in my body, what should I do?',
  ),
  'calorie_check': ChatQuickAction(
    id: 'calorie_check',
    label: 'Calorie Check',
    description: 'Quick photo calorie estimate',
    category: 'Nutrition',
    icon: Icons.local_fire_department_outlined,
    color: Color(0xFFF59E0B),
    behavior: ChatActionBehavior.openMediaPicker,
    mediaMode: ChatMediaMode.camera,
    examplePrompt: 'How many calories are in this food?',
  ),
};

const defaultChatQuickActionOrder = [
  'check_form',
  'scan_food',
  'analyze_menu',
  'quick_workout',
  'nutrition_advice',
  'compare_form',
  'recovery_tips',
  'meal_prep',
  'injury_help',
  'calorie_check',
];
