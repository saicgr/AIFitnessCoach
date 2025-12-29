import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Pre-defined coach personas and custom coach configuration.
/// Each coach has a unique personality, communication style, and visual identity.
class CoachPersona {
  final String id;
  final String name;
  final String tagline;
  final String specialization;
  final String coachingStyle;
  final String communicationTone;
  final double encouragementLevel;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final bool isCustom;

  const CoachPersona({
    required this.id,
    required this.name,
    required this.tagline,
    required this.specialization,
    required this.coachingStyle,
    required this.communicationTone,
    required this.encouragementLevel,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    this.isCustom = false,
  });

  /// Pre-defined coach personas
  static const List<CoachPersona> predefinedCoaches = [
    CoachPersona(
      id: 'coach_mike',
      name: 'Coach Mike',
      tagline: 'Your Motivational Powerhouse',
      specialization: 'Strength & Muscle Building',
      coachingStyle: 'motivational',
      communicationTone: 'encouraging',
      encouragementLevel: 0.9,
      icon: Icons.fitness_center,
      primaryColor: AppColors.orange,
      accentColor: AppColors.coral,
    ),
    CoachPersona(
      id: 'dr_sarah',
      name: 'Dr. Sarah',
      tagline: 'Evidence-Based Excellence',
      specialization: 'Scientific Training',
      coachingStyle: 'scientist',
      communicationTone: 'formal',
      encouragementLevel: 0.6,
      icon: Icons.science,
      primaryColor: AppColors.electricBlue,
      accentColor: AppColors.cyan,
    ),
    CoachPersona(
      id: 'sergeant_max',
      name: 'Sergeant Max',
      tagline: 'No Excuses, No Limits',
      specialization: 'Discipline & Intensity',
      coachingStyle: 'drill-sergeant',
      communicationTone: 'tough-love',
      encouragementLevel: 0.4,
      icon: Icons.military_tech,
      primaryColor: AppColors.coral,
      accentColor: AppColors.error,
    ),
    CoachPersona(
      id: 'zen_maya',
      name: 'Zen Maya',
      tagline: 'Balance Body & Mind',
      specialization: 'Mindful Fitness',
      coachingStyle: 'zen-master',
      communicationTone: 'casual',
      encouragementLevel: 0.7,
      icon: Icons.spa,
      primaryColor: AppColors.teal,
      accentColor: AppColors.success,
    ),
    CoachPersona(
      id: 'hype_danny',
      name: 'Hype Danny',
      tagline: "LET'S GOOOO!!!",
      specialization: 'Energy & Fun',
      coachingStyle: 'hype-beast',
      communicationTone: 'gen-z',
      encouragementLevel: 1.0,
      icon: Icons.celebration,
      primaryColor: AppColors.magenta,
      accentColor: AppColors.purple,
    ),
  ];

  /// Create a custom coach with user-defined settings
  factory CoachPersona.custom({
    required String name,
    required String coachingStyle,
    required String communicationTone,
    double encouragementLevel = 0.7,
  }) {
    return CoachPersona(
      id: 'custom',
      name: name.isEmpty ? 'My Coach' : name,
      tagline: 'Your Personal AI Coach',
      specialization: 'Customized Training',
      coachingStyle: coachingStyle,
      communicationTone: communicationTone,
      encouragementLevel: encouragementLevel,
      icon: Icons.auto_awesome,
      primaryColor: AppColors.cyan,
      accentColor: AppColors.purple,
      isCustom: true,
    );
  }

  /// Find a predefined coach by ID
  static CoachPersona? findById(String? id) {
    if (id == null) return null;
    if (id == 'custom') return null; // Custom coaches need to be reconstructed from settings
    try {
      return predefinedCoaches.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the default coach (Coach Mike)
  static CoachPersona get defaultCoach => predefinedCoaches.first;

  /// Convert to JSON for API/storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'specialization': specialization,
        'coaching_style': coachingStyle,
        'communication_tone': communicationTone,
        'encouragement_level': encouragementLevel,
        'is_custom': isCustom,
      };

  /// Create from JSON (for custom coaches stored in settings)
  factory CoachPersona.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'custom';

    // If it's a predefined coach, return that
    final predefined = findById(id);
    if (predefined != null) return predefined;

    // Otherwise, create a custom coach
    return CoachPersona.custom(
      name: json['name'] as String? ?? 'My Coach',
      coachingStyle: json['coaching_style'] as String? ?? 'motivational',
      communicationTone: json['communication_tone'] as String? ?? 'encouraging',
      encouragementLevel: (json['encouragement_level'] as num?)?.toDouble() ?? 0.7,
    );
  }

  /// Get a short personality description
  String get personalityBadge {
    final styleLabel = _formatStyle(coachingStyle);
    final toneLabel = _formatTone(communicationTone);
    return '$styleLabel + $toneLabel';
  }

