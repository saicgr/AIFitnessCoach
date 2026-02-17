import 'package:json_annotation/json_annotation.dart';

part 'progress_photos.g.dart';

/// View type for progress photos
enum PhotoViewType {
  front('front', 'Front'),
  sideLeft('side_left', 'Left Side'),
  sideRight('side_right', 'Right Side'),
  back('back', 'Back'),
  legs('legs', 'Legs'),
  glutes('glutes', 'Glutes'),
  arms('arms', 'Arms'),
  abs('abs', 'Abs'),
  chest('chest', 'Chest'),
  custom('custom', 'Other');

  final String value;
  final String displayName;

  const PhotoViewType(this.value, this.displayName);

  static PhotoViewType fromString(String value) {
    return PhotoViewType.values.firstWhere(
      (v) => v.value == value || v.name == value,
      orElse: () => PhotoViewType.front,
    );
  }
}

/// Photo visibility options
enum PhotoVisibility {
  private('private'),
  shared('shared'),
  public('public');

  final String value;

  const PhotoVisibility(this.value);

  static PhotoVisibility fromString(String value) {
    return PhotoVisibility.values.firstWhere(
      (v) => v.value == value,
      orElse: () => PhotoVisibility.private,
    );
  }
}

/// Individual progress photo
@JsonSerializable()
class ProgressPhoto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'photo_url')
  final String photoUrl;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'view_type')
  final String viewType;
  @JsonKey(name: 'taken_at')
  final DateTime takenAt;
  @JsonKey(name: 'body_weight_kg')
  final double? bodyWeightKg;
  final String? notes;
  @JsonKey(name: 'measurement_id')
  final String? measurementId;
  @JsonKey(name: 'is_comparison_ready')
  final bool isComparisonReady;
  final String visibility;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.photoUrl,
    this.thumbnailUrl,
    required this.viewType,
    required this.takenAt,
    this.bodyWeightKg,
    this.notes,
    this.measurementId,
    this.isComparisonReady = true,
    this.visibility = 'private',
    required this.createdAt,
  });

  /// Get the view type enum
  PhotoViewType get viewTypeEnum => PhotoViewType.fromString(viewType);

  /// Get visibility enum
  PhotoVisibility get visibilityEnum => PhotoVisibility.fromString(visibility);

  /// Format weight for display
  String? get formattedWeight {
    if (bodyWeightKg == null) return null;
    return '${bodyWeightKg!.toStringAsFixed(1)} kg';
  }

  /// Format date for display
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(takenAt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = diff.inDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) =>
      _$ProgressPhotoFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressPhotoToJson(this);

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    String? thumbnailUrl,
    String? viewType,
    DateTime? takenAt,
    double? bodyWeightKg,
    String? notes,
    String? measurementId,
    bool? isComparisonReady,
    String? visibility,
    DateTime? createdAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewType: viewType ?? this.viewType,
      takenAt: takenAt ?? this.takenAt,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      notes: notes ?? this.notes,
      measurementId: measurementId ?? this.measurementId,
      isComparisonReady: isComparisonReady ?? this.isComparisonReady,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Photo comparison (before/after or N-photo)
