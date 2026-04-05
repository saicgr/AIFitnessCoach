part of 'social_service.dart';


/// Activity type enum for social posts
enum SocialActivityType {
  workoutCompleted('workout_completed'),
  workoutShared('workout_shared'),
  achievementEarned('achievement_earned'),
  personalRecord('personal_record'),
  weightMilestone('weight_milestone'),
  streakMilestone('streak_milestone'),
  manualPost('manual_post');

  final String value;
  const SocialActivityType(this.value);
}


/// Visibility level for posts
enum PostVisibility {
  public('public'),
  friends('friends'),
  family('family'),
  private('private');

  final String value;
  const PostVisibility(this.value);
}

