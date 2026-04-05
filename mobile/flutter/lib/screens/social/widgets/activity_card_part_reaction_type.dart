part of 'activity_card.dart';



/// Reaction type enum matching backend
enum ReactionType {
  cheer('cheer', '🎉', 'Cheer', AppColors.orange),
  fire('fire', '🔥', 'Fire', AppColors.red),
  strong('strong', '💪', 'Strong', AppColors.purple),
  clap('clap', '👏', 'Clap', AppColors.cyan),
  heart('heart', '❤️', 'Heart', AppColors.pink);

  final String value;
  final String emoji;
  final String label;
  final Color color;

  const ReactionType(this.value, this.emoji, this.label, this.color);
}