@JsonSerializable()
class PhotoComparison {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'before_photo')
  final ProgressPhoto beforePhoto;
  @JsonKey(name: 'after_photo')
  final ProgressPhoto afterPhoto;
  final String? title;
  final String? description;
  @JsonKey(name: 'weight_change_kg')
  final double? weightChangeKg;
  @JsonKey(name: 'days_between')
  final int? daysBetween;
  final String visibility;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // N-photo comparison fields
  @JsonKey(name: 'photos_json')
  final List<ComparisonPhotoEntry>? photosJson;
  final String? layout;
  @JsonKey(name: 'settings_json')
  final Map<String, dynamic>? settingsJson;
  @JsonKey(name: 'exported_image_url')
  final String? exportedImageUrl;
  @JsonKey(name: 'ai_summary')
  final String? aiSummary;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const PhotoComparison({
    required this.id,
    required this.userId,
    required this.beforePhoto,
    required this.afterPhoto,
    this.title,
    this.description,
    this.weightChangeKg,
    this.daysBetween,
    this.visibility = 'private',
    required this.createdAt,
    this.photosJson,
    this.layout,
    this.settingsJson,
    this.exportedImageUrl,
    this.aiSummary,
    this.updatedAt,
  });

  /// Get formatted weight change
  String? get formattedWeightChange {
    if (weightChangeKg == null) return null;
    final sign = weightChangeKg! > 0 ? '+' : '';
    return '$sign${weightChangeKg!.toStringAsFixed(1)} kg';
  }

  /// Get formatted duration
  String? get formattedDuration {
    if (daysBetween == null) return null;
    if (daysBetween! < 7) {
      return '$daysBetween day${daysBetween! > 1 ? 's' : ''}';
    } else if (daysBetween! < 30) {
      final weeks = daysBetween! ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else if (daysBetween! < 365) {
      final months = daysBetween! ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = daysBetween! ~/ 365;
      return '$years year${years > 1 ? 's' : ''}';
    }
  }

  /// Get progress description
  String get progressDescription {
    final parts = <String>[];
    if (formattedDuration != null) {
      parts.add(formattedDuration!);
    }
    if (formattedWeightChange != null) {
      parts.add(formattedWeightChange!);
    }
    return parts.isEmpty ? 'Progress comparison' : parts.join(' • ');
  }

  /// Get all photos in this comparison (ordered)
  List<ProgressPhoto> get allPhotos {
    if (photosJson != null && photosJson!.isNotEmpty) {
      // For N-photo comparisons, we'd need resolved photos
      // Fall back to before/after for backward compat
      return [beforePhoto, afterPhoto];
    }
    return [beforePhoto, afterPhoto];
  }

  PhotoComparison copyWith({
    String? id,
    String? userId,
    ProgressPhoto? beforePhoto,
    ProgressPhoto? afterPhoto,
    String? title,
    String? description,
    double? weightChangeKg,
    int? daysBetween,
    String? visibility,
    DateTime? createdAt,
    List<ComparisonPhotoEntry>? photosJson,
    String? layout,
    Map<String, dynamic>? settingsJson,
    String? exportedImageUrl,
    String? aiSummary,
    DateTime? updatedAt,
  }) {
    return PhotoComparison(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      beforePhoto: beforePhoto ?? this.beforePhoto,
      afterPhoto: afterPhoto ?? this.afterPhoto,
      title: title ?? this.title,
      description: description ?? this.description,
      weightChangeKg: weightChangeKg ?? this.weightChangeKg,
      daysBetween: daysBetween ?? this.daysBetween,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      photosJson: photosJson ?? this.photosJson,
      layout: layout ?? this.layout,
      settingsJson: settingsJson ?? this.settingsJson,
      exportedImageUrl: exportedImageUrl ?? this.exportedImageUrl,
      aiSummary: aiSummary ?? this.aiSummary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PhotoComparison.fromJson(Map<String, dynamic> json) =>
      _$PhotoComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoComparisonToJson(this);
}

/// Entry in the photos_json array for N-photo comparisons
@JsonSerializable()
class ComparisonPhotoEntry {
  @JsonKey(name: 'photo_id')
  final String photoId;
  final int order;
  final String? label;

  const ComparisonPhotoEntry({
    required this.photoId,
    required this.order,
    this.label,
  });

  factory ComparisonPhotoEntry.fromJson(Map<String, dynamic> json) =>
      _$ComparisonPhotoEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ComparisonPhotoEntryToJson(this);
}

/// Settings for comparison customization (stored in settings_json)
class ComparisonSettings {
  final String layout;
  final bool showLogo;
  final double logoDx;
  final double logoDy;
  final double logoScale;
  final bool showStats;
  final bool showDates;
  final bool showAiSummary;
  final String backgroundColor;
  final String exportAspectRatio;
  final bool backgroundRemoved;
  final Map<int, List<double>> datePositions;
  final List<double>? statsPosition;
  final List<String> enabledStatCategories;
  final bool showPhotoWeights;
  final String datePosition; // 'left', 'center', 'right'
  final String photoShape; // 'rectangle', 'squircle', 'circle'
  final double squircleRadius;
  final bool photoBorderEnabled;
  final String photoBorderColor;
  final double photoBorderWidth;
  final double photoSpacing;

  const ComparisonSettings({
    this.layout = 'side_by_side',
    this.showLogo = true,
    this.logoDx = 16,
    this.logoDy = 16,
    this.logoScale = 1.0,
    this.showStats = true,
    this.showDates = true,
    this.showAiSummary = false,
    this.backgroundColor = '#000000',
    this.exportAspectRatio = '1:1',
    this.backgroundRemoved = false,
    this.datePositions = const {},
    this.statsPosition,
    this.enabledStatCategories = const ['duration', 'weight'],
    this.showPhotoWeights = true,
    this.datePosition = 'left',
    this.photoShape = 'rectangle',
    this.squircleRadius = 12.0,
    this.photoBorderEnabled = false,
    this.photoBorderColor = '#FFFFFF',
    this.photoBorderWidth = 2.0,
    this.photoSpacing = 2.0,
  });

  Map<String, dynamic> toJson() => {
    'layout': layout,
    'showLogo': showLogo,
    'logoPosition': {'dx': logoDx, 'dy': logoDy},
    'logoScale': logoScale,
    'showStats': showStats,
    'showDates': showDates,
    'showAiSummary': showAiSummary,
    'backgroundColor': backgroundColor,
    'exportAspectRatio': exportAspectRatio,
    'backgroundRemoved': backgroundRemoved,
    if (datePositions.isNotEmpty)
      'datePositions': datePositions.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    if (statsPosition != null) 'statsPosition': statsPosition,
    'enabledStatCategories': enabledStatCategories,
    'showPhotoWeights': showPhotoWeights,
    'datePosition': datePosition,
    'photoShape': photoShape,
    'squircleRadius': squircleRadius,
    'photoBorderEnabled': photoBorderEnabled,
    'photoBorderColor': photoBorderColor,
    'photoBorderWidth': photoBorderWidth,
    'photoSpacing': photoSpacing,
  };

  factory ComparisonSettings.fromJson(Map<String, dynamic> json) {
    final logoPos = json['logoPosition'] as Map<String, dynamic>?;

    // Parse datePositions
    final rawDatePos = json['datePositions'] as Map<String, dynamic>?;
    final datePositions = <int, List<double>>{};
    if (rawDatePos != null) {
      for (final entry in rawDatePos.entries) {
        final key = int.tryParse(entry.key);
        if (key != null && entry.value is List) {
          datePositions[key] = (entry.value as List)
              .map((e) => (e as num).toDouble())
              .toList();
        }
      }
    }

    // Parse statsPosition
    final rawStatsPos = json['statsPosition'] as List?;
    final statsPosition = rawStatsPos
        ?.map((e) => (e as num).toDouble())
        .toList();

    // Parse enabledStatCategories
    final rawCategories = json['enabledStatCategories'] as List?;
    final enabledStatCategories = rawCategories
        ?.map((e) => e as String)
        .toList() ?? const ['duration', 'weight'];

    return ComparisonSettings(
      layout: json['layout'] as String? ?? 'side_by_side',
      showLogo: json['showLogo'] as bool? ?? true,
      logoDx: (logoPos?['dx'] as num?)?.toDouble() ?? 16,
      logoDy: (logoPos?['dy'] as num?)?.toDouble() ?? 16,
      logoScale: (json['logoScale'] as num?)?.toDouble() ?? 1.0,
      showStats: json['showStats'] as bool? ??
          json['showWeightChange'] as bool? ?? true,
      showDates: json['showDates'] as bool? ?? true,
      showAiSummary: json['showAiSummary'] as bool? ?? false,
      backgroundColor: json['backgroundColor'] as String? ?? '#000000',
      exportAspectRatio: json['exportAspectRatio'] as String? ?? '1:1',
      backgroundRemoved: json['backgroundRemoved'] as bool? ?? false,
      datePositions: datePositions,
      statsPosition: statsPosition,
      enabledStatCategories: enabledStatCategories,
      showPhotoWeights: json['showPhotoWeights'] as bool? ?? true,
      datePosition: json['datePosition'] as String? ?? 'left',
      photoShape: json['photoShape'] as String? ?? 'rectangle',
      squircleRadius: (json['squircleRadius'] as num?)?.toDouble() ?? 12.0,
      photoBorderEnabled: json['photoBorderEnabled'] as bool? ?? false,
      photoBorderColor: json['photoBorderColor'] as String? ?? '#FFFFFF',
      photoBorderWidth: (json['photoBorderWidth'] as num?)?.toDouble() ?? 2.0,
      photoSpacing: (json['photoSpacing'] as num?)?.toDouble() ?? 2.0,
    );
  }

  ComparisonSettings copyWith({
    String? layout,
    bool? showLogo,
    double? logoDx,
    double? logoDy,
    double? logoScale,
    bool? showStats,
    bool? showDates,
    bool? showAiSummary,
    String? backgroundColor,
    String? exportAspectRatio,
    bool? backgroundRemoved,
    Map<int, List<double>>? datePositions,
    List<double>? statsPosition,
    List<String>? enabledStatCategories,
    bool? showPhotoWeights,
    String? datePosition,
    String? photoShape,
    double? squircleRadius,
    bool? photoBorderEnabled,
    String? photoBorderColor,
    double? photoBorderWidth,
    double? photoSpacing,
  }) {
    return ComparisonSettings(
      layout: layout ?? this.layout,
      showLogo: showLogo ?? this.showLogo,
      logoDx: logoDx ?? this.logoDx,
      logoDy: logoDy ?? this.logoDy,
      logoScale: logoScale ?? this.logoScale,
      showStats: showStats ?? this.showStats,
      showDates: showDates ?? this.showDates,
      showAiSummary: showAiSummary ?? this.showAiSummary,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      exportAspectRatio: exportAspectRatio ?? this.exportAspectRatio,
      backgroundRemoved: backgroundRemoved ?? this.backgroundRemoved,
      datePositions: datePositions ?? this.datePositions,
      statsPosition: statsPosition ?? this.statsPosition,
      enabledStatCategories: enabledStatCategories ?? this.enabledStatCategories,
      showPhotoWeights: showPhotoWeights ?? this.showPhotoWeights,
      datePosition: datePosition ?? this.datePosition,
      photoShape: photoShape ?? this.photoShape,
      squircleRadius: squircleRadius ?? this.squircleRadius,
      photoBorderEnabled: photoBorderEnabled ?? this.photoBorderEnabled,
      photoBorderColor: photoBorderColor ?? this.photoBorderColor,
      photoBorderWidth: photoBorderWidth ?? this.photoBorderWidth,
      photoSpacing: photoSpacing ?? this.photoSpacing,
    );
  }
}

/// Photo statistics
@JsonSerializable()
class PhotoStats {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_photos')
  final int totalPhotos;
  @JsonKey(name: 'view_types_captured')
  final int viewTypesCaptured;
  @JsonKey(name: 'first_photo_date')
  final DateTime? firstPhotoDate;
  @JsonKey(name: 'latest_photo_date')
  final DateTime? latestPhotoDate;
  @JsonKey(name: 'days_with_photos')
  final int daysWithPhotos;

  const PhotoStats({
    required this.userId,
    this.totalPhotos = 0,
    this.viewTypesCaptured = 0,
    this.firstPhotoDate,
    this.latestPhotoDate,
    this.daysWithPhotos = 0,
  });

  /// Check if user has all 4 view types
  bool get hasAllViewTypes => viewTypesCaptured >= 4;

  /// Get tracking duration in days
  int? get trackingDays {
    if (firstPhotoDate == null) return null;
    return DateTime.now().difference(firstPhotoDate!).inDays;
  }

  /// Get formatted tracking duration
  String? get formattedTrackingDuration {
    final days = trackingDays;
    if (days == null) return null;

    if (days < 7) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (days < 30) {
      final weeks = days ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else if (days < 365) {
      final months = days ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = days ~/ 365;
      return '$years year${years > 1 ? 's' : ''}';
    }
  }

  factory PhotoStats.fromJson(Map<String, dynamic> json) =>
      _$PhotoStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoStatsToJson(this);
}

/// Data for creating a new progress photo
class ProgressPhotoCreate {
  final String userId;
  final String viewType;
  final DateTime? takenAt;
  final double? bodyWeightKg;
  final String? notes;
  final String? measurementId;
  final String visibility;

  const ProgressPhotoCreate({
    required this.userId,
    required this.viewType,
    this.takenAt,
    this.bodyWeightKg,
    this.notes,
    this.measurementId,
    this.visibility = 'private',
  });

  Map<String, String> toFormData() {
    final data = <String, String>{
      'user_id': userId,
      'view_type': viewType,
      'visibility': visibility,
    };

    if (takenAt != null) {
      data['taken_at'] = takenAt!.toIso8601String();
    }
    if (bodyWeightKg != null) {
      data['body_weight_kg'] = bodyWeightKg.toString();
    }
    if (notes != null) {
      data['notes'] = notes!;
    }
    if (measurementId != null) {
      data['measurement_id'] = measurementId!;
    }

    return data;
  }
}

/// Data for updating a progress photo
class ProgressPhotoUpdate {
  final String? notes;
  final double? bodyWeightKg;
  final bool? isComparisonReady;
  final String? visibility;

  const ProgressPhotoUpdate({
    this.notes,
    this.bodyWeightKg,
    this.isComparisonReady,
    this.visibility,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (notes != null) data['notes'] = notes;
    if (bodyWeightKg != null) data['body_weight_kg'] = bodyWeightKg;
    if (isComparisonReady != null) data['is_comparison_ready'] = isComparisonReady;
    if (visibility != null) data['visibility'] = visibility;

    return data;
  }
}

/// Data for creating a photo comparison
class PhotoComparisonCreate {
  final String userId;
  final String beforePhotoId;
  final String afterPhotoId;
  final String? title;
  final String? description;

  const PhotoComparisonCreate({
    required this.userId,
    required this.beforePhotoId,
    required this.afterPhotoId,
    this.title,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'before_photo_id': beforePhotoId,
      'after_photo_id': afterPhotoId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };
  }
}

/// Latest photos by view type
class LatestPhotosByView {
  final ProgressPhoto? front;
  final ProgressPhoto? sideLeft;
  final ProgressPhoto? sideRight;
  final ProgressPhoto? back;

  const LatestPhotosByView({
    this.front,
    this.sideLeft,
    this.sideRight,
    this.back,
  });

  factory LatestPhotosByView.fromJson(Map<String, dynamic> json) {
    return LatestPhotosByView(
      front: json['front'] != null
          ? ProgressPhoto.fromJson(json['front'] as Map<String, dynamic>)
          : null,
      sideLeft: json['side_left'] != null
          ? ProgressPhoto.fromJson(json['side_left'] as Map<String, dynamic>)
          : null,
      sideRight: json['side_right'] != null
          ? ProgressPhoto.fromJson(json['side_right'] as Map<String, dynamic>)
          : null,
      back: json['back'] != null
          ? ProgressPhoto.fromJson(json['back'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Get all available photos as a list
  List<ProgressPhoto> get allPhotos {
    return [front, sideLeft, sideRight, back].whereType<ProgressPhoto>().toList();
  }

  /// Check if a view type has a photo
  bool hasPhoto(PhotoViewType viewType) {
    switch (viewType) {
      case PhotoViewType.front:
        return front != null;
      case PhotoViewType.sideLeft:
        return sideLeft != null;
      case PhotoViewType.sideRight:
        return sideRight != null;
      case PhotoViewType.back:
        return back != null;
      default:
        return false;
    }
  }

  /// Get photo for view type
  ProgressPhoto? getPhoto(PhotoViewType viewType) {
    switch (viewType) {
      case PhotoViewType.front:
        return front;
      case PhotoViewType.sideLeft:
        return sideLeft;
      case PhotoViewType.sideRight:
        return sideRight;
      case PhotoViewType.back:
        return back;
      default:
        return null;
    }
  }

  /// Get missing view types
  List<PhotoViewType> get missingViewTypes {
    return PhotoViewType.values.where((v) => !hasPhoto(v)).toList();
  }

  /// Count of captured view types
  int get capturedCount =>
      [front, sideLeft, sideRight, back].where((p) => p != null).length;
}
