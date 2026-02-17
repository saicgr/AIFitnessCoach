// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressPhoto _$ProgressPhotoFromJson(Map<String, dynamic> json) =>
    ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      photoUrl: json['photo_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      viewType: json['view_type'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      bodyWeightKg: (json['body_weight_kg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      measurementId: json['measurement_id'] as String?,
      isComparisonReady: json['is_comparison_ready'] as bool? ?? true,
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProgressPhotoToJson(ProgressPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'photo_url': instance.photoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'view_type': instance.viewType,
      'taken_at': instance.takenAt.toIso8601String(),
      'body_weight_kg': instance.bodyWeightKg,
      'notes': instance.notes,
      'measurement_id': instance.measurementId,
      'is_comparison_ready': instance.isComparisonReady,
      'visibility': instance.visibility,
      'created_at': instance.createdAt.toIso8601String(),
    };

PhotoComparison _$PhotoComparisonFromJson(Map<String, dynamic> json) =>
    PhotoComparison(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      beforePhoto: ProgressPhoto.fromJson(
        json['before_photo'] as Map<String, dynamic>,
      ),
      afterPhoto: ProgressPhoto.fromJson(
        json['after_photo'] as Map<String, dynamic>,
      ),
      title: json['title'] as String?,
      description: json['description'] as String?,
      weightChangeKg: (json['weight_change_kg'] as num?)?.toDouble(),
      daysBetween: (json['days_between'] as num?)?.toInt(),
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: DateTime.parse(json['created_at'] as String),
      photosJson: (json['photos_json'] as List<dynamic>?)
          ?.map((e) => ComparisonPhotoEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      layout: json['layout'] as String?,
      settingsJson: json['settings_json'] as Map<String, dynamic>?,
      exportedImageUrl: json['exported_image_url'] as String?,
      aiSummary: json['ai_summary'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PhotoComparisonToJson(PhotoComparison instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'before_photo': instance.beforePhoto,
      'after_photo': instance.afterPhoto,
      'title': instance.title,
      'description': instance.description,
      'weight_change_kg': instance.weightChangeKg,
      'days_between': instance.daysBetween,
      'visibility': instance.visibility,
      'created_at': instance.createdAt.toIso8601String(),
      'photos_json': instance.photosJson,
      'layout': instance.layout,
      'settings_json': instance.settingsJson,
      'exported_image_url': instance.exportedImageUrl,
      'ai_summary': instance.aiSummary,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

ComparisonPhotoEntry _$ComparisonPhotoEntryFromJson(
  Map<String, dynamic> json,
) => ComparisonPhotoEntry(
  photoId: json['photo_id'] as String,
  order: (json['order'] as num).toInt(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$ComparisonPhotoEntryToJson(
  ComparisonPhotoEntry instance,
) => <String, dynamic>{
  'photo_id': instance.photoId,
  'order': instance.order,
  'label': instance.label,
};

PhotoStats _$PhotoStatsFromJson(Map<String, dynamic> json) => PhotoStats(
  userId: json['user_id'] as String,
  totalPhotos: (json['total_photos'] as num?)?.toInt() ?? 0,
  viewTypesCaptured: (json['view_types_captured'] as num?)?.toInt() ?? 0,
  firstPhotoDate: json['first_photo_date'] == null
      ? null
      : DateTime.parse(json['first_photo_date'] as String),
  latestPhotoDate: json['latest_photo_date'] == null
      ? null
      : DateTime.parse(json['latest_photo_date'] as String),
  daysWithPhotos: (json['days_with_photos'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PhotoStatsToJson(PhotoStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'total_photos': instance.totalPhotos,
      'view_types_captured': instance.viewTypesCaptured,
      'first_photo_date': instance.firstPhotoDate?.toIso8601String(),
      'latest_photo_date': instance.latestPhotoDate?.toIso8601String(),
      'days_with_photos': instance.daysWithPhotos,
    };
