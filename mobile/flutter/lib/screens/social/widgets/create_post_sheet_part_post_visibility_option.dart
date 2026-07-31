part of 'create_post_sheet.dart';



/// UI representation for post visibility options
enum PostVisibilityOption {
  public('Public', Icons.public_rounded, PostVisibility.public),
  friends('Friends', Icons.people_rounded, PostVisibility.friends),
  privateOnly('Private', Icons.lock_rounded, PostVisibility.private);

  final String label;
  final IconData icon;
  final PostVisibility serviceValue;

  const PostVisibilityOption(this.label, this.icon, this.serviceValue);
}


/// Reddit-style flair tags for posts
enum PostFlair {
  fitness('Fitness', Icons.fitness_center_rounded, Color(0xFF06B6D4)),  // accent-allowlist: flair identity — no BuildContext available in this scope (enum constructor)
  progress('Progress', Icons.trending_up_rounded, Color(0xFF22C55E)),  // accent-allowlist: success/positive state — must stay green regardless of accent
  milestone('Milestone', Icons.emoji_events_rounded, Color(0xFFF97316)),  // accent-allowlist: flair identity — no BuildContext available in this scope (enum constructor)
  nutrition('Nutrition', Icons.restaurant_rounded, Color(0xFFA855F7)),  // accent-allowlist: flair identity — no BuildContext available in this scope (enum constructor)
  motivation('Motivation', Icons.bolt_rounded, Color(0xFFEAB308)),  // accent-allowlist: warning severity — must stay amber regardless of accent
  question('Question', Icons.help_outline_rounded, Color(0xFF3B82F6));  // accent-allowlist: informational state — must stay blue regardless of accent

  final String label;
  final IconData icon;
  final Color color;

  const PostFlair(this.label, this.icon, this.color);
}