  String _formatStyle(String style) {
    switch (style) {
      case 'motivational':
        return 'Motivational';
      case 'professional':
        return 'Professional';
      case 'friendly':
        return 'Friendly';
      case 'tough-love':
        return 'Tough Love';
      case 'drill-sergeant':
        return 'Drill Sergeant';
      case 'zen-master':
        return 'Zen Master';
      case 'hype-beast':
        return 'Hype Beast';
      case 'scientist':
        return 'Scientific';
      case 'comedian':
        return 'Comedian';
      case 'old-school':
        return 'Old School';
      case 'college-coach':
        return 'College Coach';
      default:
        return style.replaceAll('-', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  String _formatTone(String tone) {
    switch (tone) {
      case 'casual':
        return 'Casual';
      case 'encouraging':
        return 'Encouraging';
      case 'formal':
        return 'Formal';
      case 'gen-z':
        return 'Gen-Z';
      case 'sarcastic':
        return 'Sarcastic';
      case 'roast-mode':
        return 'Roast Mode';
      case 'tough-love':
        return 'Tough Love';
      case 'pirate':
        return 'Pirate';
      case 'british':
        return 'British';
      case 'surfer':
        return 'Surfer';
      case 'anime':
        return 'Anime';
      default:
        return tone.replaceAll('-', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachPersona && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Get the coach's greeting intro based on personality
  String get greetingIntro {
    switch (id) {
      case 'coach_mike':
        return "Hey champ! 💪 I'm Coach Mike, your personal hype machine!";
      case 'dr_sarah':
        return "Hello! I'm Dr. Sarah. Let's take a scientific approach to your fitness journey.";
      case 'sergeant_max':
        return "Listen up, recruit! I'm Sergeant Max. We're gonna build you into a machine!";
      case 'zen_maya':
        return "Namaste 🧘 I'm Maya. Let's find balance and strength on your journey.";
      case 'hype_danny':
        return "YOOO what's good fam!! 🔥🔥 Danny here and WE'RE ABOUT TO GO CRAZY!!";
      default:
        return "Hey! I'm your AI fitness coach. Let's get started!";
    }
  }

  /// Get the coach's summary connector phrase based on personality
  String get summaryConnector {
    switch (id) {
      case 'coach_mike':
        return "Awesome! So you want to";
      case 'dr_sarah':
        return "Excellent. Based on your input, your goals are to";
      case 'sergeant_max':
        return "Alright soldier! Your mission is to";
      case 'zen_maya':
        return "Beautiful. Your path includes";
      case 'hype_danny':
        return "BRO that's FIRE!! 🔥 You're tryna";
      default:
        return "Great! You want to";
    }
  }

  /// Get the coach's call to action for the form based on personality
  String get formCallToAction {
    switch (id) {
      case 'coach_mike':
        return "Let's finalize your game plan - just need a few quick details! 🎯";
      case 'dr_sarah':
        return "Please provide these additional data points for optimal program design.";
      case 'sergeant_max':
        return "Give me your stats below - NO EXCUSES! 💥";
      case 'zen_maya':
        return "Share a bit more about yourself so we can craft your perfect journey. ✨";
      case 'hype_danny':
        return "Drop your deets below and LET'S GET THIS BREAD!! 🍞💪";
      default:
        return "Just need a few more details below! 💪";
    }
  }

  /// Get emoji for this coach
  String get emoji {
    switch (id) {
      case 'coach_mike':
        return '💪';
      case 'dr_sarah':
        return '🔬';
      case 'sergeant_max':
        return '💥';
      case 'zen_maya':
        return '🧘';
      case 'hype_danny':
        return '🔥';
      default:
        return '💪';
    }
  }
}

/// Available coaching styles for custom coach
class CoachingStyles {
  static const List<Map<String, String>> all = [
    {'id': 'motivational', 'label': 'Motivational', 'description': 'Uplifting and inspiring'},
    {'id': 'professional', 'label': 'Professional', 'description': 'Focused and business-like'},
    {'id': 'friendly', 'label': 'Friendly', 'description': 'Warm and approachable'},
    {'id': 'tough-love', 'label': 'Tough Love', 'description': 'Honest and direct'},
    {'id': 'drill-sergeant', 'label': 'Drill Sergeant', 'description': 'Intense and demanding'},
    {'id': 'zen-master', 'label': 'Zen Master', 'description': 'Calm and mindful'},
    {'id': 'hype-beast', 'label': 'Hype Beast', 'description': 'High energy and exciting'},
    {'id': 'scientist', 'label': 'Scientist', 'description': 'Data-driven and analytical'},
    {'id': 'comedian', 'label': 'Comedian', 'description': 'Funny and entertaining'},
    {'id': 'old-school', 'label': 'Old School', 'description': 'Traditional and no-nonsense'},
    {'id': 'college-coach', 'label': 'College Coach', 'description': 'Team-oriented and competitive'},
  ];
}

/// Available communication tones for custom coach
class CommunicationTones {
  static const List<Map<String, String>> all = [
    {'id': 'casual', 'label': 'Casual', 'description': 'Relaxed and conversational'},
    {'id': 'encouraging', 'label': 'Encouraging', 'description': 'Supportive and positive'},
    {'id': 'formal', 'label': 'Formal', 'description': 'Professional and structured'},
    {'id': 'gen-z', 'label': 'Gen-Z', 'description': 'Trendy slang and vibes'},
    {'id': 'sarcastic', 'label': 'Sarcastic', 'description': 'Witty and playful teasing'},
    {'id': 'roast-mode', 'label': 'Roast Mode', 'description': 'Brutally honest humor'},
    {'id': 'tough-love', 'label': 'Tough Love', 'description': 'Direct and firm'},
    {'id': 'pirate', 'label': 'Pirate', 'description': 'Arrr matey! Nautical fun'},
    {'id': 'british', 'label': 'British', 'description': 'Proper and refined'},
    {'id': 'surfer', 'label': 'Surfer', 'description': 'Chill and laid-back'},
    {'id': 'anime', 'label': 'Anime', 'description': 'Dramatic and expressive'},
  ];
}
