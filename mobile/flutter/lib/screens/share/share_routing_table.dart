/// Pure-function decision table for routing an inbound shared payload to
/// the right Zealova destination.
///
/// Kept dependency-free so it's trivially unit-testable. The UI layer
/// (ShareRouterScreen + ShareChooserSheet) calls into [decide] with the
/// classifier result and gets back a [ShareDestination] enum.
library share_routing_table;

/// Top-level destinations. The UI maps these to actual navigation.
enum ShareDestination {
  logFood,
  scanMenu,
  parseAppScreenshot,
  scanNutritionLabel,
  importRecipeUrl,
  importRecipePaste,
  importRecipePhoto,
  importMealPlan,
  importWorkoutReview,
  formCheck,
  importEquipment,
  progressUpload,
  pantryLog,
  savedTip,
  chat,
  chooser,
}

/// All "categories" surfaced as tag chips in the Imports screen.
enum ImportCategory {
  workout,
  recipe,
  mealPlan,
  foodLog,
  menu,
  formCheck,
  progress,
  equipment,
  tip,
  nutritionLabel,
  document,
  other,
}

/// "Format" tag — what kind of payload arrived.
enum ImportFormat { image, video, audio, pdf, url, text, carousel }

/// Decide where a single payload should land based on the backend
/// classifier's response. The router always falls through to [chooser]
/// rather than guessing when input is ambiguous.
class ShareDecision {
  ShareDecision({
    required this.destination,
    required this.confidence,
    this.intent,
    this.contentType,
    this.s3Key,
    this.sharedItemId,
  });

  final ShareDestination destination;
  final String confidence; // high|medium|low
  final String? intent;
  final String? contentType;
  final String? s3Key;
  final String? sharedItemId;

  bool get isConfident => confidence == 'high';
}

/// Routing for the image-classifier output (content_type → destination).
ShareDestination destinationForContentType(String contentType) {
  switch (contentType) {
    case 'food_plate':
    case 'food_buffet':
      return ShareDestination.logFood;
    case 'food_menu':
      return ShareDestination.scanMenu;
    case 'nutrition_label':
      return ShareDestination.scanNutritionLabel;
    case 'app_screenshot':
      return ShareDestination.parseAppScreenshot;
    case 'exercise_form':
      return ShareDestination.formCheck;
    case 'progress_photo':
      return ShareDestination.progressUpload;
    case 'gym_equipment':
      return ShareDestination.importEquipment;
    case 'recipe_handwritten':
      return ShareDestination.importRecipePhoto;
    case 'pantry_photo':
      return ShareDestination.pantryLog;
    case 'document':
    case 'unknown':
      return ShareDestination.chooser;
    default:
      return ShareDestination.chooser;
  }
}

/// Routing for the intent classifier output (intent → destination).
ShareDestination destinationForIntent(String intent) {
  switch (intent) {
    case 'workout_extract':
      return ShareDestination.importWorkoutReview;
    case 'recipe_extract':
      return ShareDestination.importRecipePaste;
    case 'meal_plan_extract':
      return ShareDestination.importMealPlan;
    case 'food_log_extract':
      return ShareDestination.logFood;
    case 'form_check':
      return ShareDestination.formCheck;
    case 'progress_log':
      return ShareDestination.progressUpload;
    case 'tip_save':
      return ShareDestination.savedTip;
    case 'nutrition_question':
    case 'discuss':
    default:
      return ShareDestination.chat;
  }
}

ImportCategory categoryForIntent(String? intent) {
  switch (intent) {
    case 'workout_extract':
      return ImportCategory.workout;
    case 'recipe_extract':
      return ImportCategory.recipe;
    case 'meal_plan_extract':
      return ImportCategory.mealPlan;
    case 'food_log_extract':
      return ImportCategory.foodLog;
    case 'form_check':
      return ImportCategory.formCheck;
    case 'progress_log':
      return ImportCategory.progress;
    case 'tip_save':
      return ImportCategory.tip;
    default:
      return ImportCategory.other;
  }
}

