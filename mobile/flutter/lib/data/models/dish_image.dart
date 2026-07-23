/// A resolved thumbnail for a menu dish.
///
/// Returned by `POST /nutrition/dish-images/resolve` (free sources) and
/// `POST /nutrition/dish-images/generate` (AI, capped). The [source] matters
/// to the UI, not just to analytics:
///
///   * `user_photo` — the user's own photo of this dish. Worth labelling
///     ("your photo") because it's the most trustworthy image we can show.
///   * `food_db` / `web_cc` — a real photo of the dish; `web_cc` carries an
///     [attribution] line the licence requires us to display.
///   * `ai` — generated. Must render the [disclosure] so nobody mistakes it
///     for a photo of what that restaurant actually serves.
///
/// Plain hand-written class (not freezed): this project ships generated files
/// pre-committed and does NOT run build_runner.
class DishImage {
  final String url;
  final String source;
  final String? attribution;
  final bool isAi;
  final String? disclosure;

  const DishImage({
    required this.url,
    required this.source,
    this.attribution,
    this.isAi = false,
    this.disclosure,
  });

  bool get isUserPhoto => source == 'user_photo';

  /// Credit line that MUST be shown with the image, if any.
  String? get requiredCaption => isAi ? disclosure : attribution;

  factory DishImage.fromJson(Map<String, dynamic> json) {
    return DishImage(
      url: (json['url'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'unknown',
      attribution: json['attribution'] as String?,
      isAi: json['is_ai'] as bool? ?? false,
      disclosure: json['disclosure'] as String?,
    );
  }
}

/// Thrown by `generateDishImage` so the caller can tell "you've hit today's
/// limit" apart from "that didn't work" — the first deserves a real message,
/// the second just leaves the placeholder in place.
class DishImageException implements Exception {
  final String message;
  final bool isCapReached;

  const DishImageException(this.message, {this.isCapReached = false});

  @override
  String toString() => message;
}
