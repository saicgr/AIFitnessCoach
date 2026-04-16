/// Cook-once-eat-many leftover tracking models.
library;

enum StorageKind {
  fridge('fridge'),
  freezer('freezer'),
  counter('counter');

  final String value;
  const StorageKind(this.value);

  static StorageKind fromValue(String? v) =>
      StorageKind.values.firstWhere((e) => e.value == v, orElse: () => StorageKind.fridge);
}

class CookEvent {
  final String id;
  final String userId;
  final String? recipeId;
  final DateTime cookedAt;
  final double portionsMade;
  final double portionsRemaining;
  final StorageKind storage;
  final DateTime expiresAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CookEvent({
    required this.id,
    required this.userId,
    required this.cookedAt,
    required this.portionsMade,
    required this.portionsRemaining,
    required this.storage,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.recipeId,
    this.notes,
  });

  factory CookEvent.fromJson(Map<String, dynamic> json) => CookEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        recipeId: json['recipe_id'] as String?,
        cookedAt: DateTime.parse(json['cooked_at'] as String),
        portionsMade: (json['portions_made'] as num).toDouble(),
        portionsRemaining: (json['portions_remaining'] as num).toDouble(),
        storage: StorageKind.fromValue(json['storage'] as String?),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'recipe_id': recipeId,
        'cooked_at': cookedAt.toIso8601String(),
        'portions_made': portionsMade,
        'portions_remaining': portionsRemaining,
        'storage': storage.value,
        'expires_at': expiresAt.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class CookEventCreate {
  final String? recipeId;
  final DateTime? cookedAt;
  final double portionsMade;
  final double? portionsRemaining;
  final StorageKind storage;
  final DateTime? expiresAt;
  final String? notes;

  const CookEventCreate({
    required this.portionsMade,
    this.recipeId,
    this.cookedAt,
    this.portionsRemaining,
    this.storage = StorageKind.fridge,
    this.expiresAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        if (recipeId != null) 'recipe_id': recipeId,
        if (cookedAt != null) 'cooked_at': cookedAt!.toIso8601String(),
        'portions_made': portionsMade,
        if (portionsRemaining != null) 'portions_remaining': portionsRemaining,
        'storage': storage.value,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

class ActiveCookEvent {
  final String id;
  final String? recipeId;
  final String? recipeName;
  final String? recipeImageUrl;
  final DateTime cookedAt;
  final double portionsRemaining;
  final double portionsMade;
  final StorageKind storage;
  final DateTime expiresAt;
  final bool isExpired;
  final bool isExpiringSoon;

  const ActiveCookEvent({
    required this.id,
    required this.cookedAt,
    required this.portionsRemaining,
    required this.portionsMade,
    required this.storage,
    required this.expiresAt,
    required this.isExpired,
    required this.isExpiringSoon,
    this.recipeId,
    this.recipeName,
    this.recipeImageUrl,
  });

  factory ActiveCookEvent.fromJson(Map<String, dynamic> json) => ActiveCookEvent(
        id: json['id'] as String,
        recipeId: json['recipe_id'] as String?,
        recipeName: json['recipe_name'] as String?,
        recipeImageUrl: json['recipe_image_url'] as String?,
        cookedAt: DateTime.parse(json['cooked_at'] as String),
        portionsRemaining: (json['portions_remaining'] as num).toDouble(),
        portionsMade: (json['portions_made'] as num).toDouble(),
        storage: StorageKind.fromValue(json['storage'] as String?),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        isExpired: json['is_expired'] as bool? ?? false,
        isExpiringSoon: json['is_expiring_soon'] as bool? ?? false,
      );
}
