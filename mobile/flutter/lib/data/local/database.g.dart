// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedWorkoutsTable extends CachedWorkouts
    with TableInfo<$CachedWorkoutsTable, CachedWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exercisesJsonMeta = const VerificationMeta(
    'exercisesJson',
  );
  @override
  late final GeneratedColumn<String> exercisesJson = GeneratedColumn<String>(
    'exercises_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generationMethodMeta = const VerificationMeta(
    'generationMethod',
  );
  @override
  late final GeneratedColumn<String> generationMethod = GeneratedColumn<String>(
    'generation_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generationMetadataMeta =
      const VerificationMeta('generationMetadata');
  @override
  late final GeneratedColumn<String> generationMetadata =
      GeneratedColumn<String>(
        'generation_metadata',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    type,
    difficulty,
    scheduledDate,
    isCompleted,
    exercisesJson,
    durationMinutes,
    generationMethod,
    generationMetadata,
    cachedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('exercises_json')) {
      context.handle(
        _exercisesJsonMeta,
        exercisesJson.isAcceptableOrUnknown(
          data['exercises_json']!,
          _exercisesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exercisesJsonMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('generation_method')) {
      context.handle(
        _generationMethodMeta,
        generationMethod.isAcceptableOrUnknown(
          data['generation_method']!,
          _generationMethodMeta,
        ),
      );
    }
    if (data.containsKey('generation_metadata')) {
      context.handle(
        _generationMetadataMeta,
        generationMetadata.isAcceptableOrUnknown(
          data['generation_metadata']!,
          _generationMetadataMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      exercisesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercises_json'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      generationMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generation_method'],
      ),
      generationMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}generation_metadata'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $CachedWorkoutsTable createAlias(String alias) {
    return $CachedWorkoutsTable(attachedDatabase, alias);
  }
}

class CachedWorkout extends DataClass implements Insertable<CachedWorkout> {
  final String id;
  final String userId;
  final String? name;
  final String? type;
  final String? difficulty;
  final String? scheduledDate;
  final bool isCompleted;
  final String exercisesJson;
  final int? durationMinutes;
  final String? generationMethod;
  final String? generationMetadata;
  final DateTime cachedAt;
  final String syncStatus;
  const CachedWorkout({
    required this.id,
    required this.userId,
    this.name,
    this.type,
    this.difficulty,
    this.scheduledDate,
    required this.isCompleted,
    required this.exercisesJson,
    this.durationMinutes,
    this.generationMethod,
    this.generationMetadata,
    required this.cachedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<String>(scheduledDate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['exercises_json'] = Variable<String>(exercisesJson);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || generationMethod != null) {
      map['generation_method'] = Variable<String>(generationMethod);
    }
    if (!nullToAbsent || generationMetadata != null) {
      map['generation_metadata'] = Variable<String>(generationMetadata);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  CachedWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return CachedWorkoutsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      isCompleted: Value(isCompleted),
      exercisesJson: Value(exercisesJson),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      generationMethod: generationMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(generationMethod),
      generationMetadata: generationMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(generationMetadata),
      cachedAt: Value(cachedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory CachedWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWorkout(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      scheduledDate: serializer.fromJson<String?>(json['scheduledDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      exercisesJson: serializer.fromJson<String>(json['exercisesJson']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      generationMethod: serializer.fromJson<String?>(json['generationMethod']),
      generationMetadata: serializer.fromJson<String?>(
        json['generationMetadata'],
      ),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String?>(type),
      'difficulty': serializer.toJson<String?>(difficulty),
      'scheduledDate': serializer.toJson<String?>(scheduledDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'exercisesJson': serializer.toJson<String>(exercisesJson),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'generationMethod': serializer.toJson<String?>(generationMethod),
      'generationMetadata': serializer.toJson<String?>(generationMetadata),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  CachedWorkout copyWith({
    String? id,
    String? userId,
    Value<String?> name = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> difficulty = const Value.absent(),
    Value<String?> scheduledDate = const Value.absent(),
    bool? isCompleted,
    String? exercisesJson,
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> generationMethod = const Value.absent(),
    Value<String?> generationMetadata = const Value.absent(),
    DateTime? cachedAt,
    String? syncStatus,
  }) => CachedWorkout(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name.present ? name.value : this.name,
    type: type.present ? type.value : this.type,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    isCompleted: isCompleted ?? this.isCompleted,
    exercisesJson: exercisesJson ?? this.exercisesJson,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    generationMethod: generationMethod.present
        ? generationMethod.value
        : this.generationMethod,
    generationMetadata: generationMetadata.present
        ? generationMetadata.value
        : this.generationMetadata,
    cachedAt: cachedAt ?? this.cachedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CachedWorkout copyWithCompanion(CachedWorkoutsCompanion data) {
    return CachedWorkout(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      exercisesJson: data.exercisesJson.present
          ? data.exercisesJson.value
          : this.exercisesJson,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      generationMethod: data.generationMethod.present
          ? data.generationMethod.value
          : this.generationMethod,
      generationMetadata: data.generationMetadata.present
          ? data.generationMetadata.value
          : this.generationMetadata,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkout(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('difficulty: $difficulty, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('generationMethod: $generationMethod, ')
          ..write('generationMetadata: $generationMetadata, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    type,
    difficulty,
    scheduledDate,
    isCompleted,
    exercisesJson,
    durationMinutes,
    generationMethod,
    generationMetadata,
    cachedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWorkout &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.difficulty == this.difficulty &&
          other.scheduledDate == this.scheduledDate &&
          other.isCompleted == this.isCompleted &&
          other.exercisesJson == this.exercisesJson &&
          other.durationMinutes == this.durationMinutes &&
          other.generationMethod == this.generationMethod &&
          other.generationMetadata == this.generationMetadata &&
          other.cachedAt == this.cachedAt &&
          other.syncStatus == this.syncStatus);
}

class CachedWorkoutsCompanion extends UpdateCompanion<CachedWorkout> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> name;
  final Value<String?> type;
  final Value<String?> difficulty;
  final Value<String?> scheduledDate;
  final Value<bool> isCompleted;
  final Value<String> exercisesJson;
  final Value<int?> durationMinutes;
  final Value<String?> generationMethod;
  final Value<String?> generationMetadata;
  final Value<DateTime> cachedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const CachedWorkoutsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.generationMethod = const Value.absent(),
    this.generationMetadata = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWorkoutsCompanion.insert({
    required String id,
    required String userId,
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required String exercisesJson,
    this.durationMinutes = const Value.absent(),
    this.generationMethod = const Value.absent(),
    this.generationMetadata = const Value.absent(),
    required DateTime cachedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       exercisesJson = Value(exercisesJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedWorkout> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? difficulty,
    Expression<String>? scheduledDate,
    Expression<bool>? isCompleted,
    Expression<String>? exercisesJson,
    Expression<int>? durationMinutes,
    Expression<String>? generationMethod,
    Expression<String>? generationMetadata,
    Expression<DateTime>? cachedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (difficulty != null) 'difficulty': difficulty,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (exercisesJson != null) 'exercises_json': exercisesJson,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (generationMethod != null) 'generation_method': generationMethod,
      if (generationMetadata != null) 'generation_metadata': generationMetadata,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWorkoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? name,
    Value<String?>? type,
    Value<String?>? difficulty,
    Value<String?>? scheduledDate,
    Value<bool>? isCompleted,
    Value<String>? exercisesJson,
    Value<int?>? durationMinutes,
    Value<String?>? generationMethod,
    Value<String?>? generationMetadata,
    Value<DateTime>? cachedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return CachedWorkoutsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      generationMethod: generationMethod ?? this.generationMethod,
      generationMetadata: generationMetadata ?? this.generationMetadata,
      cachedAt: cachedAt ?? this.cachedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (exercisesJson.present) {
      map['exercises_json'] = Variable<String>(exercisesJson.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (generationMethod.present) {
      map['generation_method'] = Variable<String>(generationMethod.value);
    }
    if (generationMetadata.present) {
      map['generation_metadata'] = Variable<String>(generationMetadata.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('difficulty: $difficulty, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('generationMethod: $generationMethod, ')
          ..write('generationMetadata: $generationMetadata, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedExercisesTable extends CachedExercises
    with TableInfo<$CachedExercisesTable, CachedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyPartMeta = const VerificationMeta(
    'bodyPart',
  );
  @override
  late final GeneratedColumn<String> bodyPart = GeneratedColumn<String>(
    'body_part',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMuscleMeta = const VerificationMeta(
    'targetMuscle',
  );
  @override
  late final GeneratedColumn<String> targetMuscle = GeneratedColumn<String>(
    'target_muscle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryMuscleMeta = const VerificationMeta(
    'primaryMuscle',
  );
  @override
  late final GeneratedColumn<String> primaryMuscle = GeneratedColumn<String>(
    'primary_muscle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryMusclesMeta = const VerificationMeta(
    'secondaryMuscles',
  );
  @override
  late final GeneratedColumn<String> secondaryMuscles = GeneratedColumn<String>(
    'secondary_muscles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageS3PathMeta = const VerificationMeta(
    'imageS3Path',
  );
  @override
  late final GeneratedColumn<String> imageS3Path = GeneratedColumn<String>(
    'image_s3_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyNumMeta = const VerificationMeta(
    'difficultyNum',
  );
  @override
  late final GeneratedColumn<int> difficultyNum = GeneratedColumn<int>(
    'difficulty_num',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bodyPart,
    equipment,
    targetMuscle,
    primaryMuscle,
    secondaryMuscles,
    videoUrl,
    imageS3Path,
    instructions,
    difficulty,
    difficultyNum,
    cachedAt,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('body_part')) {
      context.handle(
        _bodyPartMeta,
        bodyPart.isAcceptableOrUnknown(data['body_part']!, _bodyPartMeta),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('target_muscle')) {
      context.handle(
        _targetMuscleMeta,
        targetMuscle.isAcceptableOrUnknown(
          data['target_muscle']!,
          _targetMuscleMeta,
        ),
      );
    }
    if (data.containsKey('primary_muscle')) {
      context.handle(
        _primaryMuscleMeta,
        primaryMuscle.isAcceptableOrUnknown(
          data['primary_muscle']!,
          _primaryMuscleMeta,
        ),
      );
    }
    if (data.containsKey('secondary_muscles')) {
      context.handle(
        _secondaryMusclesMeta,
        secondaryMuscles.isAcceptableOrUnknown(
          data['secondary_muscles']!,
          _secondaryMusclesMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('image_s3_path')) {
      context.handle(
        _imageS3PathMeta,
        imageS3Path.isAcceptableOrUnknown(
          data['image_s3_path']!,
          _imageS3PathMeta,
        ),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('difficulty_num')) {
      context.handle(
        _difficultyNumMeta,
        difficultyNum.isAcceptableOrUnknown(
          data['difficulty_num']!,
          _difficultyNumMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bodyPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_part'],
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      ),
      targetMuscle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_muscle'],
      ),
      primaryMuscle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscle'],
      ),
      secondaryMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      imageS3Path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_s3_path'],
      ),
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      difficultyNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty_num'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $CachedExercisesTable createAlias(String alias) {
    return $CachedExercisesTable(attachedDatabase, alias);
  }
}

class CachedExercise extends DataClass implements Insertable<CachedExercise> {
  final String id;
  final String name;
  final String? bodyPart;
  final String? equipment;
  final String? targetMuscle;
  final String? primaryMuscle;
  final String? secondaryMuscles;
  final String? videoUrl;
  final String? imageS3Path;
  final String? instructions;
  final String? difficulty;
  final int? difficultyNum;
  final DateTime cachedAt;
  final bool isFavorite;
  const CachedExercise({
    required this.id,
    required this.name,
    this.bodyPart,
    this.equipment,
    this.targetMuscle,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.videoUrl,
    this.imageS3Path,
    this.instructions,
    this.difficulty,
    this.difficultyNum,
    required this.cachedAt,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || bodyPart != null) {
      map['body_part'] = Variable<String>(bodyPart);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || targetMuscle != null) {
      map['target_muscle'] = Variable<String>(targetMuscle);
    }
    if (!nullToAbsent || primaryMuscle != null) {
      map['primary_muscle'] = Variable<String>(primaryMuscle);
    }
    if (!nullToAbsent || secondaryMuscles != null) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || imageS3Path != null) {
      map['image_s3_path'] = Variable<String>(imageS3Path);
    }
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || difficultyNum != null) {
      map['difficulty_num'] = Variable<int>(difficultyNum);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  CachedExercisesCompanion toCompanion(bool nullToAbsent) {
    return CachedExercisesCompanion(
      id: Value(id),
      name: Value(name),
      bodyPart: bodyPart == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyPart),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      targetMuscle: targetMuscle == null && nullToAbsent
          ? const Value.absent()
          : Value(targetMuscle),
      primaryMuscle: primaryMuscle == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryMuscle),
      secondaryMuscles: secondaryMuscles == null && nullToAbsent
          ? const Value.absent()
          : Value(secondaryMuscles),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      imageS3Path: imageS3Path == null && nullToAbsent
          ? const Value.absent()
          : Value(imageS3Path),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      difficultyNum: difficultyNum == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyNum),
      cachedAt: Value(cachedAt),
      isFavorite: Value(isFavorite),
    );
  }

  factory CachedExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bodyPart: serializer.fromJson<String?>(json['bodyPart']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      targetMuscle: serializer.fromJson<String?>(json['targetMuscle']),
      primaryMuscle: serializer.fromJson<String?>(json['primaryMuscle']),
      secondaryMuscles: serializer.fromJson<String?>(json['secondaryMuscles']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      imageS3Path: serializer.fromJson<String?>(json['imageS3Path']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      difficultyNum: serializer.fromJson<int?>(json['difficultyNum']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bodyPart': serializer.toJson<String?>(bodyPart),
      'equipment': serializer.toJson<String?>(equipment),
      'targetMuscle': serializer.toJson<String?>(targetMuscle),
      'primaryMuscle': serializer.toJson<String?>(primaryMuscle),
      'secondaryMuscles': serializer.toJson<String?>(secondaryMuscles),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'imageS3Path': serializer.toJson<String?>(imageS3Path),
      'instructions': serializer.toJson<String?>(instructions),
      'difficulty': serializer.toJson<String?>(difficulty),
      'difficultyNum': serializer.toJson<int?>(difficultyNum),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  CachedExercise copyWith({
    String? id,
    String? name,
    Value<String?> bodyPart = const Value.absent(),
    Value<String?> equipment = const Value.absent(),
    Value<String?> targetMuscle = const Value.absent(),
    Value<String?> primaryMuscle = const Value.absent(),
    Value<String?> secondaryMuscles = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> imageS3Path = const Value.absent(),
    Value<String?> instructions = const Value.absent(),
    Value<String?> difficulty = const Value.absent(),
    Value<int?> difficultyNum = const Value.absent(),
    DateTime? cachedAt,
    bool? isFavorite,
  }) => CachedExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    bodyPart: bodyPart.present ? bodyPart.value : this.bodyPart,
    equipment: equipment.present ? equipment.value : this.equipment,
    targetMuscle: targetMuscle.present ? targetMuscle.value : this.targetMuscle,
    primaryMuscle: primaryMuscle.present
        ? primaryMuscle.value
        : this.primaryMuscle,
    secondaryMuscles: secondaryMuscles.present
        ? secondaryMuscles.value
        : this.secondaryMuscles,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    imageS3Path: imageS3Path.present ? imageS3Path.value : this.imageS3Path,
    instructions: instructions.present ? instructions.value : this.instructions,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    difficultyNum: difficultyNum.present
        ? difficultyNum.value
        : this.difficultyNum,
    cachedAt: cachedAt ?? this.cachedAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  CachedExercise copyWithCompanion(CachedExercisesCompanion data) {
    return CachedExercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bodyPart: data.bodyPart.present ? data.bodyPart.value : this.bodyPart,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      targetMuscle: data.targetMuscle.present
          ? data.targetMuscle.value
          : this.targetMuscle,
      primaryMuscle: data.primaryMuscle.present
          ? data.primaryMuscle.value
          : this.primaryMuscle,
      secondaryMuscles: data.secondaryMuscles.present
          ? data.secondaryMuscles.value
          : this.secondaryMuscles,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      imageS3Path: data.imageS3Path.present
          ? data.imageS3Path.value
          : this.imageS3Path,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      difficultyNum: data.difficultyNum.present
          ? data.difficultyNum.value
          : this.difficultyNum,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('targetMuscle: $targetMuscle, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('imageS3Path: $imageS3Path, ')
          ..write('instructions: $instructions, ')
          ..write('difficulty: $difficulty, ')
          ..write('difficultyNum: $difficultyNum, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    bodyPart,
    equipment,
    targetMuscle,
    primaryMuscle,
    secondaryMuscles,
    videoUrl,
    imageS3Path,
    instructions,
    difficulty,
    difficultyNum,
    cachedAt,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.bodyPart == this.bodyPart &&
          other.equipment == this.equipment &&
          other.targetMuscle == this.targetMuscle &&
          other.primaryMuscle == this.primaryMuscle &&
          other.secondaryMuscles == this.secondaryMuscles &&
          other.videoUrl == this.videoUrl &&
          other.imageS3Path == this.imageS3Path &&
          other.instructions == this.instructions &&
          other.difficulty == this.difficulty &&
          other.difficultyNum == this.difficultyNum &&
          other.cachedAt == this.cachedAt &&
          other.isFavorite == this.isFavorite);
}

class CachedExercisesCompanion extends UpdateCompanion<CachedExercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> bodyPart;
  final Value<String?> equipment;
  final Value<String?> targetMuscle;
  final Value<String?> primaryMuscle;
  final Value<String?> secondaryMuscles;
  final Value<String?> videoUrl;
  final Value<String?> imageS3Path;
  final Value<String?> instructions;
  final Value<String?> difficulty;
  final Value<int?> difficultyNum;
  final Value<DateTime> cachedAt;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const CachedExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bodyPart = const Value.absent(),
    this.equipment = const Value.absent(),
    this.targetMuscle = const Value.absent(),
    this.primaryMuscle = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.imageS3Path = const Value.absent(),
    this.instructions = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.difficultyNum = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExercisesCompanion.insert({
    required String id,
    required String name,
    this.bodyPart = const Value.absent(),
    this.equipment = const Value.absent(),
    this.targetMuscle = const Value.absent(),
    this.primaryMuscle = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.imageS3Path = const Value.absent(),
    this.instructions = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.difficultyNum = const Value.absent(),
    required DateTime cachedAt,
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedExercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bodyPart,
    Expression<String>? equipment,
    Expression<String>? targetMuscle,
    Expression<String>? primaryMuscle,
    Expression<String>? secondaryMuscles,
    Expression<String>? videoUrl,
    Expression<String>? imageS3Path,
    Expression<String>? instructions,
    Expression<String>? difficulty,
    Expression<int>? difficultyNum,
    Expression<DateTime>? cachedAt,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bodyPart != null) 'body_part': bodyPart,
      if (equipment != null) 'equipment': equipment,
      if (targetMuscle != null) 'target_muscle': targetMuscle,
      if (primaryMuscle != null) 'primary_muscle': primaryMuscle,
      if (secondaryMuscles != null) 'secondary_muscles': secondaryMuscles,
      if (videoUrl != null) 'video_url': videoUrl,
      if (imageS3Path != null) 'image_s3_path': imageS3Path,
      if (instructions != null) 'instructions': instructions,
      if (difficulty != null) 'difficulty': difficulty,
      if (difficultyNum != null) 'difficulty_num': difficultyNum,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? bodyPart,
    Value<String?>? equipment,
    Value<String?>? targetMuscle,
    Value<String?>? primaryMuscle,
    Value<String?>? secondaryMuscles,
    Value<String?>? videoUrl,
    Value<String?>? imageS3Path,
    Value<String?>? instructions,
    Value<String?>? difficulty,
    Value<int?>? difficultyNum,
    Value<DateTime>? cachedAt,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return CachedExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      videoUrl: videoUrl ?? this.videoUrl,
      imageS3Path: imageS3Path ?? this.imageS3Path,
      instructions: instructions ?? this.instructions,
      difficulty: difficulty ?? this.difficulty,
      difficultyNum: difficultyNum ?? this.difficultyNum,
      cachedAt: cachedAt ?? this.cachedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bodyPart.present) {
      map['body_part'] = Variable<String>(bodyPart.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (targetMuscle.present) {
      map['target_muscle'] = Variable<String>(targetMuscle.value);
    }
    if (primaryMuscle.present) {
      map['primary_muscle'] = Variable<String>(primaryMuscle.value);
    }
    if (secondaryMuscles.present) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (imageS3Path.present) {
      map['image_s3_path'] = Variable<String>(imageS3Path.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (difficultyNum.present) {
      map['difficulty_num'] = Variable<int>(difficultyNum.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('targetMuscle: $targetMuscle, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('imageS3Path: $imageS3Path, ')
          ..write('instructions: $instructions, ')
          ..write('difficulty: $difficulty, ')
          ..write('difficultyNum: $difficultyNum, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedUserProfilesTable extends CachedUserProfiles
    with TableInfo<$CachedUserProfilesTable, CachedUserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>(
        'last_modified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileJson,
    cachedAt,
    lastModifiedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedUserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $CachedUserProfilesTable createAlias(String alias) {
    return $CachedUserProfilesTable(attachedDatabase, alias);
  }
}

class CachedUserProfile extends DataClass
    implements Insertable<CachedUserProfile> {
  final String id;
  final String profileJson;
  final DateTime cachedAt;
  final DateTime? lastModifiedAt;
  final String syncStatus;
  const CachedUserProfile({
    required this.id,
    required this.profileJson,
    required this.cachedAt,
    this.lastModifiedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_json'] = Variable<String>(profileJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  CachedUserProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedUserProfilesCompanion(
      id: Value(id),
      profileJson: Value(profileJson),
      cachedAt: Value(cachedAt),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory CachedUserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUserProfile(
      id: serializer.fromJson<String>(json['id']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastModifiedAt: serializer.fromJson<DateTime?>(json['lastModifiedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileJson': serializer.toJson<String>(profileJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastModifiedAt': serializer.toJson<DateTime?>(lastModifiedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  CachedUserProfile copyWith({
    String? id,
    String? profileJson,
    DateTime? cachedAt,
    Value<DateTime?> lastModifiedAt = const Value.absent(),
    String? syncStatus,
  }) => CachedUserProfile(
    id: id ?? this.id,
    profileJson: profileJson ?? this.profileJson,
    cachedAt: cachedAt ?? this.cachedAt,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CachedUserProfile copyWithCompanion(CachedUserProfilesCompanion data) {
    return CachedUserProfile(
      id: data.id.present ? data.id.value : this.id,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUserProfile(')
          ..write('id: $id, ')
          ..write('profileJson: $profileJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileJson, cachedAt, lastModifiedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUserProfile &&
          other.id == this.id &&
          other.profileJson == this.profileJson &&
          other.cachedAt == this.cachedAt &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.syncStatus == this.syncStatus);
}

class CachedUserProfilesCompanion extends UpdateCompanion<CachedUserProfile> {
  final Value<String> id;
  final Value<String> profileJson;
  final Value<DateTime> cachedAt;
  final Value<DateTime?> lastModifiedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const CachedUserProfilesCompanion({
    this.id = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUserProfilesCompanion.insert({
    required String id,
    required String profileJson,
    required DateTime cachedAt,
    this.lastModifiedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileJson = Value(profileJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedUserProfile> custom({
    Expression<String>? id,
    Expression<String>? profileJson,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileJson != null) 'profile_json': profileJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileJson,
    Value<DateTime>? cachedAt,
    Value<DateTime?>? lastModifiedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return CachedUserProfilesCompanion(
      id: id ?? this.id,
      profileJson: profileJson ?? this.profileJson,
      cachedAt: cachedAt ?? this.cachedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('profileJson: $profileJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWorkoutLogsTable extends CachedWorkoutLogs
    with TableInfo<$CachedWorkoutLogsTable, CachedWorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWorkoutLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsCompletedMeta = const VerificationMeta(
    'repsCompleted',
  );
  @override
  late final GeneratedColumn<int> repsCompleted = GeneratedColumn<int>(
    'reps_completed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setTypeMeta = const VerificationMeta(
    'setType',
  );
  @override
  late final GeneratedColumn<String> setType = GeneratedColumn<String>(
    'set_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('working'),
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncRetryCountMeta = const VerificationMeta(
    'syncRetryCount',
  );
  @override
  late final GeneratedColumn<int> syncRetryCount = GeneratedColumn<int>(
    'sync_retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    userId,
    exerciseId,
    exerciseName,
    setNumber,
    repsCompleted,
    weightKg,
    setType,
    rpe,
    rir,
    notes,
    completedAt,
    syncStatus,
    syncRetryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_workout_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWorkoutLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('reps_completed')) {
      context.handle(
        _repsCompletedMeta,
        repsCompleted.isAcceptableOrUnknown(
          data['reps_completed']!,
          _repsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('set_type')) {
      context.handle(
        _setTypeMeta,
        setType.isAcceptableOrUnknown(data['set_type']!, _setTypeMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_retry_count')) {
      context.handle(
        _syncRetryCountMeta,
        syncRetryCount.isAcceptableOrUnknown(
          data['sync_retry_count']!,
          _syncRetryCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWorkoutLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      ),
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      repsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps_completed'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      setType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_type'],
      )!,
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncRetryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_retry_count'],
      )!,
    );
  }

  @override
  $CachedWorkoutLogsTable createAlias(String alias) {
    return $CachedWorkoutLogsTable(attachedDatabase, alias);
  }
}

class CachedWorkoutLog extends DataClass
    implements Insertable<CachedWorkoutLog> {
  final String id;
  final String workoutId;
  final String userId;
  final String? exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? repsCompleted;
  final double? weightKg;
  final String setType;
  final int? rpe;
  final int? rir;
  final String? notes;
  final DateTime completedAt;
  final String syncStatus;
  final int syncRetryCount;
  const CachedWorkoutLog({
    required this.id,
    required this.workoutId,
    required this.userId,
    this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.repsCompleted,
    this.weightKg,
    required this.setType,
    this.rpe,
    this.rir,
    this.notes,
    required this.completedAt,
    required this.syncStatus,
    required this.syncRetryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    map['exercise_name'] = Variable<String>(exerciseName);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || repsCompleted != null) {
      map['reps_completed'] = Variable<int>(repsCompleted);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['set_type'] = Variable<String>(setType);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_retry_count'] = Variable<int>(syncRetryCount);
    return map;
  }

  CachedWorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return CachedWorkoutLogsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      userId: Value(userId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      exerciseName: Value(exerciseName),
      setNumber: Value(setNumber),
      repsCompleted: repsCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(repsCompleted),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      setType: Value(setType),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      completedAt: Value(completedAt),
      syncStatus: Value(syncStatus),
      syncRetryCount: Value(syncRetryCount),
    );
  }

  factory CachedWorkoutLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWorkoutLog(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      userId: serializer.fromJson<String>(json['userId']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      repsCompleted: serializer.fromJson<int?>(json['repsCompleted']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      setType: serializer.fromJson<String>(json['setType']),
      rpe: serializer.fromJson<int?>(json['rpe']),
      rir: serializer.fromJson<int?>(json['rir']),
      notes: serializer.fromJson<String?>(json['notes']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncRetryCount: serializer.fromJson<int>(json['syncRetryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'userId': serializer.toJson<String>(userId),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'setNumber': serializer.toJson<int>(setNumber),
      'repsCompleted': serializer.toJson<int?>(repsCompleted),
      'weightKg': serializer.toJson<double?>(weightKg),
      'setType': serializer.toJson<String>(setType),
      'rpe': serializer.toJson<int?>(rpe),
      'rir': serializer.toJson<int?>(rir),
      'notes': serializer.toJson<String?>(notes),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncRetryCount': serializer.toJson<int>(syncRetryCount),
    };
  }

  CachedWorkoutLog copyWith({
    String? id,
    String? workoutId,
    String? userId,
    Value<String?> exerciseId = const Value.absent(),
    String? exerciseName,
    int? setNumber,
    Value<int?> repsCompleted = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    String? setType,
    Value<int?> rpe = const Value.absent(),
    Value<int?> rir = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? completedAt,
    String? syncStatus,
    int? syncRetryCount,
  }) => CachedWorkoutLog(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    userId: userId ?? this.userId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    setNumber: setNumber ?? this.setNumber,
    repsCompleted: repsCompleted.present
        ? repsCompleted.value
        : this.repsCompleted,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    setType: setType ?? this.setType,
    rpe: rpe.present ? rpe.value : this.rpe,
    rir: rir.present ? rir.value : this.rir,
    notes: notes.present ? notes.value : this.notes,
    completedAt: completedAt ?? this.completedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncRetryCount: syncRetryCount ?? this.syncRetryCount,
  );
  CachedWorkoutLog copyWithCompanion(CachedWorkoutLogsCompanion data) {
    return CachedWorkoutLog(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      repsCompleted: data.repsCompleted.present
          ? data.repsCompleted.value
          : this.repsCompleted,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      setType: data.setType.present ? data.setType.value : this.setType,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
      notes: data.notes.present ? data.notes.value : this.notes,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncRetryCount: data.syncRetryCount.present
          ? data.syncRetryCount.value
          : this.syncRetryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutLog(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setNumber: $setNumber, ')
          ..write('repsCompleted: $repsCompleted, ')
          ..write('weightKg: $weightKg, ')
          ..write('setType: $setType, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncRetryCount: $syncRetryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    userId,
    exerciseId,
    exerciseName,
    setNumber,
    repsCompleted,
    weightKg,
    setType,
    rpe,
    rir,
    notes,
    completedAt,
    syncStatus,
    syncRetryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWorkoutLog &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.setNumber == this.setNumber &&
          other.repsCompleted == this.repsCompleted &&
          other.weightKg == this.weightKg &&
          other.setType == this.setType &&
          other.rpe == this.rpe &&
          other.rir == this.rir &&
          other.notes == this.notes &&
          other.completedAt == this.completedAt &&
          other.syncStatus == this.syncStatus &&
          other.syncRetryCount == this.syncRetryCount);
}

class CachedWorkoutLogsCompanion extends UpdateCompanion<CachedWorkoutLog> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> userId;
  final Value<String?> exerciseId;
  final Value<String> exerciseName;
  final Value<int> setNumber;
  final Value<int?> repsCompleted;
  final Value<double?> weightKg;
  final Value<String> setType;
  final Value<int?> rpe;
  final Value<int?> rir;
  final Value<String?> notes;
  final Value<DateTime> completedAt;
  final Value<String> syncStatus;
  final Value<int> syncRetryCount;
  final Value<int> rowid;
  const CachedWorkoutLogsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.repsCompleted = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.setType = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.notes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWorkoutLogsCompanion.insert({
    required String id,
    required String workoutId,
    required String userId,
    this.exerciseId = const Value.absent(),
    required String exerciseName,
    required int setNumber,
    this.repsCompleted = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.setType = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime completedAt,
    this.syncStatus = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutId = Value(workoutId),
       userId = Value(userId),
       exerciseName = Value(exerciseName),
       setNumber = Value(setNumber),
       completedAt = Value(completedAt);
  static Insertable<CachedWorkoutLog> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? userId,
    Expression<String>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? setNumber,
    Expression<int>? repsCompleted,
    Expression<double>? weightKg,
    Expression<String>? setType,
    Expression<int>? rpe,
    Expression<int>? rir,
    Expression<String>? notes,
    Expression<DateTime>? completedAt,
    Expression<String>? syncStatus,
    Expression<int>? syncRetryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (setNumber != null) 'set_number': setNumber,
      if (repsCompleted != null) 'reps_completed': repsCompleted,
      if (weightKg != null) 'weight_kg': weightKg,
      if (setType != null) 'set_type': setType,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
      if (notes != null) 'notes': notes,
      if (completedAt != null) 'completed_at': completedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncRetryCount != null) 'sync_retry_count': syncRetryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWorkoutLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutId,
    Value<String>? userId,
    Value<String?>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? setNumber,
    Value<int?>? repsCompleted,
    Value<double?>? weightKg,
    Value<String>? setType,
    Value<int?>? rpe,
    Value<int?>? rir,
    Value<String?>? notes,
    Value<DateTime>? completedAt,
    Value<String>? syncStatus,
    Value<int>? syncRetryCount,
    Value<int>? rowid,
  }) {
    return CachedWorkoutLogsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setNumber: setNumber ?? this.setNumber,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      weightKg: weightKg ?? this.weightKg,
      setType: setType ?? this.setType,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (repsCompleted.present) {
      map['reps_completed'] = Variable<int>(repsCompleted.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(setType.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncRetryCount.present) {
      map['sync_retry_count'] = Variable<int>(syncRetryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkoutLogsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setNumber: $setNumber, ')
          ..write('repsCompleted: $repsCompleted, ')
          ..write('weightKg: $weightKg, ')
          ..write('setType: $setType, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncRetryCount: $syncRetryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncQueueTable extends PendingSyncQueue
    with TableInfo<$PendingSyncQueueTable, PendingSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _httpMethodMeta = const VerificationMeta(
    'httpMethod',
  );
  @override
  late final GeneratedColumn<String> httpMethod = GeneratedColumn<String>(
    'http_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxRetriesMeta = const VerificationMeta(
    'maxRetries',
  );
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
    'max_retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _lastAttemptMeta = const VerificationMeta(
    'lastAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
    'last_attempt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    entityType,
    entityId,
    payload,
    httpMethod,
    endpoint,
    createdAt,
    retryCount,
    maxRetries,
    lastAttempt,
    lastError,
    status,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('http_method')) {
      context.handle(
        _httpMethodMeta,
        httpMethod.isAcceptableOrUnknown(data['http_method']!, _httpMethodMeta),
      );
    } else if (isInserting) {
      context.missing(_httpMethodMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('max_retries')) {
      context.handle(
        _maxRetriesMeta,
        maxRetries.isAcceptableOrUnknown(data['max_retries']!, _maxRetriesMeta),
      );
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
        _lastAttemptMeta,
        lastAttempt.isAcceptableOrUnknown(
          data['last_attempt']!,
          _lastAttemptMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      httpMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}http_method'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      maxRetries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_retries'],
      )!,
      lastAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $PendingSyncQueueTable createAlias(String alias) {
    return $PendingSyncQueueTable(attachedDatabase, alias);
  }
}

class PendingSyncQueueData extends DataClass
    implements Insertable<PendingSyncQueueData> {
  final int id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String payload;
  final String httpMethod;
  final String endpoint;
  final DateTime createdAt;
  final int retryCount;
  final int maxRetries;
  final DateTime? lastAttempt;
  final String? lastError;
  final String status;
  final int priority;
  const PendingSyncQueueData({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.httpMethod,
    required this.endpoint,
    required this.createdAt,
    required this.retryCount,
    required this.maxRetries,
    this.lastAttempt,
    this.lastError,
    required this.status,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['http_method'] = Variable<String>(httpMethod);
    map['endpoint'] = Variable<String>(endpoint);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    return map;
  }

  PendingSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncQueueCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      payload: Value(payload),
      httpMethod: Value(httpMethod),
      endpoint: Value(endpoint),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
      priority: Value(priority),
    );
  }

  factory PendingSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      httpMethod: serializer.fromJson<String>(json['httpMethod']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'httpMethod': serializer.toJson<String>(httpMethod),
      'endpoint': serializer.toJson<String>(endpoint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
    };
  }

  PendingSyncQueueData copyWith({
    int? id,
    String? operationType,
    String? entityType,
    String? entityId,
    String? payload,
    String? httpMethod,
    String? endpoint,
    DateTime? createdAt,
    int? retryCount,
    int? maxRetries,
    Value<DateTime?> lastAttempt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? status,
    int? priority,
  }) => PendingSyncQueueData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    httpMethod: httpMethod ?? this.httpMethod,
    endpoint: endpoint ?? this.endpoint,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    maxRetries: maxRetries ?? this.maxRetries,
    lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );
  PendingSyncQueueData copyWithCompanion(PendingSyncQueueCompanion data) {
    return PendingSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      httpMethod: data.httpMethod.present
          ? data.httpMethod.value
          : this.httpMethod,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      maxRetries: data.maxRetries.present
          ? data.maxRetries.value
          : this.maxRetries,
      lastAttempt: data.lastAttempt.present
          ? data.lastAttempt.value
          : this.lastAttempt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncQueueData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('endpoint: $endpoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    entityType,
    entityId,
    payload,
    httpMethod,
    endpoint,
    createdAt,
    retryCount,
    maxRetries,
    lastAttempt,
    lastError,
    status,
    priority,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncQueueData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.httpMethod == this.httpMethod &&
          other.endpoint == this.endpoint &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.lastAttempt == this.lastAttempt &&
          other.lastError == this.lastError &&
          other.status == this.status &&
          other.priority == this.priority);
}

class PendingSyncQueueCompanion extends UpdateCompanion<PendingSyncQueueData> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<String> httpMethod;
  final Value<String> endpoint;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<DateTime?> lastAttempt;
  final Value<String?> lastError;
  final Value<String> status;
  final Value<int> priority;
  const PendingSyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.httpMethod = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
  });
  PendingSyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    required String entityType,
    required String entityId,
    required String payload,
    required String httpMethod,
    required String endpoint,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
  }) : operationType = Value(operationType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payload = Value(payload),
       httpMethod = Value(httpMethod),
       endpoint = Value(endpoint),
       createdAt = Value(createdAt);
  static Insertable<PendingSyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<String>? httpMethod,
    Expression<String>? endpoint,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<DateTime>? lastAttempt,
    Expression<String>? lastError,
    Expression<String>? status,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (httpMethod != null) 'http_method': httpMethod,
      if (endpoint != null) 'endpoint': endpoint,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
    });
  }

  PendingSyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? payload,
    Value<String>? httpMethod,
    Value<String>? endpoint,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<int>? maxRetries,
    Value<DateTime?>? lastAttempt,
    Value<String?>? lastError,
    Value<String>? status,
    Value<int>? priority,
  }) {
    return PendingSyncQueueCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      httpMethod: httpMethod ?? this.httpMethod,
      endpoint: endpoint ?? this.endpoint,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (httpMethod.present) {
      map['http_method'] = Variable<String>(httpMethod.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('endpoint: $endpoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

class $CachedExerciseMediaTable extends CachedExerciseMedia
    with TableInfo<$CachedExerciseMediaTable, CachedExerciseMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExerciseMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    exerciseId,
    mediaType,
    remoteUrl,
    localPath,
    fileSizeBytes,
    downloadedAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_exercise_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExerciseMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteUrlMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, mediaType};
  @override
  CachedExerciseMediaData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExerciseMediaData(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $CachedExerciseMediaTable createAlias(String alias) {
    return $CachedExerciseMediaTable(attachedDatabase, alias);
  }
}

class CachedExerciseMediaData extends DataClass
    implements Insertable<CachedExerciseMediaData> {
  final String exerciseId;
  final String mediaType;
  final String remoteUrl;
  final String localPath;
  final int? fileSizeBytes;
  final DateTime downloadedAt;
  final DateTime lastAccessedAt;
  const CachedExerciseMediaData({
    required this.exerciseId,
    required this.mediaType,
    required this.remoteUrl,
    required this.localPath,
    this.fileSizeBytes,
    required this.downloadedAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['media_type'] = Variable<String>(mediaType);
    map['remote_url'] = Variable<String>(remoteUrl);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  CachedExerciseMediaCompanion toCompanion(bool nullToAbsent) {
    return CachedExerciseMediaCompanion(
      exerciseId: Value(exerciseId),
      mediaType: Value(mediaType),
      remoteUrl: Value(remoteUrl),
      localPath: Value(localPath),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      downloadedAt: Value(downloadedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory CachedExerciseMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExerciseMediaData(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      remoteUrl: serializer.fromJson<String>(json['remoteUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'mediaType': serializer.toJson<String>(mediaType),
      'remoteUrl': serializer.toJson<String>(remoteUrl),
      'localPath': serializer.toJson<String>(localPath),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  CachedExerciseMediaData copyWith({
    String? exerciseId,
    String? mediaType,
    String? remoteUrl,
    String? localPath,
    Value<int?> fileSizeBytes = const Value.absent(),
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
  }) => CachedExerciseMediaData(
    exerciseId: exerciseId ?? this.exerciseId,
    mediaType: mediaType ?? this.mediaType,
    remoteUrl: remoteUrl ?? this.remoteUrl,
    localPath: localPath ?? this.localPath,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  CachedExerciseMediaData copyWithCompanion(CachedExerciseMediaCompanion data) {
    return CachedExerciseMediaData(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExerciseMediaData(')
          ..write('exerciseId: $exerciseId, ')
          ..write('mediaType: $mediaType, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    exerciseId,
    mediaType,
    remoteUrl,
    localPath,
    fileSizeBytes,
    downloadedAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExerciseMediaData &&
          other.exerciseId == this.exerciseId &&
          other.mediaType == this.mediaType &&
          other.remoteUrl == this.remoteUrl &&
          other.localPath == this.localPath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class CachedExerciseMediaCompanion
    extends UpdateCompanion<CachedExerciseMediaData> {
  final Value<String> exerciseId;
  final Value<String> mediaType;
  final Value<String> remoteUrl;
  final Value<String> localPath;
  final Value<int?> fileSizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const CachedExerciseMediaCompanion({
    this.exerciseId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExerciseMediaCompanion.insert({
    required String exerciseId,
    required String mediaType,
    required String remoteUrl,
    required String localPath,
    this.fileSizeBytes = const Value.absent(),
    required DateTime downloadedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       mediaType = Value(mediaType),
       remoteUrl = Value(remoteUrl),
       localPath = Value(localPath),
       downloadedAt = Value(downloadedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CachedExerciseMediaData> custom({
    Expression<String>? exerciseId,
    Expression<String>? mediaType,
    Expression<String>? remoteUrl,
    Expression<String>? localPath,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (mediaType != null) 'media_type': mediaType,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (localPath != null) 'local_path': localPath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExerciseMediaCompanion copyWith({
    Value<String>? exerciseId,
    Value<String>? mediaType,
    Value<String>? remoteUrl,
    Value<String>? localPath,
    Value<int?>? fileSizeBytes,
    Value<DateTime>? downloadedAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return CachedExerciseMediaCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      mediaType: mediaType ?? this.mediaType,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExerciseMediaCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('mediaType: $mediaType, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedGymProfilesTable extends CachedGymProfiles
    with TableInfo<$CachedGymProfilesTable, CachedGymProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedGymProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    profileJson,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_gym_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedGymProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileJsonMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedGymProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedGymProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedGymProfilesTable createAlias(String alias) {
    return $CachedGymProfilesTable(attachedDatabase, alias);
  }
}

class CachedGymProfile extends DataClass
    implements Insertable<CachedGymProfile> {
  final String id;
  final String userId;
  final String profileJson;
  final bool isActive;
  final DateTime cachedAt;
  const CachedGymProfile({
    required this.id,
    required this.userId,
    required this.profileJson,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['profile_json'] = Variable<String>(profileJson);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedGymProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedGymProfilesCompanion(
      id: Value(id),
      userId: Value(userId),
      profileJson: Value(profileJson),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedGymProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedGymProfile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'profileJson': serializer.toJson<String>(profileJson),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedGymProfile copyWith({
    String? id,
    String? userId,
    String? profileJson,
    bool? isActive,
    DateTime? cachedAt,
  }) => CachedGymProfile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    profileJson: profileJson ?? this.profileJson,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedGymProfile copyWithCompanion(CachedGymProfilesCompanion data) {
    return CachedGymProfile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedGymProfile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, profileJson, isActive, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedGymProfile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.profileJson == this.profileJson &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class CachedGymProfilesCompanion extends UpdateCompanion<CachedGymProfile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> profileJson;
  final Value<bool> isActive;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedGymProfilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedGymProfilesCompanion.insert({
    required String id,
    required String userId,
    required String profileJson,
    this.isActive = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       profileJson = Value(profileJson),
       cachedAt = Value(cachedAt);
  static Insertable<CachedGymProfile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? profileJson,
    Expression<bool>? isActive,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (profileJson != null) 'profile_json': profileJson,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedGymProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? profileJson,
    Value<bool>? isActive,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedGymProfilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileJson: profileJson ?? this.profileJson,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedGymProfilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('profileJson: $profileJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFoodsTable extends CachedFoods
    with TableInfo<$CachedFoodsTable, CachedFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodCategoryMeta = const VerificationMeta(
    'foodCategory',
  );
  @override
  late final GeneratedColumn<String> foodCategory = GeneratedColumn<String>(
    'food_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('usda'),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingSizeGMeta = const VerificationMeta(
    'servingSizeG',
  );
  @override
  late final GeneratedColumn<double> servingSizeG = GeneratedColumn<double>(
    'serving_size_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100.0),
  );
  static const VerificationMeta _householdServingMeta = const VerificationMeta(
    'householdServing',
  );
  @override
  late final GeneratedColumn<String> householdServing = GeneratedColumn<String>(
    'household_serving',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vitaminAMcgMeta = const VerificationMeta(
    'vitaminAMcg',
  );
  @override
  late final GeneratedColumn<double> vitaminAMcg = GeneratedColumn<double>(
    'vitamin_a_mcg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vitaminCMgMeta = const VerificationMeta(
    'vitaminCMg',
  );
  @override
  late final GeneratedColumn<double> vitaminCMg = GeneratedColumn<double>(
    'vitamin_c_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calciumMgMeta = const VerificationMeta(
    'calciumMg',
  );
  @override
  late final GeneratedColumn<double> calciumMg = GeneratedColumn<double>(
    'calcium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ironMgMeta = const VerificationMeta('ironMg');
  @override
  late final GeneratedColumn<double> ironMg = GeneratedColumn<double>(
    'iron_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _potassiumMgMeta = const VerificationMeta(
    'potassiumMg',
  );
  @override
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
    'potassium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    externalId,
    description,
    foodCategory,
    source,
    barcode,
    brandName,
    servingSizeG,
    householdServing,
    calories,
    proteinG,
    fatG,
    carbsG,
    fiberG,
    sugarG,
    sodiumMg,
    vitaminAMcg,
    vitaminCMg,
    calciumMg,
    ironMg,
    potassiumMg,
    imageUrl,
    isFavorite,
    lastUsedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('food_category')) {
      context.handle(
        _foodCategoryMeta,
        foodCategory.isAcceptableOrUnknown(
          data['food_category']!,
          _foodCategoryMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    }
    if (data.containsKey('serving_size_g')) {
      context.handle(
        _servingSizeGMeta,
        servingSizeG.isAcceptableOrUnknown(
          data['serving_size_g']!,
          _servingSizeGMeta,
        ),
      );
    }
    if (data.containsKey('household_serving')) {
      context.handle(
        _householdServingMeta,
        householdServing.isAcceptableOrUnknown(
          data['household_serving']!,
          _householdServingMeta,
        ),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('vitamin_a_mcg')) {
      context.handle(
        _vitaminAMcgMeta,
        vitaminAMcg.isAcceptableOrUnknown(
          data['vitamin_a_mcg']!,
          _vitaminAMcgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_c_mg')) {
      context.handle(
        _vitaminCMgMeta,
        vitaminCMg.isAcceptableOrUnknown(
          data['vitamin_c_mg']!,
          _vitaminCMgMeta,
        ),
      );
    }
    if (data.containsKey('calcium_mg')) {
      context.handle(
        _calciumMgMeta,
        calciumMg.isAcceptableOrUnknown(data['calcium_mg']!, _calciumMgMeta),
      );
    }
    if (data.containsKey('iron_mg')) {
      context.handle(
        _ironMgMeta,
        ironMg.isAcceptableOrUnknown(data['iron_mg']!, _ironMgMeta),
      );
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
        _potassiumMgMeta,
        potassiumMg.isAcceptableOrUnknown(
          data['potassium_mg']!,
          _potassiumMgMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {externalId, source},
  ];
  @override
  CachedFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      foodCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_category'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      ),
      servingSizeG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_size_g'],
      )!,
      householdServing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_serving'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      )!,
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      )!,
      vitaminAMcg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_a_mcg'],
      ),
      vitaminCMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_c_mg'],
      ),
      calciumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calcium_mg'],
      ),
      ironMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iron_mg'],
      ),
      potassiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium_mg'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedFoodsTable createAlias(String alias) {
    return $CachedFoodsTable(attachedDatabase, alias);
  }
}

class CachedFood extends DataClass implements Insertable<CachedFood> {
  final int id;

  /// USDA FDC ID or Open Food Facts barcode
  final String externalId;

  /// Food name/description
  final String description;

  /// Food category (e.g., "Poultry", "Vegetables")
  final String? foodCategory;

  /// Source: 'usda', 'openfoodfacts', 'user'
  final String source;

  /// Barcode (EAN/UPC) if from Open Food Facts
  final String? barcode;

  /// Brand name (for packaged foods)
  final String? brandName;

  /// Serving size in grams
  final double servingSizeG;

  /// Household serving description (e.g., "1 cup", "1 large")
  final String? householdServing;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;
  final double? vitaminAMcg;
  final double? vitaminCMg;
  final double? calciumMg;
  final double? ironMg;
  final double? potassiumMg;

  /// Image URL (from Open Food Facts)
  final String? imageUrl;

  /// Whether this food is in user's favorites
  final bool isFavorite;

  /// Last time this food was used (for "recent foods" feature)
  final DateTime? lastUsedAt;

  /// When this record was cached/created
  final DateTime cachedAt;
  const CachedFood({
    required this.id,
    required this.externalId,
    required this.description,
    this.foodCategory,
    required this.source,
    this.barcode,
    this.brandName,
    required this.servingSizeG,
    this.householdServing,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    this.vitaminAMcg,
    this.vitaminCMg,
    this.calciumMg,
    this.ironMg,
    this.potassiumMg,
    this.imageUrl,
    required this.isFavorite,
    this.lastUsedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['external_id'] = Variable<String>(externalId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || foodCategory != null) {
      map['food_category'] = Variable<String>(foodCategory);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || brandName != null) {
      map['brand_name'] = Variable<String>(brandName);
    }
    map['serving_size_g'] = Variable<double>(servingSizeG);
    if (!nullToAbsent || householdServing != null) {
      map['household_serving'] = Variable<String>(householdServing);
    }
    map['calories'] = Variable<double>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['fat_g'] = Variable<double>(fatG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fiber_g'] = Variable<double>(fiberG);
    map['sugar_g'] = Variable<double>(sugarG);
    map['sodium_mg'] = Variable<double>(sodiumMg);
    if (!nullToAbsent || vitaminAMcg != null) {
      map['vitamin_a_mcg'] = Variable<double>(vitaminAMcg);
    }
    if (!nullToAbsent || vitaminCMg != null) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg);
    }
    if (!nullToAbsent || calciumMg != null) {
      map['calcium_mg'] = Variable<double>(calciumMg);
    }
    if (!nullToAbsent || ironMg != null) {
      map['iron_mg'] = Variable<double>(ironMg);
    }
    if (!nullToAbsent || potassiumMg != null) {
      map['potassium_mg'] = Variable<double>(potassiumMg);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFoodsCompanion toCompanion(bool nullToAbsent) {
    return CachedFoodsCompanion(
      id: Value(id),
      externalId: Value(externalId),
      description: Value(description),
      foodCategory: foodCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(foodCategory),
      source: Value(source),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      brandName: brandName == null && nullToAbsent
          ? const Value.absent()
          : Value(brandName),
      servingSizeG: Value(servingSizeG),
      householdServing: householdServing == null && nullToAbsent
          ? const Value.absent()
          : Value(householdServing),
      calories: Value(calories),
      proteinG: Value(proteinG),
      fatG: Value(fatG),
      carbsG: Value(carbsG),
      fiberG: Value(fiberG),
      sugarG: Value(sugarG),
      sodiumMg: Value(sodiumMg),
      vitaminAMcg: vitaminAMcg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminAMcg),
      vitaminCMg: vitaminCMg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminCMg),
      calciumMg: calciumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(calciumMg),
      ironMg: ironMg == null && nullToAbsent
          ? const Value.absent()
          : Value(ironMg),
      potassiumMg: potassiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumMg),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      isFavorite: Value(isFavorite),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFood(
      id: serializer.fromJson<int>(json['id']),
      externalId: serializer.fromJson<String>(json['externalId']),
      description: serializer.fromJson<String>(json['description']),
      foodCategory: serializer.fromJson<String?>(json['foodCategory']),
      source: serializer.fromJson<String>(json['source']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      brandName: serializer.fromJson<String?>(json['brandName']),
      servingSizeG: serializer.fromJson<double>(json['servingSizeG']),
      householdServing: serializer.fromJson<String?>(json['householdServing']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      sugarG: serializer.fromJson<double>(json['sugarG']),
      sodiumMg: serializer.fromJson<double>(json['sodiumMg']),
      vitaminAMcg: serializer.fromJson<double?>(json['vitaminAMcg']),
      vitaminCMg: serializer.fromJson<double?>(json['vitaminCMg']),
      calciumMg: serializer.fromJson<double?>(json['calciumMg']),
      ironMg: serializer.fromJson<double?>(json['ironMg']),
      potassiumMg: serializer.fromJson<double?>(json['potassiumMg']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'externalId': serializer.toJson<String>(externalId),
      'description': serializer.toJson<String>(description),
      'foodCategory': serializer.toJson<String?>(foodCategory),
      'source': serializer.toJson<String>(source),
      'barcode': serializer.toJson<String?>(barcode),
      'brandName': serializer.toJson<String?>(brandName),
      'servingSizeG': serializer.toJson<double>(servingSizeG),
      'householdServing': serializer.toJson<String?>(householdServing),
      'calories': serializer.toJson<double>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'fatG': serializer.toJson<double>(fatG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fiberG': serializer.toJson<double>(fiberG),
      'sugarG': serializer.toJson<double>(sugarG),
      'sodiumMg': serializer.toJson<double>(sodiumMg),
      'vitaminAMcg': serializer.toJson<double?>(vitaminAMcg),
      'vitaminCMg': serializer.toJson<double?>(vitaminCMg),
      'calciumMg': serializer.toJson<double?>(calciumMg),
      'ironMg': serializer.toJson<double?>(ironMg),
      'potassiumMg': serializer.toJson<double?>(potassiumMg),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFood copyWith({
    int? id,
    String? externalId,
    String? description,
    Value<String?> foodCategory = const Value.absent(),
    String? source,
    Value<String?> barcode = const Value.absent(),
    Value<String?> brandName = const Value.absent(),
    double? servingSizeG,
    Value<String?> householdServing = const Value.absent(),
    double? calories,
    double? proteinG,
    double? fatG,
    double? carbsG,
    double? fiberG,
    double? sugarG,
    double? sodiumMg,
    Value<double?> vitaminAMcg = const Value.absent(),
    Value<double?> vitaminCMg = const Value.absent(),
    Value<double?> calciumMg = const Value.absent(),
    Value<double?> ironMg = const Value.absent(),
    Value<double?> potassiumMg = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    bool? isFavorite,
    Value<DateTime?> lastUsedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedFood(
    id: id ?? this.id,
    externalId: externalId ?? this.externalId,
    description: description ?? this.description,
    foodCategory: foodCategory.present ? foodCategory.value : this.foodCategory,
    source: source ?? this.source,
    barcode: barcode.present ? barcode.value : this.barcode,
    brandName: brandName.present ? brandName.value : this.brandName,
    servingSizeG: servingSizeG ?? this.servingSizeG,
    householdServing: householdServing.present
        ? householdServing.value
        : this.householdServing,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    fatG: fatG ?? this.fatG,
    carbsG: carbsG ?? this.carbsG,
    fiberG: fiberG ?? this.fiberG,
    sugarG: sugarG ?? this.sugarG,
    sodiumMg: sodiumMg ?? this.sodiumMg,
    vitaminAMcg: vitaminAMcg.present ? vitaminAMcg.value : this.vitaminAMcg,
    vitaminCMg: vitaminCMg.present ? vitaminCMg.value : this.vitaminCMg,
    calciumMg: calciumMg.present ? calciumMg.value : this.calciumMg,
    ironMg: ironMg.present ? ironMg.value : this.ironMg,
    potassiumMg: potassiumMg.present ? potassiumMg.value : this.potassiumMg,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    isFavorite: isFavorite ?? this.isFavorite,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedFood copyWithCompanion(CachedFoodsCompanion data) {
    return CachedFood(
      id: data.id.present ? data.id.value : this.id,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      description: data.description.present
          ? data.description.value
          : this.description,
      foodCategory: data.foodCategory.present
          ? data.foodCategory.value
          : this.foodCategory,
      source: data.source.present ? data.source.value : this.source,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      servingSizeG: data.servingSizeG.present
          ? data.servingSizeG.value
          : this.servingSizeG,
      householdServing: data.householdServing.present
          ? data.householdServing.value
          : this.householdServing,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      vitaminAMcg: data.vitaminAMcg.present
          ? data.vitaminAMcg.value
          : this.vitaminAMcg,
      vitaminCMg: data.vitaminCMg.present
          ? data.vitaminCMg.value
          : this.vitaminCMg,
      calciumMg: data.calciumMg.present ? data.calciumMg.value : this.calciumMg,
      ironMg: data.ironMg.present ? data.ironMg.value : this.ironMg,
      potassiumMg: data.potassiumMg.present
          ? data.potassiumMg.value
          : this.potassiumMg,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFood(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('description: $description, ')
          ..write('foodCategory: $foodCategory, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('brandName: $brandName, ')
          ..write('servingSizeG: $servingSizeG, ')
          ..write('householdServing: $householdServing, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('vitaminAMcg: $vitaminAMcg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    externalId,
    description,
    foodCategory,
    source,
    barcode,
    brandName,
    servingSizeG,
    householdServing,
    calories,
    proteinG,
    fatG,
    carbsG,
    fiberG,
    sugarG,
    sodiumMg,
    vitaminAMcg,
    vitaminCMg,
    calciumMg,
    ironMg,
    potassiumMg,
    imageUrl,
    isFavorite,
    lastUsedAt,
    cachedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFood &&
          other.id == this.id &&
          other.externalId == this.externalId &&
          other.description == this.description &&
          other.foodCategory == this.foodCategory &&
          other.source == this.source &&
          other.barcode == this.barcode &&
          other.brandName == this.brandName &&
          other.servingSizeG == this.servingSizeG &&
          other.householdServing == this.householdServing &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbsG == this.carbsG &&
          other.fiberG == this.fiberG &&
          other.sugarG == this.sugarG &&
          other.sodiumMg == this.sodiumMg &&
          other.vitaminAMcg == this.vitaminAMcg &&
          other.vitaminCMg == this.vitaminCMg &&
          other.calciumMg == this.calciumMg &&
          other.ironMg == this.ironMg &&
          other.potassiumMg == this.potassiumMg &&
          other.imageUrl == this.imageUrl &&
          other.isFavorite == this.isFavorite &&
          other.lastUsedAt == this.lastUsedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedFoodsCompanion extends UpdateCompanion<CachedFood> {
  final Value<int> id;
  final Value<String> externalId;
  final Value<String> description;
  final Value<String?> foodCategory;
  final Value<String> source;
  final Value<String?> barcode;
  final Value<String?> brandName;
  final Value<double> servingSizeG;
  final Value<String?> householdServing;
  final Value<double> calories;
  final Value<double> proteinG;
  final Value<double> fatG;
  final Value<double> carbsG;
  final Value<double> fiberG;
  final Value<double> sugarG;
  final Value<double> sodiumMg;
  final Value<double?> vitaminAMcg;
  final Value<double?> vitaminCMg;
  final Value<double?> calciumMg;
  final Value<double?> ironMg;
  final Value<double?> potassiumMg;
  final Value<String?> imageUrl;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> cachedAt;
  const CachedFoodsCompanion({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
    this.description = const Value.absent(),
    this.foodCategory = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.brandName = const Value.absent(),
    this.servingSizeG = const Value.absent(),
    this.householdServing = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.vitaminAMcg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String externalId,
    required String description,
    this.foodCategory = const Value.absent(),
    this.source = const Value.absent(),
    this.barcode = const Value.absent(),
    this.brandName = const Value.absent(),
    this.servingSizeG = const Value.absent(),
    this.householdServing = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.vitaminAMcg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    required DateTime cachedAt,
  }) : externalId = Value(externalId),
       description = Value(description),
       cachedAt = Value(cachedAt);
  static Insertable<CachedFood> custom({
    Expression<int>? id,
    Expression<String>? externalId,
    Expression<String>? description,
    Expression<String>? foodCategory,
    Expression<String>? source,
    Expression<String>? barcode,
    Expression<String>? brandName,
    Expression<double>? servingSizeG,
    Expression<String>? householdServing,
    Expression<double>? calories,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbsG,
    Expression<double>? fiberG,
    Expression<double>? sugarG,
    Expression<double>? sodiumMg,
    Expression<double>? vitaminAMcg,
    Expression<double>? vitaminCMg,
    Expression<double>? calciumMg,
    Expression<double>? ironMg,
    Expression<double>? potassiumMg,
    Expression<String>? imageUrl,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalId != null) 'external_id': externalId,
      if (description != null) 'description': description,
      if (foodCategory != null) 'food_category': foodCategory,
      if (source != null) 'source': source,
      if (barcode != null) 'barcode': barcode,
      if (brandName != null) 'brand_name': brandName,
      if (servingSizeG != null) 'serving_size_g': servingSizeG,
      if (householdServing != null) 'household_serving': householdServing,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (vitaminAMcg != null) 'vitamin_a_mcg': vitaminAMcg,
      if (vitaminCMg != null) 'vitamin_c_mg': vitaminCMg,
      if (calciumMg != null) 'calcium_mg': calciumMg,
      if (ironMg != null) 'iron_mg': ironMg,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? externalId,
    Value<String>? description,
    Value<String?>? foodCategory,
    Value<String>? source,
    Value<String?>? barcode,
    Value<String?>? brandName,
    Value<double>? servingSizeG,
    Value<String?>? householdServing,
    Value<double>? calories,
    Value<double>? proteinG,
    Value<double>? fatG,
    Value<double>? carbsG,
    Value<double>? fiberG,
    Value<double>? sugarG,
    Value<double>? sodiumMg,
    Value<double?>? vitaminAMcg,
    Value<double?>? vitaminCMg,
    Value<double?>? calciumMg,
    Value<double?>? ironMg,
    Value<double?>? potassiumMg,
    Value<String?>? imageUrl,
    Value<bool>? isFavorite,
    Value<DateTime?>? lastUsedAt,
    Value<DateTime>? cachedAt,
  }) {
    return CachedFoodsCompanion(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      description: description ?? this.description,
      foodCategory: foodCategory ?? this.foodCategory,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
      brandName: brandName ?? this.brandName,
      servingSizeG: servingSizeG ?? this.servingSizeG,
      householdServing: householdServing ?? this.householdServing,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbsG: carbsG ?? this.carbsG,
      fiberG: fiberG ?? this.fiberG,
      sugarG: sugarG ?? this.sugarG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      vitaminAMcg: vitaminAMcg ?? this.vitaminAMcg,
      vitaminCMg: vitaminCMg ?? this.vitaminCMg,
      calciumMg: calciumMg ?? this.calciumMg,
      ironMg: ironMg ?? this.ironMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (foodCategory.present) {
      map['food_category'] = Variable<String>(foodCategory.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (servingSizeG.present) {
      map['serving_size_g'] = Variable<double>(servingSizeG.value);
    }
    if (householdServing.present) {
      map['household_serving'] = Variable<String>(householdServing.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (vitaminAMcg.present) {
      map['vitamin_a_mcg'] = Variable<double>(vitaminAMcg.value);
    }
    if (vitaminCMg.present) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg.value);
    }
    if (calciumMg.present) {
      map['calcium_mg'] = Variable<double>(calciumMg.value);
    }
    if (ironMg.present) {
      map['iron_mg'] = Variable<double>(ironMg.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFoodsCompanion(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('description: $description, ')
          ..write('foodCategory: $foodCategory, ')
          ..write('source: $source, ')
          ..write('barcode: $barcode, ')
          ..write('brandName: $brandName, ')
          ..write('servingSizeG: $servingSizeG, ')
          ..write('householdServing: $householdServing, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('vitaminAMcg: $vitaminAMcg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $EmbeddingCacheTable extends EmbeddingCache
    with TableInfo<$EmbeddingCacheTable, EmbeddingCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmbeddingCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchableTextMeta = const VerificationMeta(
    'searchableText',
  );
  @override
  late final GeneratedColumn<String> searchableText = GeneratedColumn<String>(
    'searchable_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingBlobMeta = const VerificationMeta(
    'embeddingBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> embeddingBlob =
      GeneratedColumn<Uint8List>(
        'embedding_blob',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dimensionMeta = const VerificationMeta(
    'dimension',
  );
  @override
  late final GeneratedColumn<int> dimension = GeneratedColumn<int>(
    'dimension',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(768),
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    searchableText,
    embeddingBlob,
    dimension,
    modelVersion,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'embedding_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmbeddingCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('searchable_text')) {
      context.handle(
        _searchableTextMeta,
        searchableText.isAcceptableOrUnknown(
          data['searchable_text']!,
          _searchableTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_searchableTextMeta);
    }
    if (data.containsKey('embedding_blob')) {
      context.handle(
        _embeddingBlobMeta,
        embeddingBlob.isAcceptableOrUnknown(
          data['embedding_blob']!,
          _embeddingBlobMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingBlobMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(
        _dimensionMeta,
        dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta),
      );
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityId},
  ];
  @override
  EmbeddingCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmbeddingCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      searchableText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}searchable_text'],
      )!,
      embeddingBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding_blob'],
      )!,
      dimension: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dimension'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EmbeddingCacheTable createAlias(String alias) {
    return $EmbeddingCacheTable(attachedDatabase, alias);
  }
}

class EmbeddingCacheData extends DataClass
    implements Insertable<EmbeddingCacheData> {
  final int id;

  /// Entity type: 'exercise' or 'food'
  final String entityType;

  /// Foreign key to the source entity (exercise ID or food external ID)
  final String entityId;

  /// The text that was embedded (for debugging and re-indexing detection)
  final String searchableText;

  /// Embedding vector stored as BLOB (Float32List → Uint8List)
  final Uint8List embeddingBlob;

  /// Embedding dimension (768 for EmbeddingGemma)
  final int dimension;

  /// Model version that produced this embedding (for invalidation on model change)
  final String modelVersion;
  final DateTime createdAt;
  const EmbeddingCacheData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.searchableText,
    required this.embeddingBlob,
    required this.dimension,
    required this.modelVersion,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['searchable_text'] = Variable<String>(searchableText);
    map['embedding_blob'] = Variable<Uint8List>(embeddingBlob);
    map['dimension'] = Variable<int>(dimension);
    map['model_version'] = Variable<String>(modelVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmbeddingCacheCompanion toCompanion(bool nullToAbsent) {
    return EmbeddingCacheCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      searchableText: Value(searchableText),
      embeddingBlob: Value(embeddingBlob),
      dimension: Value(dimension),
      modelVersion: Value(modelVersion),
      createdAt: Value(createdAt),
    );
  }

  factory EmbeddingCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmbeddingCacheData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      searchableText: serializer.fromJson<String>(json['searchableText']),
      embeddingBlob: serializer.fromJson<Uint8List>(json['embeddingBlob']),
      dimension: serializer.fromJson<int>(json['dimension']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'searchableText': serializer.toJson<String>(searchableText),
      'embeddingBlob': serializer.toJson<Uint8List>(embeddingBlob),
      'dimension': serializer.toJson<int>(dimension),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EmbeddingCacheData copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? searchableText,
    Uint8List? embeddingBlob,
    int? dimension,
    String? modelVersion,
    DateTime? createdAt,
  }) => EmbeddingCacheData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    searchableText: searchableText ?? this.searchableText,
    embeddingBlob: embeddingBlob ?? this.embeddingBlob,
    dimension: dimension ?? this.dimension,
    modelVersion: modelVersion ?? this.modelVersion,
    createdAt: createdAt ?? this.createdAt,
  );
  EmbeddingCacheData copyWithCompanion(EmbeddingCacheCompanion data) {
    return EmbeddingCacheData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      searchableText: data.searchableText.present
          ? data.searchableText.value
          : this.searchableText,
      embeddingBlob: data.embeddingBlob.present
          ? data.embeddingBlob.value
          : this.embeddingBlob,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingCacheData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('searchableText: $searchableText, ')
          ..write('embeddingBlob: $embeddingBlob, ')
          ..write('dimension: $dimension, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    searchableText,
    $driftBlobEquality.hash(embeddingBlob),
    dimension,
    modelVersion,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmbeddingCacheData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.searchableText == this.searchableText &&
          $driftBlobEquality.equals(other.embeddingBlob, this.embeddingBlob) &&
          other.dimension == this.dimension &&
          other.modelVersion == this.modelVersion &&
          other.createdAt == this.createdAt);
}

class EmbeddingCacheCompanion extends UpdateCompanion<EmbeddingCacheData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> searchableText;
  final Value<Uint8List> embeddingBlob;
  final Value<int> dimension;
  final Value<String> modelVersion;
  final Value<DateTime> createdAt;
  const EmbeddingCacheCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.searchableText = const Value.absent(),
    this.embeddingBlob = const Value.absent(),
    this.dimension = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmbeddingCacheCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String searchableText,
    required Uint8List embeddingBlob,
    this.dimension = const Value.absent(),
    required String modelVersion,
    required DateTime createdAt,
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       searchableText = Value(searchableText),
       embeddingBlob = Value(embeddingBlob),
       modelVersion = Value(modelVersion),
       createdAt = Value(createdAt);
  static Insertable<EmbeddingCacheData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? searchableText,
    Expression<Uint8List>? embeddingBlob,
    Expression<int>? dimension,
    Expression<String>? modelVersion,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (searchableText != null) 'searchable_text': searchableText,
      if (embeddingBlob != null) 'embedding_blob': embeddingBlob,
      if (dimension != null) 'dimension': dimension,
      if (modelVersion != null) 'model_version': modelVersion,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmbeddingCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? searchableText,
    Value<Uint8List>? embeddingBlob,
    Value<int>? dimension,
    Value<String>? modelVersion,
    Value<DateTime>? createdAt,
  }) {
    return EmbeddingCacheCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      searchableText: searchableText ?? this.searchableText,
      embeddingBlob: embeddingBlob ?? this.embeddingBlob,
      dimension: dimension ?? this.dimension,
      modelVersion: modelVersion ?? this.modelVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (searchableText.present) {
      map['searchable_text'] = Variable<String>(searchableText.value);
    }
    if (embeddingBlob.present) {
      map['embedding_blob'] = Variable<Uint8List>(embeddingBlob.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<int>(dimension.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingCacheCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('searchableText: $searchableText, ')
          ..write('embeddingBlob: $embeddingBlob, ')
          ..write('dimension: $dimension, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedWorkoutsTable cachedWorkouts = $CachedWorkoutsTable(this);
  late final $CachedExercisesTable cachedExercises = $CachedExercisesTable(
    this,
  );
  late final $CachedUserProfilesTable cachedUserProfiles =
      $CachedUserProfilesTable(this);
  late final $CachedWorkoutLogsTable cachedWorkoutLogs =
      $CachedWorkoutLogsTable(this);
  late final $PendingSyncQueueTable pendingSyncQueue = $PendingSyncQueueTable(
    this,
  );
  late final $CachedExerciseMediaTable cachedExerciseMedia =
      $CachedExerciseMediaTable(this);
  late final $CachedGymProfilesTable cachedGymProfiles =
      $CachedGymProfilesTable(this);
  late final $CachedFoodsTable cachedFoods = $CachedFoodsTable(this);
  late final $EmbeddingCacheTable embeddingCache = $EmbeddingCacheTable(this);
  late final WorkoutDao workoutDao = WorkoutDao(this as AppDatabase);
  late final ExerciseLibraryDao exerciseLibraryDao = ExerciseLibraryDao(
    this as AppDatabase,
  );
  late final UserProfileDao userProfileDao = UserProfileDao(
    this as AppDatabase,
  );
  late final WorkoutLogDao workoutLogDao = WorkoutLogDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final MediaCacheDao mediaCacheDao = MediaCacheDao(this as AppDatabase);
  late final GymProfileDao gymProfileDao = GymProfileDao(this as AppDatabase);
  late final FoodDao foodDao = FoodDao(this as AppDatabase);
  late final EmbeddingDao embeddingDao = EmbeddingDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedWorkouts,
    cachedExercises,
    cachedUserProfiles,
    cachedWorkoutLogs,
    pendingSyncQueue,
    cachedExerciseMedia,
    cachedGymProfiles,
    cachedFoods,
    embeddingCache,
  ];
}

typedef $$CachedWorkoutsTableCreateCompanionBuilder =
    CachedWorkoutsCompanion Function({
      required String id,
      required String userId,
      Value<String?> name,
      Value<String?> type,
      Value<String?> difficulty,
      Value<String?> scheduledDate,
      Value<bool> isCompleted,
      required String exercisesJson,
      Value<int?> durationMinutes,
      Value<String?> generationMethod,
      Value<String?> generationMetadata,
      required DateTime cachedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$CachedWorkoutsTableUpdateCompanionBuilder =
    CachedWorkoutsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> name,
      Value<String?> type,
      Value<String?> difficulty,
      Value<String?> scheduledDate,
      Value<bool> isCompleted,
      Value<String> exercisesJson,
      Value<int?> durationMinutes,
      Value<String?> generationMethod,
      Value<String?> generationMetadata,
      Value<DateTime> cachedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$CachedWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWorkoutsTable> {
  $$CachedWorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generationMethod => $composableBuilder(
    column: $table.generationMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get generationMetadata => $composableBuilder(
    column: $table.generationMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWorkoutsTable> {
  $$CachedWorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generationMethod => $composableBuilder(
    column: $table.generationMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generationMetadata => $composableBuilder(
    column: $table.generationMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWorkoutsTable> {
  $$CachedWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get generationMethod => $composableBuilder(
    column: $table.generationMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get generationMetadata => $composableBuilder(
    column: $table.generationMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$CachedWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWorkoutsTable,
          CachedWorkout,
          $$CachedWorkoutsTableFilterComposer,
          $$CachedWorkoutsTableOrderingComposer,
          $$CachedWorkoutsTableAnnotationComposer,
          $$CachedWorkoutsTableCreateCompanionBuilder,
          $$CachedWorkoutsTableUpdateCompanionBuilder,
          (
            CachedWorkout,
            BaseReferences<_$AppDatabase, $CachedWorkoutsTable, CachedWorkout>,
          ),
          CachedWorkout,
          PrefetchHooks Function()
        > {
  $$CachedWorkoutsTableTableManager(
    _$AppDatabase db,
    $CachedWorkoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> scheduledDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> exercisesJson = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> generationMethod = const Value.absent(),
                Value<String?> generationMetadata = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutsCompanion(
                id: id,
                userId: userId,
                name: name,
                type: type,
                difficulty: difficulty,
                scheduledDate: scheduledDate,
                isCompleted: isCompleted,
                exercisesJson: exercisesJson,
                durationMinutes: durationMinutes,
                generationMethod: generationMethod,
                generationMetadata: generationMetadata,
                cachedAt: cachedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> scheduledDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                required String exercisesJson,
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> generationMethod = const Value.absent(),
                Value<String?> generationMetadata = const Value.absent(),
                required DateTime cachedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                type: type,
                difficulty: difficulty,
                scheduledDate: scheduledDate,
                isCompleted: isCompleted,
                exercisesJson: exercisesJson,
                durationMinutes: durationMinutes,
                generationMethod: generationMethod,
                generationMetadata: generationMetadata,
                cachedAt: cachedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWorkoutsTable,
      CachedWorkout,
      $$CachedWorkoutsTableFilterComposer,
      $$CachedWorkoutsTableOrderingComposer,
      $$CachedWorkoutsTableAnnotationComposer,
      $$CachedWorkoutsTableCreateCompanionBuilder,
      $$CachedWorkoutsTableUpdateCompanionBuilder,
      (
        CachedWorkout,
        BaseReferences<_$AppDatabase, $CachedWorkoutsTable, CachedWorkout>,
      ),
      CachedWorkout,
      PrefetchHooks Function()
    >;
typedef $$CachedExercisesTableCreateCompanionBuilder =
    CachedExercisesCompanion Function({
      required String id,
      required String name,
      Value<String?> bodyPart,
      Value<String?> equipment,
      Value<String?> targetMuscle,
      Value<String?> primaryMuscle,
      Value<String?> secondaryMuscles,
      Value<String?> videoUrl,
      Value<String?> imageS3Path,
      Value<String?> instructions,
      Value<String?> difficulty,
      Value<int?> difficultyNum,
      required DateTime cachedAt,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$CachedExercisesTableUpdateCompanionBuilder =
    CachedExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> bodyPart,
      Value<String?> equipment,
      Value<String?> targetMuscle,
      Value<String?> primaryMuscle,
      Value<String?> secondaryMuscles,
      Value<String?> videoUrl,
      Value<String?> imageS3Path,
      Value<String?> instructions,
      Value<String?> difficulty,
      Value<int?> difficultyNum,
      Value<DateTime> cachedAt,
      Value<bool> isFavorite,
      Value<int> rowid,
    });

class $$CachedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetMuscle => $composableBuilder(
    column: $table.targetMuscle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageS3Path => $composableBuilder(
    column: $table.imageS3Path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultyNum => $composableBuilder(
    column: $table.difficultyNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetMuscle => $composableBuilder(
    column: $table.targetMuscle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageS3Path => $composableBuilder(
    column: $table.imageS3Path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultyNum => $composableBuilder(
    column: $table.difficultyNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedExercisesTable> {
  $$CachedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bodyPart =>
      $composableBuilder(column: $table.bodyPart, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get targetMuscle => $composableBuilder(
    column: $table.targetMuscle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryMuscle => $composableBuilder(
    column: $table.primaryMuscle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get imageS3Path => $composableBuilder(
    column: $table.imageS3Path,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultyNum => $composableBuilder(
    column: $table.difficultyNum,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$CachedExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedExercisesTable,
          CachedExercise,
          $$CachedExercisesTableFilterComposer,
          $$CachedExercisesTableOrderingComposer,
          $$CachedExercisesTableAnnotationComposer,
          $$CachedExercisesTableCreateCompanionBuilder,
          $$CachedExercisesTableUpdateCompanionBuilder,
          (
            CachedExercise,
            BaseReferences<
              _$AppDatabase,
              $CachedExercisesTable,
              CachedExercise
            >,
          ),
          CachedExercise,
          PrefetchHooks Function()
        > {
  $$CachedExercisesTableTableManager(
    _$AppDatabase db,
    $CachedExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> bodyPart = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> targetMuscle = const Value.absent(),
                Value<String?> primaryMuscle = const Value.absent(),
                Value<String?> secondaryMuscles = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> imageS3Path = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int?> difficultyNum = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExercisesCompanion(
                id: id,
                name: name,
                bodyPart: bodyPart,
                equipment: equipment,
                targetMuscle: targetMuscle,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                videoUrl: videoUrl,
                imageS3Path: imageS3Path,
                instructions: instructions,
                difficulty: difficulty,
                difficultyNum: difficultyNum,
                cachedAt: cachedAt,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> bodyPart = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> targetMuscle = const Value.absent(),
                Value<String?> primaryMuscle = const Value.absent(),
                Value<String?> secondaryMuscles = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> imageS3Path = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int?> difficultyNum = const Value.absent(),
                required DateTime cachedAt,
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExercisesCompanion.insert(
                id: id,
                name: name,
                bodyPart: bodyPart,
                equipment: equipment,
                targetMuscle: targetMuscle,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                videoUrl: videoUrl,
                imageS3Path: imageS3Path,
                instructions: instructions,
                difficulty: difficulty,
                difficultyNum: difficultyNum,
                cachedAt: cachedAt,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedExercisesTable,
      CachedExercise,
      $$CachedExercisesTableFilterComposer,
      $$CachedExercisesTableOrderingComposer,
      $$CachedExercisesTableAnnotationComposer,
      $$CachedExercisesTableCreateCompanionBuilder,
      $$CachedExercisesTableUpdateCompanionBuilder,
      (
        CachedExercise,
        BaseReferences<_$AppDatabase, $CachedExercisesTable, CachedExercise>,
      ),
      CachedExercise,
      PrefetchHooks Function()
    >;
typedef $$CachedUserProfilesTableCreateCompanionBuilder =
    CachedUserProfilesCompanion Function({
      required String id,
      required String profileJson,
      required DateTime cachedAt,
      Value<DateTime?> lastModifiedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$CachedUserProfilesTableUpdateCompanionBuilder =
    CachedUserProfilesCompanion Function({
      Value<String> id,
      Value<String> profileJson,
      Value<DateTime> cachedAt,
      Value<DateTime?> lastModifiedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$CachedUserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUserProfilesTable> {
  $$CachedUserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedUserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUserProfilesTable> {
  $$CachedUserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUserProfilesTable> {
  $$CachedUserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$CachedUserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedUserProfilesTable,
          CachedUserProfile,
          $$CachedUserProfilesTableFilterComposer,
          $$CachedUserProfilesTableOrderingComposer,
          $$CachedUserProfilesTableAnnotationComposer,
          $$CachedUserProfilesTableCreateCompanionBuilder,
          $$CachedUserProfilesTableUpdateCompanionBuilder,
          (
            CachedUserProfile,
            BaseReferences<
              _$AppDatabase,
              $CachedUserProfilesTable,
              CachedUserProfile
            >,
          ),
          CachedUserProfile,
          PrefetchHooks Function()
        > {
  $$CachedUserProfilesTableTableManager(
    _$AppDatabase db,
    $CachedUserProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUserProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime?> lastModifiedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUserProfilesCompanion(
                id: id,
                profileJson: profileJson,
                cachedAt: cachedAt,
                lastModifiedAt: lastModifiedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileJson,
                required DateTime cachedAt,
                Value<DateTime?> lastModifiedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUserProfilesCompanion.insert(
                id: id,
                profileJson: profileJson,
                cachedAt: cachedAt,
                lastModifiedAt: lastModifiedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedUserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedUserProfilesTable,
      CachedUserProfile,
      $$CachedUserProfilesTableFilterComposer,
      $$CachedUserProfilesTableOrderingComposer,
      $$CachedUserProfilesTableAnnotationComposer,
      $$CachedUserProfilesTableCreateCompanionBuilder,
      $$CachedUserProfilesTableUpdateCompanionBuilder,
      (
        CachedUserProfile,
        BaseReferences<
          _$AppDatabase,
          $CachedUserProfilesTable,
          CachedUserProfile
        >,
      ),
      CachedUserProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedWorkoutLogsTableCreateCompanionBuilder =
    CachedWorkoutLogsCompanion Function({
      required String id,
      required String workoutId,
      required String userId,
      Value<String?> exerciseId,
      required String exerciseName,
      required int setNumber,
      Value<int?> repsCompleted,
      Value<double?> weightKg,
      Value<String> setType,
      Value<int?> rpe,
      Value<int?> rir,
      Value<String?> notes,
      required DateTime completedAt,
      Value<String> syncStatus,
      Value<int> syncRetryCount,
      Value<int> rowid,
    });
typedef $$CachedWorkoutLogsTableUpdateCompanionBuilder =
    CachedWorkoutLogsCompanion Function({
      Value<String> id,
      Value<String> workoutId,
      Value<String> userId,
      Value<String?> exerciseId,
      Value<String> exerciseName,
      Value<int> setNumber,
      Value<int?> repsCompleted,
      Value<double?> weightKg,
      Value<String> setType,
      Value<int?> rpe,
      Value<int?> rir,
      Value<String?> notes,
      Value<DateTime> completedAt,
      Value<String> syncStatus,
      Value<int> syncRetryCount,
      Value<int> rowid,
    });

class $$CachedWorkoutLogsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWorkoutLogsTable> {
  $$CachedWorkoutLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repsCompleted => $composableBuilder(
    column: $table.repsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWorkoutLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWorkoutLogsTable> {
  $$CachedWorkoutLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repsCompleted => $composableBuilder(
    column: $table.repsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWorkoutLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWorkoutLogsTable> {
  $$CachedWorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<int> get repsCompleted => $composableBuilder(
    column: $table.repsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => column,
  );
}

class $$CachedWorkoutLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWorkoutLogsTable,
          CachedWorkoutLog,
          $$CachedWorkoutLogsTableFilterComposer,
          $$CachedWorkoutLogsTableOrderingComposer,
          $$CachedWorkoutLogsTableAnnotationComposer,
          $$CachedWorkoutLogsTableCreateCompanionBuilder,
          $$CachedWorkoutLogsTableUpdateCompanionBuilder,
          (
            CachedWorkoutLog,
            BaseReferences<
              _$AppDatabase,
              $CachedWorkoutLogsTable,
              CachedWorkoutLog
            >,
          ),
          CachedWorkoutLog,
          PrefetchHooks Function()
        > {
  $$CachedWorkoutLogsTableTableManager(
    _$AppDatabase db,
    $CachedWorkoutLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWorkoutLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<int?> repsCompleted = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String> setType = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncRetryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutLogsCompanion(
                id: id,
                workoutId: workoutId,
                userId: userId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setNumber: setNumber,
                repsCompleted: repsCompleted,
                weightKg: weightKg,
                setType: setType,
                rpe: rpe,
                rir: rir,
                notes: notes,
                completedAt: completedAt,
                syncStatus: syncStatus,
                syncRetryCount: syncRetryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutId,
                required String userId,
                Value<String?> exerciseId = const Value.absent(),
                required String exerciseName,
                required int setNumber,
                Value<int?> repsCompleted = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String> setType = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime completedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncRetryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWorkoutLogsCompanion.insert(
                id: id,
                workoutId: workoutId,
                userId: userId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setNumber: setNumber,
                repsCompleted: repsCompleted,
                weightKg: weightKg,
                setType: setType,
                rpe: rpe,
                rir: rir,
                notes: notes,
                completedAt: completedAt,
                syncStatus: syncStatus,
                syncRetryCount: syncRetryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWorkoutLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWorkoutLogsTable,
      CachedWorkoutLog,
      $$CachedWorkoutLogsTableFilterComposer,
      $$CachedWorkoutLogsTableOrderingComposer,
      $$CachedWorkoutLogsTableAnnotationComposer,
      $$CachedWorkoutLogsTableCreateCompanionBuilder,
      $$CachedWorkoutLogsTableUpdateCompanionBuilder,
      (
        CachedWorkoutLog,
        BaseReferences<
          _$AppDatabase,
          $CachedWorkoutLogsTable,
          CachedWorkoutLog
        >,
      ),
      CachedWorkoutLog,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncQueueTableCreateCompanionBuilder =
    PendingSyncQueueCompanion Function({
      Value<int> id,
      required String operationType,
      required String entityType,
      required String entityId,
      required String payload,
      required String httpMethod,
      required String endpoint,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<DateTime?> lastAttempt,
      Value<String?> lastError,
      Value<String> status,
      Value<int> priority,
    });
typedef $$PendingSyncQueueTableUpdateCompanionBuilder =
    PendingSyncQueueCompanion Function({
      Value<int> id,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> payload,
      Value<String> httpMethod,
      Value<String> endpoint,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<DateTime?> lastAttempt,
      Value<String?> lastError,
      Value<String> status,
      Value<int> priority,
    });

class $$PendingSyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncQueueTable> {
  $$PendingSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncQueueTable> {
  $$PendingSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncQueueTable> {
  $$PendingSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$PendingSyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSyncQueueTable,
          PendingSyncQueueData,
          $$PendingSyncQueueTableFilterComposer,
          $$PendingSyncQueueTableOrderingComposer,
          $$PendingSyncQueueTableAnnotationComposer,
          $$PendingSyncQueueTableCreateCompanionBuilder,
          $$PendingSyncQueueTableUpdateCompanionBuilder,
          (
            PendingSyncQueueData,
            BaseReferences<
              _$AppDatabase,
              $PendingSyncQueueTable,
              PendingSyncQueueData
            >,
          ),
          PendingSyncQueueData,
          PrefetchHooks Function()
        > {
  $$PendingSyncQueueTableTableManager(
    _$AppDatabase db,
    $PendingSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> httpMethod = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => PendingSyncQueueCompanion(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                httpMethod: httpMethod,
                endpoint: endpoint,
                createdAt: createdAt,
                retryCount: retryCount,
                maxRetries: maxRetries,
                lastAttempt: lastAttempt,
                lastError: lastError,
                status: status,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationType,
                required String entityType,
                required String entityId,
                required String payload,
                required String httpMethod,
                required String endpoint,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => PendingSyncQueueCompanion.insert(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                payload: payload,
                httpMethod: httpMethod,
                endpoint: endpoint,
                createdAt: createdAt,
                retryCount: retryCount,
                maxRetries: maxRetries,
                lastAttempt: lastAttempt,
                lastError: lastError,
                status: status,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSyncQueueTable,
      PendingSyncQueueData,
      $$PendingSyncQueueTableFilterComposer,
      $$PendingSyncQueueTableOrderingComposer,
      $$PendingSyncQueueTableAnnotationComposer,
      $$PendingSyncQueueTableCreateCompanionBuilder,
      $$PendingSyncQueueTableUpdateCompanionBuilder,
      (
        PendingSyncQueueData,
        BaseReferences<
          _$AppDatabase,
          $PendingSyncQueueTable,
          PendingSyncQueueData
        >,
      ),
      PendingSyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$CachedExerciseMediaTableCreateCompanionBuilder =
    CachedExerciseMediaCompanion Function({
      required String exerciseId,
      required String mediaType,
      required String remoteUrl,
      required String localPath,
      Value<int?> fileSizeBytes,
      required DateTime downloadedAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$CachedExerciseMediaTableUpdateCompanionBuilder =
    CachedExerciseMediaCompanion Function({
      Value<String> exerciseId,
      Value<String> mediaType,
      Value<String> remoteUrl,
      Value<String> localPath,
      Value<int?> fileSizeBytes,
      Value<DateTime> downloadedAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

class $$CachedExerciseMediaTableFilterComposer
    extends Composer<_$AppDatabase, $CachedExerciseMediaTable> {
  $$CachedExerciseMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExerciseMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedExerciseMediaTable> {
  $$CachedExerciseMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExerciseMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedExerciseMediaTable> {
  $$CachedExerciseMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$CachedExerciseMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedExerciseMediaTable,
          CachedExerciseMediaData,
          $$CachedExerciseMediaTableFilterComposer,
          $$CachedExerciseMediaTableOrderingComposer,
          $$CachedExerciseMediaTableAnnotationComposer,
          $$CachedExerciseMediaTableCreateCompanionBuilder,
          $$CachedExerciseMediaTableUpdateCompanionBuilder,
          (
            CachedExerciseMediaData,
            BaseReferences<
              _$AppDatabase,
              $CachedExerciseMediaTable,
              CachedExerciseMediaData
            >,
          ),
          CachedExerciseMediaData,
          PrefetchHooks Function()
        > {
  $$CachedExerciseMediaTableTableManager(
    _$AppDatabase db,
    $CachedExerciseMediaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExerciseMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExerciseMediaTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedExerciseMediaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> remoteUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExerciseMediaCompanion(
                exerciseId: exerciseId,
                mediaType: mediaType,
                remoteUrl: remoteUrl,
                localPath: localPath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required String mediaType,
                required String remoteUrl,
                required String localPath,
                Value<int?> fileSizeBytes = const Value.absent(),
                required DateTime downloadedAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedExerciseMediaCompanion.insert(
                exerciseId: exerciseId,
                mediaType: mediaType,
                remoteUrl: remoteUrl,
                localPath: localPath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExerciseMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedExerciseMediaTable,
      CachedExerciseMediaData,
      $$CachedExerciseMediaTableFilterComposer,
      $$CachedExerciseMediaTableOrderingComposer,
      $$CachedExerciseMediaTableAnnotationComposer,
      $$CachedExerciseMediaTableCreateCompanionBuilder,
      $$CachedExerciseMediaTableUpdateCompanionBuilder,
      (
        CachedExerciseMediaData,
        BaseReferences<
          _$AppDatabase,
          $CachedExerciseMediaTable,
          CachedExerciseMediaData
        >,
      ),
      CachedExerciseMediaData,
      PrefetchHooks Function()
    >;
typedef $$CachedGymProfilesTableCreateCompanionBuilder =
    CachedGymProfilesCompanion Function({
      required String id,
      required String userId,
      required String profileJson,
      Value<bool> isActive,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedGymProfilesTableUpdateCompanionBuilder =
    CachedGymProfilesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> profileJson,
      Value<bool> isActive,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedGymProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedGymProfilesTable> {
  $$CachedGymProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedGymProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedGymProfilesTable> {
  $$CachedGymProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedGymProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedGymProfilesTable> {
  $$CachedGymProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedGymProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedGymProfilesTable,
          CachedGymProfile,
          $$CachedGymProfilesTableFilterComposer,
          $$CachedGymProfilesTableOrderingComposer,
          $$CachedGymProfilesTableAnnotationComposer,
          $$CachedGymProfilesTableCreateCompanionBuilder,
          $$CachedGymProfilesTableUpdateCompanionBuilder,
          (
            CachedGymProfile,
            BaseReferences<
              _$AppDatabase,
              $CachedGymProfilesTable,
              CachedGymProfile
            >,
          ),
          CachedGymProfile,
          PrefetchHooks Function()
        > {
  $$CachedGymProfilesTableTableManager(
    _$AppDatabase db,
    $CachedGymProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedGymProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedGymProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedGymProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedGymProfilesCompanion(
                id: id,
                userId: userId,
                profileJson: profileJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String profileJson,
                Value<bool> isActive = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedGymProfilesCompanion.insert(
                id: id,
                userId: userId,
                profileJson: profileJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedGymProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedGymProfilesTable,
      CachedGymProfile,
      $$CachedGymProfilesTableFilterComposer,
      $$CachedGymProfilesTableOrderingComposer,
      $$CachedGymProfilesTableAnnotationComposer,
      $$CachedGymProfilesTableCreateCompanionBuilder,
      $$CachedGymProfilesTableUpdateCompanionBuilder,
      (
        CachedGymProfile,
        BaseReferences<
          _$AppDatabase,
          $CachedGymProfilesTable,
          CachedGymProfile
        >,
      ),
      CachedGymProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedFoodsTableCreateCompanionBuilder =
    CachedFoodsCompanion Function({
      Value<int> id,
      required String externalId,
      required String description,
      Value<String?> foodCategory,
      Value<String> source,
      Value<String?> barcode,
      Value<String?> brandName,
      Value<double> servingSizeG,
      Value<String?> householdServing,
      Value<double> calories,
      Value<double> proteinG,
      Value<double> fatG,
      Value<double> carbsG,
      Value<double> fiberG,
      Value<double> sugarG,
      Value<double> sodiumMg,
      Value<double?> vitaminAMcg,
      Value<double?> vitaminCMg,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> potassiumMg,
      Value<String?> imageUrl,
      Value<bool> isFavorite,
      Value<DateTime?> lastUsedAt,
      required DateTime cachedAt,
    });
typedef $$CachedFoodsTableUpdateCompanionBuilder =
    CachedFoodsCompanion Function({
      Value<int> id,
      Value<String> externalId,
      Value<String> description,
      Value<String?> foodCategory,
      Value<String> source,
      Value<String?> barcode,
      Value<String?> brandName,
      Value<double> servingSizeG,
      Value<String?> householdServing,
      Value<double> calories,
      Value<double> proteinG,
      Value<double> fatG,
      Value<double> carbsG,
      Value<double> fiberG,
      Value<double> sugarG,
      Value<double> sodiumMg,
      Value<double?> vitaminAMcg,
      Value<double?> vitaminCMg,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> potassiumMg,
      Value<String?> imageUrl,
      Value<bool> isFavorite,
      Value<DateTime?> lastUsedAt,
      Value<DateTime> cachedAt,
    });

class $$CachedFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodCategory => $composableBuilder(
    column: $table.foodCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdServing => $composableBuilder(
    column: $table.householdServing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminAMcg => $composableBuilder(
    column: $table.vitaminAMcg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodCategory => $composableBuilder(
    column: $table.foodCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdServing => $composableBuilder(
    column: $table.householdServing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminAMcg => $composableBuilder(
    column: $table.vitaminAMcg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFoodsTable> {
  $$CachedFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foodCategory => $composableBuilder(
    column: $table.foodCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<double> get servingSizeG => $composableBuilder(
    column: $table.servingSizeG,
    builder: (column) => column,
  );

  GeneratedColumn<String> get householdServing => $composableBuilder(
    column: $table.householdServing,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get vitaminAMcg => $composableBuilder(
    column: $table.vitaminAMcg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calciumMg =>
      $composableBuilder(column: $table.calciumMg, builder: (column) => column);

  GeneratedColumn<double> get ironMg =>
      $composableBuilder(column: $table.ironMg, builder: (column) => column);

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFoodsTable,
          CachedFood,
          $$CachedFoodsTableFilterComposer,
          $$CachedFoodsTableOrderingComposer,
          $$CachedFoodsTableAnnotationComposer,
          $$CachedFoodsTableCreateCompanionBuilder,
          $$CachedFoodsTableUpdateCompanionBuilder,
          (
            CachedFood,
            BaseReferences<_$AppDatabase, $CachedFoodsTable, CachedFood>,
          ),
          CachedFood,
          PrefetchHooks Function()
        > {
  $$CachedFoodsTableTableManager(_$AppDatabase db, $CachedFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> foodCategory = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<double> servingSizeG = const Value.absent(),
                Value<String?> householdServing = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> sodiumMg = const Value.absent(),
                Value<double?> vitaminAMcg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedFoodsCompanion(
                id: id,
                externalId: externalId,
                description: description,
                foodCategory: foodCategory,
                source: source,
                barcode: barcode,
                brandName: brandName,
                servingSizeG: servingSizeG,
                householdServing: householdServing,
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                vitaminAMcg: vitaminAMcg,
                vitaminCMg: vitaminCMg,
                calciumMg: calciumMg,
                ironMg: ironMg,
                potassiumMg: potassiumMg,
                imageUrl: imageUrl,
                isFavorite: isFavorite,
                lastUsedAt: lastUsedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String externalId,
                required String description,
                Value<String?> foodCategory = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<double> servingSizeG = const Value.absent(),
                Value<String?> householdServing = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fiberG = const Value.absent(),
                Value<double> sugarG = const Value.absent(),
                Value<double> sodiumMg = const Value.absent(),
                Value<double?> vitaminAMcg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                required DateTime cachedAt,
              }) => CachedFoodsCompanion.insert(
                id: id,
                externalId: externalId,
                description: description,
                foodCategory: foodCategory,
                source: source,
                barcode: barcode,
                brandName: brandName,
                servingSizeG: servingSizeG,
                householdServing: householdServing,
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                vitaminAMcg: vitaminAMcg,
                vitaminCMg: vitaminCMg,
                calciumMg: calciumMg,
                ironMg: ironMg,
                potassiumMg: potassiumMg,
                imageUrl: imageUrl,
                isFavorite: isFavorite,
                lastUsedAt: lastUsedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFoodsTable,
      CachedFood,
      $$CachedFoodsTableFilterComposer,
      $$CachedFoodsTableOrderingComposer,
      $$CachedFoodsTableAnnotationComposer,
      $$CachedFoodsTableCreateCompanionBuilder,
      $$CachedFoodsTableUpdateCompanionBuilder,
      (
        CachedFood,
        BaseReferences<_$AppDatabase, $CachedFoodsTable, CachedFood>,
      ),
      CachedFood,
      PrefetchHooks Function()
    >;
typedef $$EmbeddingCacheTableCreateCompanionBuilder =
    EmbeddingCacheCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String searchableText,
      required Uint8List embeddingBlob,
      Value<int> dimension,
      required String modelVersion,
      required DateTime createdAt,
    });
typedef $$EmbeddingCacheTableUpdateCompanionBuilder =
    EmbeddingCacheCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> searchableText,
      Value<Uint8List> embeddingBlob,
      Value<int> dimension,
      Value<String> modelVersion,
      Value<DateTime> createdAt,
    });

class $$EmbeddingCacheTableFilterComposer
    extends Composer<_$AppDatabase, $EmbeddingCacheTable> {
  $$EmbeddingCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchableText => $composableBuilder(
    column: $table.searchableText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embeddingBlob => $composableBuilder(
    column: $table.embeddingBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmbeddingCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $EmbeddingCacheTable> {
  $$EmbeddingCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchableText => $composableBuilder(
    column: $table.searchableText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embeddingBlob => $composableBuilder(
    column: $table.embeddingBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmbeddingCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmbeddingCacheTable> {
  $$EmbeddingCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get searchableText => $composableBuilder(
    column: $table.searchableText,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get embeddingBlob => $composableBuilder(
    column: $table.embeddingBlob,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EmbeddingCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmbeddingCacheTable,
          EmbeddingCacheData,
          $$EmbeddingCacheTableFilterComposer,
          $$EmbeddingCacheTableOrderingComposer,
          $$EmbeddingCacheTableAnnotationComposer,
          $$EmbeddingCacheTableCreateCompanionBuilder,
          $$EmbeddingCacheTableUpdateCompanionBuilder,
          (
            EmbeddingCacheData,
            BaseReferences<
              _$AppDatabase,
              $EmbeddingCacheTable,
              EmbeddingCacheData
            >,
          ),
          EmbeddingCacheData,
          PrefetchHooks Function()
        > {
  $$EmbeddingCacheTableTableManager(
    _$AppDatabase db,
    $EmbeddingCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmbeddingCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmbeddingCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmbeddingCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> searchableText = const Value.absent(),
                Value<Uint8List> embeddingBlob = const Value.absent(),
                Value<int> dimension = const Value.absent(),
                Value<String> modelVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EmbeddingCacheCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                searchableText: searchableText,
                embeddingBlob: embeddingBlob,
                dimension: dimension,
                modelVersion: modelVersion,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String searchableText,
                required Uint8List embeddingBlob,
                Value<int> dimension = const Value.absent(),
                required String modelVersion,
                required DateTime createdAt,
              }) => EmbeddingCacheCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                searchableText: searchableText,
                embeddingBlob: embeddingBlob,
                dimension: dimension,
                modelVersion: modelVersion,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmbeddingCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmbeddingCacheTable,
      EmbeddingCacheData,
      $$EmbeddingCacheTableFilterComposer,
      $$EmbeddingCacheTableOrderingComposer,
      $$EmbeddingCacheTableAnnotationComposer,
      $$EmbeddingCacheTableCreateCompanionBuilder,
      $$EmbeddingCacheTableUpdateCompanionBuilder,
      (
        EmbeddingCacheData,
        BaseReferences<_$AppDatabase, $EmbeddingCacheTable, EmbeddingCacheData>,
      ),
      EmbeddingCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedWorkoutsTableTableManager get cachedWorkouts =>
      $$CachedWorkoutsTableTableManager(_db, _db.cachedWorkouts);
  $$CachedExercisesTableTableManager get cachedExercises =>
      $$CachedExercisesTableTableManager(_db, _db.cachedExercises);
  $$CachedUserProfilesTableTableManager get cachedUserProfiles =>
      $$CachedUserProfilesTableTableManager(_db, _db.cachedUserProfiles);
  $$CachedWorkoutLogsTableTableManager get cachedWorkoutLogs =>
      $$CachedWorkoutLogsTableTableManager(_db, _db.cachedWorkoutLogs);
  $$PendingSyncQueueTableTableManager get pendingSyncQueue =>
      $$PendingSyncQueueTableTableManager(_db, _db.pendingSyncQueue);
  $$CachedExerciseMediaTableTableManager get cachedExerciseMedia =>
      $$CachedExerciseMediaTableTableManager(_db, _db.cachedExerciseMedia);
  $$CachedGymProfilesTableTableManager get cachedGymProfiles =>
      $$CachedGymProfilesTableTableManager(_db, _db.cachedGymProfiles);
  $$CachedFoodsTableTableManager get cachedFoods =>
      $$CachedFoodsTableTableManager(_db, _db.cachedFoods);
  $$EmbeddingCacheTableTableManager get embeddingCache =>
      $$EmbeddingCacheTableTableManager(_db, _db.embeddingCache);
}