ImportCategory categoryForContentType(String? contentType) {
  switch (contentType) {
    case 'food_plate':
    case 'food_buffet':
    case 'app_screenshot':
      return ImportCategory.foodLog;
    case 'food_menu':
      return ImportCategory.menu;
    case 'nutrition_label':
      return ImportCategory.nutritionLabel;
    case 'exercise_form':
      return ImportCategory.formCheck;
    case 'progress_photo':
      return ImportCategory.progress;
    case 'gym_equipment':
      return ImportCategory.equipment;
    case 'recipe_handwritten':
      return ImportCategory.recipe;
    case 'pantry_photo':
      return ImportCategory.foodLog;
    case 'document':
      return ImportCategory.document;
    default:
      return ImportCategory.other;
  }
}

String categoryLabel(ImportCategory c) {
  switch (c) {
    case ImportCategory.workout:
      return 'Workout';
    case ImportCategory.recipe:
      return 'Recipe';
    case ImportCategory.mealPlan:
      return 'Meal plan';
    case ImportCategory.foodLog:
      return 'Food log';
    case ImportCategory.menu:
      return 'Menu';
    case ImportCategory.formCheck:
      return 'Form check';
    case ImportCategory.progress:
      return 'Progress';
    case ImportCategory.equipment:
      return 'Equipment';
    case ImportCategory.tip:
      return 'Tip';
    case ImportCategory.nutritionLabel:
      return 'Nutrition label';
    case ImportCategory.document:
      return 'Document';
    case ImportCategory.other:
      return 'Other';
  }
}

String formatLabel(ImportFormat f) {
  switch (f) {
    case ImportFormat.image:
      return 'Photo';
    case ImportFormat.video:
      return 'Video';
    case ImportFormat.audio:
      return 'Audio';
    case ImportFormat.pdf:
      return 'PDF';
    case ImportFormat.url:
      return 'Link';
    case ImportFormat.text:
      return 'Text';
    case ImportFormat.carousel:
      return 'Photos';
  }
}

ImportFormat? formatFromString(String? s) {
  switch (s) {
    case 'image':
    case 'photo':
      return ImportFormat.image;
    case 'video':
      return ImportFormat.video;
    case 'audio':
      return ImportFormat.audio;
    case 'pdf':
      return ImportFormat.pdf;
    case 'url':
      return ImportFormat.url;
    case 'text':
      return ImportFormat.text;
    case 'carousel':
      return ImportFormat.carousel;
    default:
      return null;
  }
}

ImportCategory? categoryFromString(String? s) {
  switch (s) {
    case 'workout':
      return ImportCategory.workout;
    case 'recipe':
      return ImportCategory.recipe;
    case 'meal_plan':
      return ImportCategory.mealPlan;
    case 'food_log':
      return ImportCategory.foodLog;
    case 'menu':
      return ImportCategory.menu;
    case 'form_check':
      return ImportCategory.formCheck;
    case 'progress':
      return ImportCategory.progress;
    case 'equipment':
      return ImportCategory.equipment;
    case 'tip':
      return ImportCategory.tip;
    case 'nutrition_label':
      return ImportCategory.nutritionLabel;
    case 'document':
      return ImportCategory.document;
    case 'other':
      return ImportCategory.other;
    default:
      return null;
  }
}

/// Short label for a source origin. Used in the Imports row card.
String originLabel(String? origin) {
  if (origin == null || origin.isEmpty) return 'Shared';
  switch (origin) {
    case 'photos':
      return 'Photos';
    case 'safari':
      return 'Safari';
    case 'youtube':
      return 'YouTube';
    case 'instagram':
      return 'Instagram';
    case 'tiktok':
      return 'TikTok';
    case 'reddit':
      return 'Reddit';
    case 'x':
      return 'X';
    case 'chatgpt':
      return 'ChatGPT';
    case 'claude':
      return 'Claude';
    case 'perplexity':
      return 'Perplexity';
    case 'voicememos':
      return 'Voice Memos';
    case 'files':
      return 'Files';
    case 'notes':
      return 'Notes';
    case 'imessage':
      return 'iMessage';
    case 'whatsapp':
      return 'WhatsApp';
    case 'mail':
      return 'Mail';
    case 'shortcuts':
      return 'Shortcuts';
    case 'web':
      return 'Web';
    case 'manual_paste':
      return 'Pasted';
    default:
      return origin;
  }
}
