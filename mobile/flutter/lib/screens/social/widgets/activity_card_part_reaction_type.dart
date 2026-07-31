part of 'activity_card.dart';



/// Reaction type enum matching backend
enum ReactionType {
  cheer('cheer', '🎉', 'Cheer', AppColors.orange),  // accent-allowlist: reaction type identity — fixed per-reaction color (cheer/fire/strong/clap/heart), recoloring would collide two reaction types into the same color
  fire('fire', '🔥', 'Fire', AppColors.red),  // accent-allowlist: reaction type identity — fixed per-reaction color (cheer/fire/strong/clap/heart), recoloring would collide two reaction types into the same color
  strong('strong', '💪', 'Strong', AppColors.purple),  // accent-allowlist: reaction type identity — fixed per-reaction color (cheer/fire/strong/clap/heart), recoloring would collide two reaction types into the same color
  clap('clap', '👏', 'Clap', AppColors.cyan),  // accent-allowlist: reaction type identity — fixed per-reaction color (cheer/fire/strong/clap/heart), recoloring would collide two reaction types into the same color
  heart('heart', '❤️', 'Heart', AppColors.pink);  // accent-allowlist: reaction type identity — fixed per-reaction color (cheer/fire/strong/clap/heart), recoloring would collide two reaction types into the same color

  final String value;
  final String emoji;
  final String label;
  final Color color;

  const ReactionType(this.value, this.emoji, this.label, this.color);
}

