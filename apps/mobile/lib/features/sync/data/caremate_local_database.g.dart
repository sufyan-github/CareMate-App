// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caremate_local_database.dart';

// ignore_for_file: type=lint
class $LocalAccountBindingsTable extends LocalAccountBindings
    with TableInfo<$LocalAccountBindingsTable, LocalAccountBinding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountBindingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slot, userId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_account_bindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAccountBinding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  LocalAccountBinding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccountBinding(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalAccountBindingsTable createAlias(String alias) {
    return $LocalAccountBindingsTable(attachedDatabase, alias);
  }
}

class LocalAccountBinding extends DataClass
    implements Insertable<LocalAccountBinding> {
  final int slot;
  final String userId;
  final DateTime updatedAt;
  const LocalAccountBinding({
    required this.slot,
    required this.userId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<int>(slot);
    map['user_id'] = Variable<String>(userId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAccountBindingsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountBindingsCompanion(
      slot: Value(slot),
      userId: Value(userId),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAccountBinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccountBinding(
      slot: serializer.fromJson<int>(json['slot']),
      userId: serializer.fromJson<String>(json['userId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<int>(slot),
      'userId': serializer.toJson<String>(userId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAccountBinding copyWith({
    int? slot,
    String? userId,
    DateTime? updatedAt,
  }) => LocalAccountBinding(
    slot: slot ?? this.slot,
    userId: userId ?? this.userId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAccountBinding copyWithCompanion(LocalAccountBindingsCompanion data) {
    return LocalAccountBinding(
      slot: data.slot.present ? data.slot.value : this.slot,
      userId: data.userId.present ? data.userId.value : this.userId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountBinding(')
          ..write('slot: $slot, ')
          ..write('userId: $userId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slot, userId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccountBinding &&
          other.slot == this.slot &&
          other.userId == this.userId &&
          other.updatedAt == this.updatedAt);
}

class LocalAccountBindingsCompanion
    extends UpdateCompanion<LocalAccountBinding> {
  final Value<int> slot;
  final Value<String> userId;
  final Value<DateTime> updatedAt;
  const LocalAccountBindingsCompanion({
    this.slot = const Value.absent(),
    this.userId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalAccountBindingsCompanion.insert({
    this.slot = const Value.absent(),
    required String userId,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<LocalAccountBinding> custom({
    Expression<int>? slot,
    Expression<String>? userId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (userId != null) 'user_id': userId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalAccountBindingsCompanion copyWith({
    Value<int>? slot,
    Value<String>? userId,
    Value<DateTime>? updatedAt,
  }) {
    return LocalAccountBindingsCompanion(
      slot: slot ?? this.slot,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountBindingsCompanion(')
          ..write('slot: $slot, ')
          ..write('userId: $userId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedPatientProfilesTable extends CachedPatientProfiles
    with TableInfo<$CachedPatientProfilesTable, CachedPatientProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPatientProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessRoleMeta = const VerificationMeta(
    'accessRole',
  );
  @override
  late final GeneratedColumn<String> accessRole = GeneratedColumn<String>(
    'access_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canManageMeta = const VerificationMeta(
    'canManage',
  );
  @override
  late final GeneratedColumn<bool> canManage = GeneratedColumn<bool>(
    'can_manage',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_manage" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canReceiveMissedDoseAlertsMeta =
      const VerificationMeta('canReceiveMissedDoseAlerts');
  @override
  late final GeneratedColumn<bool> canReceiveMissedDoseAlerts =
      GeneratedColumn<bool>(
        'can_receive_missed_dose_alerts',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("can_receive_missed_dose_alerts" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _canViewMedicationPlanMeta =
      const VerificationMeta('canViewMedicationPlan');
  @override
  late final GeneratedColumn<bool> canViewMedicationPlan =
      GeneratedColumn<bool>(
        'can_view_medication_plan',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("can_view_medication_plan" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _missedDoseGraceMinutesMeta =
      const VerificationMeta('missedDoseGraceMinutes');
  @override
  late final GeneratedColumn<int> missedDoseGraceMinutes = GeneratedColumn<int>(
    'missed_dose_grace_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(45),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    timezone,
    version,
    accessRole,
    canManage,
    canReceiveMissedDoseAlerts,
    canViewMedicationPlan,
    missedDoseGraceMinutes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_patient_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPatientProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('access_role')) {
      context.handle(
        _accessRoleMeta,
        accessRole.isAcceptableOrUnknown(data['access_role']!, _accessRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_accessRoleMeta);
    }
    if (data.containsKey('can_manage')) {
      context.handle(
        _canManageMeta,
        canManage.isAcceptableOrUnknown(data['can_manage']!, _canManageMeta),
      );
    } else if (isInserting) {
      context.missing(_canManageMeta);
    }
    if (data.containsKey('can_receive_missed_dose_alerts')) {
      context.handle(
        _canReceiveMissedDoseAlertsMeta,
        canReceiveMissedDoseAlerts.isAcceptableOrUnknown(
          data['can_receive_missed_dose_alerts']!,
          _canReceiveMissedDoseAlertsMeta,
        ),
      );
    }
    if (data.containsKey('can_view_medication_plan')) {
      context.handle(
        _canViewMedicationPlanMeta,
        canViewMedicationPlan.isAcceptableOrUnknown(
          data['can_view_medication_plan']!,
          _canViewMedicationPlanMeta,
        ),
      );
    }
    if (data.containsKey('missed_dose_grace_minutes')) {
      context.handle(
        _missedDoseGraceMinutesMeta,
        missedDoseGraceMinutes.isAcceptableOrUnknown(
          data['missed_dose_grace_minutes']!,
          _missedDoseGraceMinutesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPatientProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPatientProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      accessRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_role'],
      )!,
      canManage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_manage'],
      )!,
      canReceiveMissedDoseAlerts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_receive_missed_dose_alerts'],
      )!,
      canViewMedicationPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_view_medication_plan'],
      )!,
      missedDoseGraceMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missed_dose_grace_minutes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedPatientProfilesTable createAlias(String alias) {
    return $CachedPatientProfilesTable(attachedDatabase, alias);
  }
}

class CachedPatientProfile extends DataClass
    implements Insertable<CachedPatientProfile> {
  final String id;
  final String displayName;
  final String timezone;
  final int version;
  final String accessRole;
  final bool canManage;
  final bool canReceiveMissedDoseAlerts;
  final bool canViewMedicationPlan;
  final int missedDoseGraceMinutes;
  final DateTime updatedAt;
  const CachedPatientProfile({
    required this.id,
    required this.displayName,
    required this.timezone,
    required this.version,
    required this.accessRole,
    required this.canManage,
    required this.canReceiveMissedDoseAlerts,
    required this.canViewMedicationPlan,
    required this.missedDoseGraceMinutes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['timezone'] = Variable<String>(timezone);
    map['version'] = Variable<int>(version);
    map['access_role'] = Variable<String>(accessRole);
    map['can_manage'] = Variable<bool>(canManage);
    map['can_receive_missed_dose_alerts'] = Variable<bool>(
      canReceiveMissedDoseAlerts,
    );
    map['can_view_medication_plan'] = Variable<bool>(canViewMedicationPlan);
    map['missed_dose_grace_minutes'] = Variable<int>(missedDoseGraceMinutes);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedPatientProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedPatientProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      timezone: Value(timezone),
      version: Value(version),
      accessRole: Value(accessRole),
      canManage: Value(canManage),
      canReceiveMissedDoseAlerts: Value(canReceiveMissedDoseAlerts),
      canViewMedicationPlan: Value(canViewMedicationPlan),
      missedDoseGraceMinutes: Value(missedDoseGraceMinutes),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedPatientProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPatientProfile(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      timezone: serializer.fromJson<String>(json['timezone']),
      version: serializer.fromJson<int>(json['version']),
      accessRole: serializer.fromJson<String>(json['accessRole']),
      canManage: serializer.fromJson<bool>(json['canManage']),
      canReceiveMissedDoseAlerts: serializer.fromJson<bool>(
        json['canReceiveMissedDoseAlerts'],
      ),
      canViewMedicationPlan: serializer.fromJson<bool>(
        json['canViewMedicationPlan'],
      ),
      missedDoseGraceMinutes: serializer.fromJson<int>(
        json['missedDoseGraceMinutes'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'timezone': serializer.toJson<String>(timezone),
      'version': serializer.toJson<int>(version),
      'accessRole': serializer.toJson<String>(accessRole),
      'canManage': serializer.toJson<bool>(canManage),
      'canReceiveMissedDoseAlerts': serializer.toJson<bool>(
        canReceiveMissedDoseAlerts,
      ),
      'canViewMedicationPlan': serializer.toJson<bool>(canViewMedicationPlan),
      'missedDoseGraceMinutes': serializer.toJson<int>(missedDoseGraceMinutes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedPatientProfile copyWith({
    String? id,
    String? displayName,
    String? timezone,
    int? version,
    String? accessRole,
    bool? canManage,
    bool? canReceiveMissedDoseAlerts,
    bool? canViewMedicationPlan,
    int? missedDoseGraceMinutes,
    DateTime? updatedAt,
  }) => CachedPatientProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    timezone: timezone ?? this.timezone,
    version: version ?? this.version,
    accessRole: accessRole ?? this.accessRole,
    canManage: canManage ?? this.canManage,
    canReceiveMissedDoseAlerts:
        canReceiveMissedDoseAlerts ?? this.canReceiveMissedDoseAlerts,
    canViewMedicationPlan: canViewMedicationPlan ?? this.canViewMedicationPlan,
    missedDoseGraceMinutes:
        missedDoseGraceMinutes ?? this.missedDoseGraceMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedPatientProfile copyWithCompanion(CachedPatientProfilesCompanion data) {
    return CachedPatientProfile(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      version: data.version.present ? data.version.value : this.version,
      accessRole: data.accessRole.present
          ? data.accessRole.value
          : this.accessRole,
      canManage: data.canManage.present ? data.canManage.value : this.canManage,
      canReceiveMissedDoseAlerts: data.canReceiveMissedDoseAlerts.present
          ? data.canReceiveMissedDoseAlerts.value
          : this.canReceiveMissedDoseAlerts,
      canViewMedicationPlan: data.canViewMedicationPlan.present
          ? data.canViewMedicationPlan.value
          : this.canViewMedicationPlan,
      missedDoseGraceMinutes: data.missedDoseGraceMinutes.present
          ? data.missedDoseGraceMinutes.value
          : this.missedDoseGraceMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatientProfile(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('timezone: $timezone, ')
          ..write('version: $version, ')
          ..write('accessRole: $accessRole, ')
          ..write('canManage: $canManage, ')
          ..write('canReceiveMissedDoseAlerts: $canReceiveMissedDoseAlerts, ')
          ..write('canViewMedicationPlan: $canViewMedicationPlan, ')
          ..write('missedDoseGraceMinutes: $missedDoseGraceMinutes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    timezone,
    version,
    accessRole,
    canManage,
    canReceiveMissedDoseAlerts,
    canViewMedicationPlan,
    missedDoseGraceMinutes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPatientProfile &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.timezone == this.timezone &&
          other.version == this.version &&
          other.accessRole == this.accessRole &&
          other.canManage == this.canManage &&
          other.canReceiveMissedDoseAlerts == this.canReceiveMissedDoseAlerts &&
          other.canViewMedicationPlan == this.canViewMedicationPlan &&
          other.missedDoseGraceMinutes == this.missedDoseGraceMinutes &&
          other.updatedAt == this.updatedAt);
}

class CachedPatientProfilesCompanion
    extends UpdateCompanion<CachedPatientProfile> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> timezone;
  final Value<int> version;
  final Value<String> accessRole;
  final Value<bool> canManage;
  final Value<bool> canReceiveMissedDoseAlerts;
  final Value<bool> canViewMedicationPlan;
  final Value<int> missedDoseGraceMinutes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedPatientProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.timezone = const Value.absent(),
    this.version = const Value.absent(),
    this.accessRole = const Value.absent(),
    this.canManage = const Value.absent(),
    this.canReceiveMissedDoseAlerts = const Value.absent(),
    this.canViewMedicationPlan = const Value.absent(),
    this.missedDoseGraceMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPatientProfilesCompanion.insert({
    required String id,
    required String displayName,
    required String timezone,
    required int version,
    required String accessRole,
    required bool canManage,
    this.canReceiveMissedDoseAlerts = const Value.absent(),
    this.canViewMedicationPlan = const Value.absent(),
    this.missedDoseGraceMinutes = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       timezone = Value(timezone),
       version = Value(version),
       accessRole = Value(accessRole),
       canManage = Value(canManage),
       updatedAt = Value(updatedAt);
  static Insertable<CachedPatientProfile> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? timezone,
    Expression<int>? version,
    Expression<String>? accessRole,
    Expression<bool>? canManage,
    Expression<bool>? canReceiveMissedDoseAlerts,
    Expression<bool>? canViewMedicationPlan,
    Expression<int>? missedDoseGraceMinutes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (timezone != null) 'timezone': timezone,
      if (version != null) 'version': version,
      if (accessRole != null) 'access_role': accessRole,
      if (canManage != null) 'can_manage': canManage,
      if (canReceiveMissedDoseAlerts != null)
        'can_receive_missed_dose_alerts': canReceiveMissedDoseAlerts,
      if (canViewMedicationPlan != null)
        'can_view_medication_plan': canViewMedicationPlan,
      if (missedDoseGraceMinutes != null)
        'missed_dose_grace_minutes': missedDoseGraceMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPatientProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? timezone,
    Value<int>? version,
    Value<String>? accessRole,
    Value<bool>? canManage,
    Value<bool>? canReceiveMissedDoseAlerts,
    Value<bool>? canViewMedicationPlan,
    Value<int>? missedDoseGraceMinutes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedPatientProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      version: version ?? this.version,
      accessRole: accessRole ?? this.accessRole,
      canManage: canManage ?? this.canManage,
      canReceiveMissedDoseAlerts:
          canReceiveMissedDoseAlerts ?? this.canReceiveMissedDoseAlerts,
      canViewMedicationPlan:
          canViewMedicationPlan ?? this.canViewMedicationPlan,
      missedDoseGraceMinutes:
          missedDoseGraceMinutes ?? this.missedDoseGraceMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (accessRole.present) {
      map['access_role'] = Variable<String>(accessRole.value);
    }
    if (canManage.present) {
      map['can_manage'] = Variable<bool>(canManage.value);
    }
    if (canReceiveMissedDoseAlerts.present) {
      map['can_receive_missed_dose_alerts'] = Variable<bool>(
        canReceiveMissedDoseAlerts.value,
      );
    }
    if (canViewMedicationPlan.present) {
      map['can_view_medication_plan'] = Variable<bool>(
        canViewMedicationPlan.value,
      );
    }
    if (missedDoseGraceMinutes.present) {
      map['missed_dose_grace_minutes'] = Variable<int>(
        missedDoseGraceMinutes.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatientProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('timezone: $timezone, ')
          ..write('version: $version, ')
          ..write('accessRole: $accessRole, ')
          ..write('canManage: $canManage, ')
          ..write('canReceiveMissedDoseAlerts: $canReceiveMissedDoseAlerts, ')
          ..write('canViewMedicationPlan: $canViewMedicationPlan, ')
          ..write('missedDoseGraceMinutes: $missedDoseGraceMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMedicationsTable extends CachedMedications
    with TableInfo<$CachedMedicationsTable, CachedMedication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealRelationMeta = const VerificationMeta(
    'mealRelation',
  );
  @override
  late final GeneratedColumn<String> mealRelation = GeneratedColumn<String>(
    'meal_relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNSPECIFIED'),
  );
  static const VerificationMeta _quantityLabelMeta = const VerificationMeta(
    'quantityLabel',
  );
  @override
  late final GeneratedColumn<String> quantityLabel = GeneratedColumn<String>(
    'quantity_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthLabelMeta = const VerificationMeta(
    'strengthLabel',
  );
  @override
  late final GeneratedColumn<String> strengthLabel = GeneratedColumn<String>(
    'strength_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeScheduleJsonMeta =
      const VerificationMeta('activeScheduleJson');
  @override
  late final GeneratedColumn<String> activeScheduleJson =
      GeneratedColumn<String>(
        'active_schedule_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    displayName,
    form,
    mealRelation,
    quantityLabel,
    status,
    strengthLabel,
    activeScheduleJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMedication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    } else if (isInserting) {
      context.missing(_formMeta);
    }
    if (data.containsKey('meal_relation')) {
      context.handle(
        _mealRelationMeta,
        mealRelation.isAcceptableOrUnknown(
          data['meal_relation']!,
          _mealRelationMeta,
        ),
      );
    }
    if (data.containsKey('quantity_label')) {
      context.handle(
        _quantityLabelMeta,
        quantityLabel.isAcceptableOrUnknown(
          data['quantity_label']!,
          _quantityLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityLabelMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('strength_label')) {
      context.handle(
        _strengthLabelMeta,
        strengthLabel.isAcceptableOrUnknown(
          data['strength_label']!,
          _strengthLabelMeta,
        ),
      );
    }
    if (data.containsKey('active_schedule_json')) {
      context.handle(
        _activeScheduleJsonMeta,
        activeScheduleJson.isAcceptableOrUnknown(
          data['active_schedule_json']!,
          _activeScheduleJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMedication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMedication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      )!,
      mealRelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_relation'],
      )!,
      quantityLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_label'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      strengthLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength_label'],
      ),
      activeScheduleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_schedule_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedMedicationsTable createAlias(String alias) {
    return $CachedMedicationsTable(attachedDatabase, alias);
  }
}

class CachedMedication extends DataClass
    implements Insertable<CachedMedication> {
  final String id;
  final String profileId;
  final String displayName;
  final String form;
  final String mealRelation;
  final String quantityLabel;
  final String status;
  final String? strengthLabel;
  final String? activeScheduleJson;
  final DateTime updatedAt;
  const CachedMedication({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.form,
    required this.mealRelation,
    required this.quantityLabel,
    required this.status,
    this.strengthLabel,
    this.activeScheduleJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['display_name'] = Variable<String>(displayName);
    map['form'] = Variable<String>(form);
    map['meal_relation'] = Variable<String>(mealRelation);
    map['quantity_label'] = Variable<String>(quantityLabel);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || strengthLabel != null) {
      map['strength_label'] = Variable<String>(strengthLabel);
    }
    if (!nullToAbsent || activeScheduleJson != null) {
      map['active_schedule_json'] = Variable<String>(activeScheduleJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMedicationsCompanion toCompanion(bool nullToAbsent) {
    return CachedMedicationsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      displayName: Value(displayName),
      form: Value(form),
      mealRelation: Value(mealRelation),
      quantityLabel: Value(quantityLabel),
      status: Value(status),
      strengthLabel: strengthLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(strengthLabel),
      activeScheduleJson: activeScheduleJson == null && nullToAbsent
          ? const Value.absent()
          : Value(activeScheduleJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMedication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMedication(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      form: serializer.fromJson<String>(json['form']),
      mealRelation: serializer.fromJson<String>(json['mealRelation']),
      quantityLabel: serializer.fromJson<String>(json['quantityLabel']),
      status: serializer.fromJson<String>(json['status']),
      strengthLabel: serializer.fromJson<String?>(json['strengthLabel']),
      activeScheduleJson: serializer.fromJson<String?>(
        json['activeScheduleJson'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'displayName': serializer.toJson<String>(displayName),
      'form': serializer.toJson<String>(form),
      'mealRelation': serializer.toJson<String>(mealRelation),
      'quantityLabel': serializer.toJson<String>(quantityLabel),
      'status': serializer.toJson<String>(status),
      'strengthLabel': serializer.toJson<String?>(strengthLabel),
      'activeScheduleJson': serializer.toJson<String?>(activeScheduleJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMedication copyWith({
    String? id,
    String? profileId,
    String? displayName,
    String? form,
    String? mealRelation,
    String? quantityLabel,
    String? status,
    Value<String?> strengthLabel = const Value.absent(),
    Value<String?> activeScheduleJson = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedMedication(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    displayName: displayName ?? this.displayName,
    form: form ?? this.form,
    mealRelation: mealRelation ?? this.mealRelation,
    quantityLabel: quantityLabel ?? this.quantityLabel,
    status: status ?? this.status,
    strengthLabel: strengthLabel.present
        ? strengthLabel.value
        : this.strengthLabel,
    activeScheduleJson: activeScheduleJson.present
        ? activeScheduleJson.value
        : this.activeScheduleJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMedication copyWithCompanion(CachedMedicationsCompanion data) {
    return CachedMedication(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      form: data.form.present ? data.form.value : this.form,
      mealRelation: data.mealRelation.present
          ? data.mealRelation.value
          : this.mealRelation,
      quantityLabel: data.quantityLabel.present
          ? data.quantityLabel.value
          : this.quantityLabel,
      status: data.status.present ? data.status.value : this.status,
      strengthLabel: data.strengthLabel.present
          ? data.strengthLabel.value
          : this.strengthLabel,
      activeScheduleJson: data.activeScheduleJson.present
          ? data.activeScheduleJson.value
          : this.activeScheduleJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedication(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('displayName: $displayName, ')
          ..write('form: $form, ')
          ..write('mealRelation: $mealRelation, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('status: $status, ')
          ..write('strengthLabel: $strengthLabel, ')
          ..write('activeScheduleJson: $activeScheduleJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    displayName,
    form,
    mealRelation,
    quantityLabel,
    status,
    strengthLabel,
    activeScheduleJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMedication &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.displayName == this.displayName &&
          other.form == this.form &&
          other.mealRelation == this.mealRelation &&
          other.quantityLabel == this.quantityLabel &&
          other.status == this.status &&
          other.strengthLabel == this.strengthLabel &&
          other.activeScheduleJson == this.activeScheduleJson &&
          other.updatedAt == this.updatedAt);
}

class CachedMedicationsCompanion extends UpdateCompanion<CachedMedication> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> displayName;
  final Value<String> form;
  final Value<String> mealRelation;
  final Value<String> quantityLabel;
  final Value<String> status;
  final Value<String?> strengthLabel;
  final Value<String?> activeScheduleJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMedicationsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.form = const Value.absent(),
    this.mealRelation = const Value.absent(),
    this.quantityLabel = const Value.absent(),
    this.status = const Value.absent(),
    this.strengthLabel = const Value.absent(),
    this.activeScheduleJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMedicationsCompanion.insert({
    required String id,
    required String profileId,
    required String displayName,
    required String form,
    this.mealRelation = const Value.absent(),
    required String quantityLabel,
    required String status,
    this.strengthLabel = const Value.absent(),
    this.activeScheduleJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       displayName = Value(displayName),
       form = Value(form),
       quantityLabel = Value(quantityLabel),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMedication> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? displayName,
    Expression<String>? form,
    Expression<String>? mealRelation,
    Expression<String>? quantityLabel,
    Expression<String>? status,
    Expression<String>? strengthLabel,
    Expression<String>? activeScheduleJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (displayName != null) 'display_name': displayName,
      if (form != null) 'form': form,
      if (mealRelation != null) 'meal_relation': mealRelation,
      if (quantityLabel != null) 'quantity_label': quantityLabel,
      if (status != null) 'status': status,
      if (strengthLabel != null) 'strength_label': strengthLabel,
      if (activeScheduleJson != null)
        'active_schedule_json': activeScheduleJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? displayName,
    Value<String>? form,
    Value<String>? mealRelation,
    Value<String>? quantityLabel,
    Value<String>? status,
    Value<String?>? strengthLabel,
    Value<String?>? activeScheduleJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMedicationsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      displayName: displayName ?? this.displayName,
      form: form ?? this.form,
      mealRelation: mealRelation ?? this.mealRelation,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      status: status ?? this.status,
      strengthLabel: strengthLabel ?? this.strengthLabel,
      activeScheduleJson: activeScheduleJson ?? this.activeScheduleJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (mealRelation.present) {
      map['meal_relation'] = Variable<String>(mealRelation.value);
    }
    if (quantityLabel.present) {
      map['quantity_label'] = Variable<String>(quantityLabel.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (strengthLabel.present) {
      map['strength_label'] = Variable<String>(strengthLabel.value);
    }
    if (activeScheduleJson.present) {
      map['active_schedule_json'] = Variable<String>(activeScheduleJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedicationsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('displayName: $displayName, ')
          ..write('form: $form, ')
          ..write('mealRelation: $mealRelation, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('status: $status, ')
          ..write('strengthLabel: $strengthLabel, ')
          ..write('activeScheduleJson: $activeScheduleJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDoseOccurrencesTable extends CachedDoseOccurrences
    with TableInfo<$CachedDoseOccurrencesTable, CachedDoseOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDoseOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedAtMeta = const VerificationMeta(
    'plannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> plannedAt = GeneratedColumn<DateTime>(
    'planned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedLocalDateTimeMeta =
      const VerificationMeta('plannedLocalDateTime');
  @override
  late final GeneratedColumn<String> plannedLocalDateTime =
      GeneratedColumn<String>(
        'planned_local_date_time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _quantityLabelMeta = const VerificationMeta(
    'quantityLabel',
  );
  @override
  late final GeneratedColumn<String> quantityLabel = GeneratedColumn<String>(
    'quantity_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleRevisionMeta = const VerificationMeta(
    'ruleRevision',
  );
  @override
  late final GeneratedColumn<int> ruleRevision = GeneratedColumn<int>(
    'rule_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missedAtMeta = const VerificationMeta(
    'missedAt',
  );
  @override
  late final GeneratedColumn<DateTime> missedAt = GeneratedColumn<DateTime>(
    'missed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderSentAtMeta = const VerificationMeta(
    'reminderSentAt',
  );
  @override
  late final GeneratedColumn<DateTime> reminderSentAt =
      GeneratedColumn<DateTime>(
        'reminder_sent_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _responseDueAtMeta = const VerificationMeta(
    'responseDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> responseDueAt =
      GeneratedColumn<DateTime>(
        'response_due_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _snoozeCountMeta = const VerificationMeta(
    'snoozeCount',
  );
  @override
  late final GeneratedColumn<int> snoozeCount = GeneratedColumn<int>(
    'snooze_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timingClassificationMeta =
      const VerificationMeta('timingClassification');
  @override
  late final GeneratedColumn<String> timingClassification =
      GeneratedColumn<String>(
        'timing_classification',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pendingMutationIdMeta = const VerificationMeta(
    'pendingMutationId',
  );
  @override
  late final GeneratedColumn<String> pendingMutationId =
      GeneratedColumn<String>(
        'pending_mutation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorCodeMeta = const VerificationMeta(
    'syncErrorCode',
  );
  @override
  late final GeneratedColumn<String> syncErrorCode = GeneratedColumn<String>(
    'sync_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    medicationName,
    plannedAt,
    plannedLocalDateTime,
    quantityLabel,
    ruleRevision,
    status,
    version,
    confirmedAt,
    missedAt,
    reminderSentAt,
    responseDueAt,
    snoozeCount,
    snoozedUntil,
    timingClassification,
    pendingMutationId,
    syncErrorCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_dose_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDoseOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationNameMeta);
    }
    if (data.containsKey('planned_at')) {
      context.handle(
        _plannedAtMeta,
        plannedAt.isAcceptableOrUnknown(data['planned_at']!, _plannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedAtMeta);
    }
    if (data.containsKey('planned_local_date_time')) {
      context.handle(
        _plannedLocalDateTimeMeta,
        plannedLocalDateTime.isAcceptableOrUnknown(
          data['planned_local_date_time']!,
          _plannedLocalDateTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedLocalDateTimeMeta);
    }
    if (data.containsKey('quantity_label')) {
      context.handle(
        _quantityLabelMeta,
        quantityLabel.isAcceptableOrUnknown(
          data['quantity_label']!,
          _quantityLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityLabelMeta);
    }
    if (data.containsKey('rule_revision')) {
      context.handle(
        _ruleRevisionMeta,
        ruleRevision.isAcceptableOrUnknown(
          data['rule_revision']!,
          _ruleRevisionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('missed_at')) {
      context.handle(
        _missedAtMeta,
        missedAt.isAcceptableOrUnknown(data['missed_at']!, _missedAtMeta),
      );
    }
    if (data.containsKey('reminder_sent_at')) {
      context.handle(
        _reminderSentAtMeta,
        reminderSentAt.isAcceptableOrUnknown(
          data['reminder_sent_at']!,
          _reminderSentAtMeta,
        ),
      );
    }
    if (data.containsKey('response_due_at')) {
      context.handle(
        _responseDueAtMeta,
        responseDueAt.isAcceptableOrUnknown(
          data['response_due_at']!,
          _responseDueAtMeta,
        ),
      );
    }
    if (data.containsKey('snooze_count')) {
      context.handle(
        _snoozeCountMeta,
        snoozeCount.isAcceptableOrUnknown(
          data['snooze_count']!,
          _snoozeCountMeta,
        ),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('timing_classification')) {
      context.handle(
        _timingClassificationMeta,
        timingClassification.isAcceptableOrUnknown(
          data['timing_classification']!,
          _timingClassificationMeta,
        ),
      );
    }
    if (data.containsKey('pending_mutation_id')) {
      context.handle(
        _pendingMutationIdMeta,
        pendingMutationId.isAcceptableOrUnknown(
          data['pending_mutation_id']!,
          _pendingMutationIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_error_code')) {
      context.handle(
        _syncErrorCodeMeta,
        syncErrorCode.isAcceptableOrUnknown(
          data['sync_error_code']!,
          _syncErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDoseOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDoseOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      )!,
      plannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_at'],
      )!,
      plannedLocalDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_local_date_time'],
      )!,
      quantityLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_label'],
      )!,
      ruleRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_revision'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
      missedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}missed_at'],
      ),
      reminderSentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_sent_at'],
      ),
      responseDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}response_due_at'],
      ),
      snoozeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_count'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      timingClassification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timing_classification'],
      ),
      pendingMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_mutation_id'],
      ),
      syncErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error_code'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedDoseOccurrencesTable createAlias(String alias) {
    return $CachedDoseOccurrencesTable(attachedDatabase, alias);
  }
}

class CachedDoseOccurrence extends DataClass
    implements Insertable<CachedDoseOccurrence> {
  final String id;
  final String profileId;
  final String medicationName;
  final DateTime plannedAt;
  final String plannedLocalDateTime;
  final String quantityLabel;
  final int ruleRevision;
  final String status;
  final int version;
  final DateTime? confirmedAt;
  final DateTime? missedAt;
  final DateTime? reminderSentAt;
  final DateTime? responseDueAt;
  final int snoozeCount;
  final DateTime? snoozedUntil;
  final String? timingClassification;
  final String? pendingMutationId;
  final String? syncErrorCode;
  final DateTime updatedAt;
  const CachedDoseOccurrence({
    required this.id,
    required this.profileId,
    required this.medicationName,
    required this.plannedAt,
    required this.plannedLocalDateTime,
    required this.quantityLabel,
    required this.ruleRevision,
    required this.status,
    required this.version,
    this.confirmedAt,
    this.missedAt,
    this.reminderSentAt,
    this.responseDueAt,
    required this.snoozeCount,
    this.snoozedUntil,
    this.timingClassification,
    this.pendingMutationId,
    this.syncErrorCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['medication_name'] = Variable<String>(medicationName);
    map['planned_at'] = Variable<DateTime>(plannedAt);
    map['planned_local_date_time'] = Variable<String>(plannedLocalDateTime);
    map['quantity_label'] = Variable<String>(quantityLabel);
    map['rule_revision'] = Variable<int>(ruleRevision);
    map['status'] = Variable<String>(status);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    if (!nullToAbsent || missedAt != null) {
      map['missed_at'] = Variable<DateTime>(missedAt);
    }
    if (!nullToAbsent || reminderSentAt != null) {
      map['reminder_sent_at'] = Variable<DateTime>(reminderSentAt);
    }
    if (!nullToAbsent || responseDueAt != null) {
      map['response_due_at'] = Variable<DateTime>(responseDueAt);
    }
    map['snooze_count'] = Variable<int>(snoozeCount);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    if (!nullToAbsent || timingClassification != null) {
      map['timing_classification'] = Variable<String>(timingClassification);
    }
    if (!nullToAbsent || pendingMutationId != null) {
      map['pending_mutation_id'] = Variable<String>(pendingMutationId);
    }
    if (!nullToAbsent || syncErrorCode != null) {
      map['sync_error_code'] = Variable<String>(syncErrorCode);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedDoseOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return CachedDoseOccurrencesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      medicationName: Value(medicationName),
      plannedAt: Value(plannedAt),
      plannedLocalDateTime: Value(plannedLocalDateTime),
      quantityLabel: Value(quantityLabel),
      ruleRevision: Value(ruleRevision),
      status: Value(status),
      version: Value(version),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      missedAt: missedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(missedAt),
      reminderSentAt: reminderSentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderSentAt),
      responseDueAt: responseDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(responseDueAt),
      snoozeCount: Value(snoozeCount),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      timingClassification: timingClassification == null && nullToAbsent
          ? const Value.absent()
          : Value(timingClassification),
      pendingMutationId: pendingMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingMutationId),
      syncErrorCode: syncErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(syncErrorCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedDoseOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDoseOccurrence(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      medicationName: serializer.fromJson<String>(json['medicationName']),
      plannedAt: serializer.fromJson<DateTime>(json['plannedAt']),
      plannedLocalDateTime: serializer.fromJson<String>(
        json['plannedLocalDateTime'],
      ),
      quantityLabel: serializer.fromJson<String>(json['quantityLabel']),
      ruleRevision: serializer.fromJson<int>(json['ruleRevision']),
      status: serializer.fromJson<String>(json['status']),
      version: serializer.fromJson<int>(json['version']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
      missedAt: serializer.fromJson<DateTime?>(json['missedAt']),
      reminderSentAt: serializer.fromJson<DateTime?>(json['reminderSentAt']),
      responseDueAt: serializer.fromJson<DateTime?>(json['responseDueAt']),
      snoozeCount: serializer.fromJson<int>(json['snoozeCount']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      timingClassification: serializer.fromJson<String?>(
        json['timingClassification'],
      ),
      pendingMutationId: serializer.fromJson<String?>(
        json['pendingMutationId'],
      ),
      syncErrorCode: serializer.fromJson<String?>(json['syncErrorCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'medicationName': serializer.toJson<String>(medicationName),
      'plannedAt': serializer.toJson<DateTime>(plannedAt),
      'plannedLocalDateTime': serializer.toJson<String>(plannedLocalDateTime),
      'quantityLabel': serializer.toJson<String>(quantityLabel),
      'ruleRevision': serializer.toJson<int>(ruleRevision),
      'status': serializer.toJson<String>(status),
      'version': serializer.toJson<int>(version),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
      'missedAt': serializer.toJson<DateTime?>(missedAt),
      'reminderSentAt': serializer.toJson<DateTime?>(reminderSentAt),
      'responseDueAt': serializer.toJson<DateTime?>(responseDueAt),
      'snoozeCount': serializer.toJson<int>(snoozeCount),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'timingClassification': serializer.toJson<String?>(timingClassification),
      'pendingMutationId': serializer.toJson<String?>(pendingMutationId),
      'syncErrorCode': serializer.toJson<String?>(syncErrorCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedDoseOccurrence copyWith({
    String? id,
    String? profileId,
    String? medicationName,
    DateTime? plannedAt,
    String? plannedLocalDateTime,
    String? quantityLabel,
    int? ruleRevision,
    String? status,
    int? version,
    Value<DateTime?> confirmedAt = const Value.absent(),
    Value<DateTime?> missedAt = const Value.absent(),
    Value<DateTime?> reminderSentAt = const Value.absent(),
    Value<DateTime?> responseDueAt = const Value.absent(),
    int? snoozeCount,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<String?> timingClassification = const Value.absent(),
    Value<String?> pendingMutationId = const Value.absent(),
    Value<String?> syncErrorCode = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedDoseOccurrence(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    medicationName: medicationName ?? this.medicationName,
    plannedAt: plannedAt ?? this.plannedAt,
    plannedLocalDateTime: plannedLocalDateTime ?? this.plannedLocalDateTime,
    quantityLabel: quantityLabel ?? this.quantityLabel,
    ruleRevision: ruleRevision ?? this.ruleRevision,
    status: status ?? this.status,
    version: version ?? this.version,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    missedAt: missedAt.present ? missedAt.value : this.missedAt,
    reminderSentAt: reminderSentAt.present
        ? reminderSentAt.value
        : this.reminderSentAt,
    responseDueAt: responseDueAt.present
        ? responseDueAt.value
        : this.responseDueAt,
    snoozeCount: snoozeCount ?? this.snoozeCount,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    timingClassification: timingClassification.present
        ? timingClassification.value
        : this.timingClassification,
    pendingMutationId: pendingMutationId.present
        ? pendingMutationId.value
        : this.pendingMutationId,
    syncErrorCode: syncErrorCode.present
        ? syncErrorCode.value
        : this.syncErrorCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedDoseOccurrence copyWithCompanion(CachedDoseOccurrencesCompanion data) {
    return CachedDoseOccurrence(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      plannedAt: data.plannedAt.present ? data.plannedAt.value : this.plannedAt,
      plannedLocalDateTime: data.plannedLocalDateTime.present
          ? data.plannedLocalDateTime.value
          : this.plannedLocalDateTime,
      quantityLabel: data.quantityLabel.present
          ? data.quantityLabel.value
          : this.quantityLabel,
      ruleRevision: data.ruleRevision.present
          ? data.ruleRevision.value
          : this.ruleRevision,
      status: data.status.present ? data.status.value : this.status,
      version: data.version.present ? data.version.value : this.version,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      missedAt: data.missedAt.present ? data.missedAt.value : this.missedAt,
      reminderSentAt: data.reminderSentAt.present
          ? data.reminderSentAt.value
          : this.reminderSentAt,
      responseDueAt: data.responseDueAt.present
          ? data.responseDueAt.value
          : this.responseDueAt,
      snoozeCount: data.snoozeCount.present
          ? data.snoozeCount.value
          : this.snoozeCount,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      timingClassification: data.timingClassification.present
          ? data.timingClassification.value
          : this.timingClassification,
      pendingMutationId: data.pendingMutationId.present
          ? data.pendingMutationId.value
          : this.pendingMutationId,
      syncErrorCode: data.syncErrorCode.present
          ? data.syncErrorCode.value
          : this.syncErrorCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDoseOccurrence(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('medicationName: $medicationName, ')
          ..write('plannedAt: $plannedAt, ')
          ..write('plannedLocalDateTime: $plannedLocalDateTime, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('ruleRevision: $ruleRevision, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('missedAt: $missedAt, ')
          ..write('reminderSentAt: $reminderSentAt, ')
          ..write('responseDueAt: $responseDueAt, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('timingClassification: $timingClassification, ')
          ..write('pendingMutationId: $pendingMutationId, ')
          ..write('syncErrorCode: $syncErrorCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    medicationName,
    plannedAt,
    plannedLocalDateTime,
    quantityLabel,
    ruleRevision,
    status,
    version,
    confirmedAt,
    missedAt,
    reminderSentAt,
    responseDueAt,
    snoozeCount,
    snoozedUntil,
    timingClassification,
    pendingMutationId,
    syncErrorCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDoseOccurrence &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.medicationName == this.medicationName &&
          other.plannedAt == this.plannedAt &&
          other.plannedLocalDateTime == this.plannedLocalDateTime &&
          other.quantityLabel == this.quantityLabel &&
          other.ruleRevision == this.ruleRevision &&
          other.status == this.status &&
          other.version == this.version &&
          other.confirmedAt == this.confirmedAt &&
          other.missedAt == this.missedAt &&
          other.reminderSentAt == this.reminderSentAt &&
          other.responseDueAt == this.responseDueAt &&
          other.snoozeCount == this.snoozeCount &&
          other.snoozedUntil == this.snoozedUntil &&
          other.timingClassification == this.timingClassification &&
          other.pendingMutationId == this.pendingMutationId &&
          other.syncErrorCode == this.syncErrorCode &&
          other.updatedAt == this.updatedAt);
}

class CachedDoseOccurrencesCompanion
    extends UpdateCompanion<CachedDoseOccurrence> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> medicationName;
  final Value<DateTime> plannedAt;
  final Value<String> plannedLocalDateTime;
  final Value<String> quantityLabel;
  final Value<int> ruleRevision;
  final Value<String> status;
  final Value<int> version;
  final Value<DateTime?> confirmedAt;
  final Value<DateTime?> missedAt;
  final Value<DateTime?> reminderSentAt;
  final Value<DateTime?> responseDueAt;
  final Value<int> snoozeCount;
  final Value<DateTime?> snoozedUntil;
  final Value<String?> timingClassification;
  final Value<String?> pendingMutationId;
  final Value<String?> syncErrorCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedDoseOccurrencesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.plannedAt = const Value.absent(),
    this.plannedLocalDateTime = const Value.absent(),
    this.quantityLabel = const Value.absent(),
    this.ruleRevision = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.missedAt = const Value.absent(),
    this.reminderSentAt = const Value.absent(),
    this.responseDueAt = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.timingClassification = const Value.absent(),
    this.pendingMutationId = const Value.absent(),
    this.syncErrorCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDoseOccurrencesCompanion.insert({
    required String id,
    required String profileId,
    required String medicationName,
    required DateTime plannedAt,
    required String plannedLocalDateTime,
    required String quantityLabel,
    this.ruleRevision = const Value.absent(),
    required String status,
    required int version,
    this.confirmedAt = const Value.absent(),
    this.missedAt = const Value.absent(),
    this.reminderSentAt = const Value.absent(),
    this.responseDueAt = const Value.absent(),
    this.snoozeCount = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.timingClassification = const Value.absent(),
    this.pendingMutationId = const Value.absent(),
    this.syncErrorCode = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       medicationName = Value(medicationName),
       plannedAt = Value(plannedAt),
       plannedLocalDateTime = Value(plannedLocalDateTime),
       quantityLabel = Value(quantityLabel),
       status = Value(status),
       version = Value(version),
       updatedAt = Value(updatedAt);
  static Insertable<CachedDoseOccurrence> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? medicationName,
    Expression<DateTime>? plannedAt,
    Expression<String>? plannedLocalDateTime,
    Expression<String>? quantityLabel,
    Expression<int>? ruleRevision,
    Expression<String>? status,
    Expression<int>? version,
    Expression<DateTime>? confirmedAt,
    Expression<DateTime>? missedAt,
    Expression<DateTime>? reminderSentAt,
    Expression<DateTime>? responseDueAt,
    Expression<int>? snoozeCount,
    Expression<DateTime>? snoozedUntil,
    Expression<String>? timingClassification,
    Expression<String>? pendingMutationId,
    Expression<String>? syncErrorCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (medicationName != null) 'medication_name': medicationName,
      if (plannedAt != null) 'planned_at': plannedAt,
      if (plannedLocalDateTime != null)
        'planned_local_date_time': plannedLocalDateTime,
      if (quantityLabel != null) 'quantity_label': quantityLabel,
      if (ruleRevision != null) 'rule_revision': ruleRevision,
      if (status != null) 'status': status,
      if (version != null) 'version': version,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (missedAt != null) 'missed_at': missedAt,
      if (reminderSentAt != null) 'reminder_sent_at': reminderSentAt,
      if (responseDueAt != null) 'response_due_at': responseDueAt,
      if (snoozeCount != null) 'snooze_count': snoozeCount,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (timingClassification != null)
        'timing_classification': timingClassification,
      if (pendingMutationId != null) 'pending_mutation_id': pendingMutationId,
      if (syncErrorCode != null) 'sync_error_code': syncErrorCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDoseOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? medicationName,
    Value<DateTime>? plannedAt,
    Value<String>? plannedLocalDateTime,
    Value<String>? quantityLabel,
    Value<int>? ruleRevision,
    Value<String>? status,
    Value<int>? version,
    Value<DateTime?>? confirmedAt,
    Value<DateTime?>? missedAt,
    Value<DateTime?>? reminderSentAt,
    Value<DateTime?>? responseDueAt,
    Value<int>? snoozeCount,
    Value<DateTime?>? snoozedUntil,
    Value<String?>? timingClassification,
    Value<String?>? pendingMutationId,
    Value<String?>? syncErrorCode,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedDoseOccurrencesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medicationName: medicationName ?? this.medicationName,
      plannedAt: plannedAt ?? this.plannedAt,
      plannedLocalDateTime: plannedLocalDateTime ?? this.plannedLocalDateTime,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      ruleRevision: ruleRevision ?? this.ruleRevision,
      status: status ?? this.status,
      version: version ?? this.version,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      missedAt: missedAt ?? this.missedAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      responseDueAt: responseDueAt ?? this.responseDueAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      timingClassification: timingClassification ?? this.timingClassification,
      pendingMutationId: pendingMutationId ?? this.pendingMutationId,
      syncErrorCode: syncErrorCode ?? this.syncErrorCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (plannedAt.present) {
      map['planned_at'] = Variable<DateTime>(plannedAt.value);
    }
    if (plannedLocalDateTime.present) {
      map['planned_local_date_time'] = Variable<String>(
        plannedLocalDateTime.value,
      );
    }
    if (quantityLabel.present) {
      map['quantity_label'] = Variable<String>(quantityLabel.value);
    }
    if (ruleRevision.present) {
      map['rule_revision'] = Variable<int>(ruleRevision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (missedAt.present) {
      map['missed_at'] = Variable<DateTime>(missedAt.value);
    }
    if (reminderSentAt.present) {
      map['reminder_sent_at'] = Variable<DateTime>(reminderSentAt.value);
    }
    if (responseDueAt.present) {
      map['response_due_at'] = Variable<DateTime>(responseDueAt.value);
    }
    if (snoozeCount.present) {
      map['snooze_count'] = Variable<int>(snoozeCount.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (timingClassification.present) {
      map['timing_classification'] = Variable<String>(
        timingClassification.value,
      );
    }
    if (pendingMutationId.present) {
      map['pending_mutation_id'] = Variable<String>(pendingMutationId.value);
    }
    if (syncErrorCode.present) {
      map['sync_error_code'] = Variable<String>(syncErrorCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDoseOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('medicationName: $medicationName, ')
          ..write('plannedAt: $plannedAt, ')
          ..write('plannedLocalDateTime: $plannedLocalDateTime, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('ruleRevision: $ruleRevision, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('missedAt: $missedAt, ')
          ..write('reminderSentAt: $reminderSentAt, ')
          ..write('responseDueAt: $responseDueAt, ')
          ..write('snoozeCount: $snoozeCount, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('timingClassification: $timingClassification, ')
          ..write('pendingMutationId: $pendingMutationId, ')
          ..write('syncErrorCode: $syncErrorCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMutationsTable extends SyncMutations
    with TableInfo<$SyncMutationsTable, SyncMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  @override
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedVersionMeta = const VerificationMeta(
    'expectedVersion',
  );
  @override
  late final GeneratedColumn<int> expectedVersion = GeneratedColumn<int>(
    'expected_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientAtMeta = const VerificationMeta(
    'clientAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientAt = GeneratedColumn<DateTime>(
    'client_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previousOccurrenceJsonMeta =
      const VerificationMeta('previousOccurrenceJson');
  @override
  late final GeneratedColumn<String> previousOccurrenceJson =
      GeneratedColumn<String>(
        'previous_occurrence_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    installationId,
    occurrenceId,
    action,
    expectedVersion,
    clientAt,
    snoozeMinutes,
    reason,
    previousOccurrenceJson,
    status,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installationIdMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('expected_version')) {
      context.handle(
        _expectedVersionMeta,
        expectedVersion.isAcceptableOrUnknown(
          data['expected_version']!,
          _expectedVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedVersionMeta);
    }
    if (data.containsKey('client_at')) {
      context.handle(
        _clientAtMeta,
        clientAt.isAcceptableOrUnknown(data['client_at']!, _clientAtMeta),
      );
    } else if (isInserting) {
      context.missing(_clientAtMeta);
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('previous_occurrence_json')) {
      context.handle(
        _previousOccurrenceJsonMeta,
        previousOccurrenceJson.isAcceptableOrUnknown(
          data['previous_occurrence_json']!,
          _previousOccurrenceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousOccurrenceJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMutation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      expectedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_version'],
      )!,
      clientAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_at'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      previousOccurrenceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_occurrence_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncMutationsTable createAlias(String alias) {
    return $SyncMutationsTable(attachedDatabase, alias);
  }
}

class SyncMutation extends DataClass implements Insertable<SyncMutation> {
  final String id;
  final String installationId;
  final String occurrenceId;
  final String action;
  final int expectedVersion;
  final DateTime clientAt;
  final int? snoozeMinutes;
  final String? reason;
  final String previousOccurrenceJson;
  final String status;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncMutation({
    required this.id,
    required this.installationId,
    required this.occurrenceId,
    required this.action,
    required this.expectedVersion,
    required this.clientAt,
    this.snoozeMinutes,
    this.reason,
    required this.previousOccurrenceJson,
    required this.status,
    required this.attemptCount,
    this.nextAttemptAt,
    this.lastErrorCode,
    this.lastErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['installation_id'] = Variable<String>(installationId);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['action'] = Variable<String>(action);
    map['expected_version'] = Variable<int>(expectedVersion);
    map['client_at'] = Variable<DateTime>(clientAt);
    if (!nullToAbsent || snoozeMinutes != null) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['previous_occurrence_json'] = Variable<String>(previousOccurrenceJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncMutationsCompanion toCompanion(bool nullToAbsent) {
    return SyncMutationsCompanion(
      id: Value(id),
      installationId: Value(installationId),
      occurrenceId: Value(occurrenceId),
      action: Value(action),
      expectedVersion: Value(expectedVersion),
      clientAt: Value(clientAt),
      snoozeMinutes: snoozeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeMinutes),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      previousOccurrenceJson: Value(previousOccurrenceJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMutation(
      id: serializer.fromJson<String>(json['id']),
      installationId: serializer.fromJson<String>(json['installationId']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      action: serializer.fromJson<String>(json['action']),
      expectedVersion: serializer.fromJson<int>(json['expectedVersion']),
      clientAt: serializer.fromJson<DateTime>(json['clientAt']),
      snoozeMinutes: serializer.fromJson<int?>(json['snoozeMinutes']),
      reason: serializer.fromJson<String?>(json['reason']),
      previousOccurrenceJson: serializer.fromJson<String>(
        json['previousOccurrenceJson'],
      ),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'installationId': serializer.toJson<String>(installationId),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'action': serializer.toJson<String>(action),
      'expectedVersion': serializer.toJson<int>(expectedVersion),
      'clientAt': serializer.toJson<DateTime>(clientAt),
      'snoozeMinutes': serializer.toJson<int?>(snoozeMinutes),
      'reason': serializer.toJson<String?>(reason),
      'previousOccurrenceJson': serializer.toJson<String>(
        previousOccurrenceJson,
      ),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncMutation copyWith({
    String? id,
    String? installationId,
    String? occurrenceId,
    String? action,
    int? expectedVersion,
    DateTime? clientAt,
    Value<int?> snoozeMinutes = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    String? previousOccurrenceJson,
    String? status,
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncMutation(
    id: id ?? this.id,
    installationId: installationId ?? this.installationId,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    action: action ?? this.action,
    expectedVersion: expectedVersion ?? this.expectedVersion,
    clientAt: clientAt ?? this.clientAt,
    snoozeMinutes: snoozeMinutes.present
        ? snoozeMinutes.value
        : this.snoozeMinutes,
    reason: reason.present ? reason.value : this.reason,
    previousOccurrenceJson:
        previousOccurrenceJson ?? this.previousOccurrenceJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncMutation copyWithCompanion(SyncMutationsCompanion data) {
    return SyncMutation(
      id: data.id.present ? data.id.value : this.id,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      action: data.action.present ? data.action.value : this.action,
      expectedVersion: data.expectedVersion.present
          ? data.expectedVersion.value
          : this.expectedVersion,
      clientAt: data.clientAt.present ? data.clientAt.value : this.clientAt,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      reason: data.reason.present ? data.reason.value : this.reason,
      previousOccurrenceJson: data.previousOccurrenceJson.present
          ? data.previousOccurrenceJson.value
          : this.previousOccurrenceJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMutation(')
          ..write('id: $id, ')
          ..write('installationId: $installationId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('action: $action, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('clientAt: $clientAt, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('reason: $reason, ')
          ..write('previousOccurrenceJson: $previousOccurrenceJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    installationId,
    occurrenceId,
    action,
    expectedVersion,
    clientAt,
    snoozeMinutes,
    reason,
    previousOccurrenceJson,
    status,
    attemptCount,
    nextAttemptAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMutation &&
          other.id == this.id &&
          other.installationId == this.installationId &&
          other.occurrenceId == this.occurrenceId &&
          other.action == this.action &&
          other.expectedVersion == this.expectedVersion &&
          other.clientAt == this.clientAt &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.reason == this.reason &&
          other.previousOccurrenceJson == this.previousOccurrenceJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncMutationsCompanion extends UpdateCompanion<SyncMutation> {
  final Value<String> id;
  final Value<String> installationId;
  final Value<String> occurrenceId;
  final Value<String> action;
  final Value<int> expectedVersion;
  final Value<DateTime> clientAt;
  final Value<int?> snoozeMinutes;
  final Value<String?> reason;
  final Value<String> previousOccurrenceJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncMutationsCompanion({
    this.id = const Value.absent(),
    this.installationId = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.action = const Value.absent(),
    this.expectedVersion = const Value.absent(),
    this.clientAt = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.reason = const Value.absent(),
    this.previousOccurrenceJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMutationsCompanion.insert({
    required String id,
    required String installationId,
    required String occurrenceId,
    required String action,
    required int expectedVersion,
    required DateTime clientAt,
    this.snoozeMinutes = const Value.absent(),
    this.reason = const Value.absent(),
    required String previousOccurrenceJson,
    required String status,
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       installationId = Value(installationId),
       occurrenceId = Value(occurrenceId),
       action = Value(action),
       expectedVersion = Value(expectedVersion),
       clientAt = Value(clientAt),
       previousOccurrenceJson = Value(previousOccurrenceJson),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMutation> custom({
    Expression<String>? id,
    Expression<String>? installationId,
    Expression<String>? occurrenceId,
    Expression<String>? action,
    Expression<int>? expectedVersion,
    Expression<DateTime>? clientAt,
    Expression<int>? snoozeMinutes,
    Expression<String>? reason,
    Expression<String>? previousOccurrenceJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (installationId != null) 'installation_id': installationId,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (action != null) 'action': action,
      if (expectedVersion != null) 'expected_version': expectedVersion,
      if (clientAt != null) 'client_at': clientAt,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (reason != null) 'reason': reason,
      if (previousOccurrenceJson != null)
        'previous_occurrence_json': previousOccurrenceJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMutationsCompanion copyWith({
    Value<String>? id,
    Value<String>? installationId,
    Value<String>? occurrenceId,
    Value<String>? action,
    Value<int>? expectedVersion,
    Value<DateTime>? clientAt,
    Value<int?>? snoozeMinutes,
    Value<String?>? reason,
    Value<String>? previousOccurrenceJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMutationsCompanion(
      id: id ?? this.id,
      installationId: installationId ?? this.installationId,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      action: action ?? this.action,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      clientAt: clientAt ?? this.clientAt,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      reason: reason ?? this.reason,
      previousOccurrenceJson:
          previousOccurrenceJson ?? this.previousOccurrenceJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (expectedVersion.present) {
      map['expected_version'] = Variable<int>(expectedVersion.value);
    }
    if (clientAt.present) {
      map['client_at'] = Variable<DateTime>(clientAt.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (previousOccurrenceJson.present) {
      map['previous_occurrence_json'] = Variable<String>(
        previousOccurrenceJson.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMutationsCompanion(')
          ..write('id: $id, ')
          ..write('installationId: $installationId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('action: $action, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('clientAt: $clientAt, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('reason: $reason, ')
          ..write('previousOccurrenceJson: $previousOccurrenceJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CareMateLocalDatabase extends GeneratedDatabase {
  _$CareMateLocalDatabase(QueryExecutor e) : super(e);
  $CareMateLocalDatabaseManager get managers =>
      $CareMateLocalDatabaseManager(this);
  late final $LocalAccountBindingsTable localAccountBindings =
      $LocalAccountBindingsTable(this);
  late final $CachedPatientProfilesTable cachedPatientProfiles =
      $CachedPatientProfilesTable(this);
  late final $CachedMedicationsTable cachedMedications =
      $CachedMedicationsTable(this);
  late final $CachedDoseOccurrencesTable cachedDoseOccurrences =
      $CachedDoseOccurrencesTable(this);
  late final $SyncMutationsTable syncMutations = $SyncMutationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localAccountBindings,
    cachedPatientProfiles,
    cachedMedications,
    cachedDoseOccurrences,
    syncMutations,
  ];
}

typedef $$LocalAccountBindingsTableCreateCompanionBuilder =
    LocalAccountBindingsCompanion Function({
      Value<int> slot,
      required String userId,
      required DateTime updatedAt,
    });
typedef $$LocalAccountBindingsTableUpdateCompanionBuilder =
    LocalAccountBindingsCompanion Function({
      Value<int> slot,
      Value<String> userId,
      Value<DateTime> updatedAt,
    });

class $$LocalAccountBindingsTableFilterComposer
    extends Composer<_$CareMateLocalDatabase, $LocalAccountBindingsTable> {
  $$LocalAccountBindingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAccountBindingsTableOrderingComposer
    extends Composer<_$CareMateLocalDatabase, $LocalAccountBindingsTable> {
  $$LocalAccountBindingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAccountBindingsTableAnnotationComposer
    extends Composer<_$CareMateLocalDatabase, $LocalAccountBindingsTable> {
  $$LocalAccountBindingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAccountBindingsTableTableManager
    extends
        RootTableManager<
          _$CareMateLocalDatabase,
          $LocalAccountBindingsTable,
          LocalAccountBinding,
          $$LocalAccountBindingsTableFilterComposer,
          $$LocalAccountBindingsTableOrderingComposer,
          $$LocalAccountBindingsTableAnnotationComposer,
          $$LocalAccountBindingsTableCreateCompanionBuilder,
          $$LocalAccountBindingsTableUpdateCompanionBuilder,
          (
            LocalAccountBinding,
            BaseReferences<
              _$CareMateLocalDatabase,
              $LocalAccountBindingsTable,
              LocalAccountBinding
            >,
          ),
          LocalAccountBinding,
          PrefetchHooks Function()
        > {
  $$LocalAccountBindingsTableTableManager(
    _$CareMateLocalDatabase db,
    $LocalAccountBindingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAccountBindingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAccountBindingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAccountBindingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> slot = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalAccountBindingsCompanion(
                slot: slot,
                userId: userId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> slot = const Value.absent(),
                required String userId,
                required DateTime updatedAt,
              }) => LocalAccountBindingsCompanion.insert(
                slot: slot,
                userId: userId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAccountBindingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareMateLocalDatabase,
      $LocalAccountBindingsTable,
      LocalAccountBinding,
      $$LocalAccountBindingsTableFilterComposer,
      $$LocalAccountBindingsTableOrderingComposer,
      $$LocalAccountBindingsTableAnnotationComposer,
      $$LocalAccountBindingsTableCreateCompanionBuilder,
      $$LocalAccountBindingsTableUpdateCompanionBuilder,
      (
        LocalAccountBinding,
        BaseReferences<
          _$CareMateLocalDatabase,
          $LocalAccountBindingsTable,
          LocalAccountBinding
        >,
      ),
      LocalAccountBinding,
      PrefetchHooks Function()
    >;
typedef $$CachedPatientProfilesTableCreateCompanionBuilder =
    CachedPatientProfilesCompanion Function({
      required String id,
      required String displayName,
      required String timezone,
      required int version,
      required String accessRole,
      required bool canManage,
      Value<bool> canReceiveMissedDoseAlerts,
      Value<bool> canViewMedicationPlan,
      Value<int> missedDoseGraceMinutes,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedPatientProfilesTableUpdateCompanionBuilder =
    CachedPatientProfilesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> timezone,
      Value<int> version,
      Value<String> accessRole,
      Value<bool> canManage,
      Value<bool> canReceiveMissedDoseAlerts,
      Value<bool> canViewMedicationPlan,
      Value<int> missedDoseGraceMinutes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedPatientProfilesTableFilterComposer
    extends Composer<_$CareMateLocalDatabase, $CachedPatientProfilesTable> {
  $$CachedPatientProfilesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canManage => $composableBuilder(
    column: $table.canManage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canReceiveMissedDoseAlerts => $composableBuilder(
    column: $table.canReceiveMissedDoseAlerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canViewMedicationPlan => $composableBuilder(
    column: $table.canViewMedicationPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missedDoseGraceMinutes => $composableBuilder(
    column: $table.missedDoseGraceMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPatientProfilesTableOrderingComposer
    extends Composer<_$CareMateLocalDatabase, $CachedPatientProfilesTable> {
  $$CachedPatientProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canManage => $composableBuilder(
    column: $table.canManage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canReceiveMissedDoseAlerts => $composableBuilder(
    column: $table.canReceiveMissedDoseAlerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canViewMedicationPlan => $composableBuilder(
    column: $table.canViewMedicationPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missedDoseGraceMinutes => $composableBuilder(
    column: $table.missedDoseGraceMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPatientProfilesTableAnnotationComposer
    extends Composer<_$CareMateLocalDatabase, $CachedPatientProfilesTable> {
  $$CachedPatientProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canManage =>
      $composableBuilder(column: $table.canManage, builder: (column) => column);

  GeneratedColumn<bool> get canReceiveMissedDoseAlerts => $composableBuilder(
    column: $table.canReceiveMissedDoseAlerts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canViewMedicationPlan => $composableBuilder(
    column: $table.canViewMedicationPlan,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missedDoseGraceMinutes => $composableBuilder(
    column: $table.missedDoseGraceMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedPatientProfilesTableTableManager
    extends
        RootTableManager<
          _$CareMateLocalDatabase,
          $CachedPatientProfilesTable,
          CachedPatientProfile,
          $$CachedPatientProfilesTableFilterComposer,
          $$CachedPatientProfilesTableOrderingComposer,
          $$CachedPatientProfilesTableAnnotationComposer,
          $$CachedPatientProfilesTableCreateCompanionBuilder,
          $$CachedPatientProfilesTableUpdateCompanionBuilder,
          (
            CachedPatientProfile,
            BaseReferences<
              _$CareMateLocalDatabase,
              $CachedPatientProfilesTable,
              CachedPatientProfile
            >,
          ),
          CachedPatientProfile,
          PrefetchHooks Function()
        > {
  $$CachedPatientProfilesTableTableManager(
    _$CareMateLocalDatabase db,
    $CachedPatientProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPatientProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedPatientProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPatientProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> accessRole = const Value.absent(),
                Value<bool> canManage = const Value.absent(),
                Value<bool> canReceiveMissedDoseAlerts = const Value.absent(),
                Value<bool> canViewMedicationPlan = const Value.absent(),
                Value<int> missedDoseGraceMinutes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPatientProfilesCompanion(
                id: id,
                displayName: displayName,
                timezone: timezone,
                version: version,
                accessRole: accessRole,
                canManage: canManage,
                canReceiveMissedDoseAlerts: canReceiveMissedDoseAlerts,
                canViewMedicationPlan: canViewMedicationPlan,
                missedDoseGraceMinutes: missedDoseGraceMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String timezone,
                required int version,
                required String accessRole,
                required bool canManage,
                Value<bool> canReceiveMissedDoseAlerts = const Value.absent(),
                Value<bool> canViewMedicationPlan = const Value.absent(),
                Value<int> missedDoseGraceMinutes = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPatientProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                timezone: timezone,
                version: version,
                accessRole: accessRole,
                canManage: canManage,
                canReceiveMissedDoseAlerts: canReceiveMissedDoseAlerts,
                canViewMedicationPlan: canViewMedicationPlan,
                missedDoseGraceMinutes: missedDoseGraceMinutes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPatientProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareMateLocalDatabase,
      $CachedPatientProfilesTable,
      CachedPatientProfile,
      $$CachedPatientProfilesTableFilterComposer,
      $$CachedPatientProfilesTableOrderingComposer,
      $$CachedPatientProfilesTableAnnotationComposer,
      $$CachedPatientProfilesTableCreateCompanionBuilder,
      $$CachedPatientProfilesTableUpdateCompanionBuilder,
      (
        CachedPatientProfile,
        BaseReferences<
          _$CareMateLocalDatabase,
          $CachedPatientProfilesTable,
          CachedPatientProfile
        >,
      ),
      CachedPatientProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedMedicationsTableCreateCompanionBuilder =
    CachedMedicationsCompanion Function({
      required String id,
      required String profileId,
      required String displayName,
      required String form,
      Value<String> mealRelation,
      required String quantityLabel,
      required String status,
      Value<String?> strengthLabel,
      Value<String?> activeScheduleJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMedicationsTableUpdateCompanionBuilder =
    CachedMedicationsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> displayName,
      Value<String> form,
      Value<String> mealRelation,
      Value<String> quantityLabel,
      Value<String> status,
      Value<String?> strengthLabel,
      Value<String?> activeScheduleJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMedicationsTableFilterComposer
    extends Composer<_$CareMateLocalDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableFilterComposer({
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

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strengthLabel => $composableBuilder(
    column: $table.strengthLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeScheduleJson => $composableBuilder(
    column: $table.activeScheduleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMedicationsTableOrderingComposer
    extends Composer<_$CareMateLocalDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableOrderingComposer({
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

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strengthLabel => $composableBuilder(
    column: $table.strengthLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeScheduleJson => $composableBuilder(
    column: $table.activeScheduleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMedicationsTableAnnotationComposer
    extends Composer<_$CareMateLocalDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get strengthLabel => $composableBuilder(
    column: $table.strengthLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeScheduleJson => $composableBuilder(
    column: $table.activeScheduleJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMedicationsTableTableManager
    extends
        RootTableManager<
          _$CareMateLocalDatabase,
          $CachedMedicationsTable,
          CachedMedication,
          $$CachedMedicationsTableFilterComposer,
          $$CachedMedicationsTableOrderingComposer,
          $$CachedMedicationsTableAnnotationComposer,
          $$CachedMedicationsTableCreateCompanionBuilder,
          $$CachedMedicationsTableUpdateCompanionBuilder,
          (
            CachedMedication,
            BaseReferences<
              _$CareMateLocalDatabase,
              $CachedMedicationsTable,
              CachedMedication
            >,
          ),
          CachedMedication,
          PrefetchHooks Function()
        > {
  $$CachedMedicationsTableTableManager(
    _$CareMateLocalDatabase db,
    $CachedMedicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMedicationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> form = const Value.absent(),
                Value<String> mealRelation = const Value.absent(),
                Value<String> quantityLabel = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> strengthLabel = const Value.absent(),
                Value<String?> activeScheduleJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion(
                id: id,
                profileId: profileId,
                displayName: displayName,
                form: form,
                mealRelation: mealRelation,
                quantityLabel: quantityLabel,
                status: status,
                strengthLabel: strengthLabel,
                activeScheduleJson: activeScheduleJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String displayName,
                required String form,
                Value<String> mealRelation = const Value.absent(),
                required String quantityLabel,
                required String status,
                Value<String?> strengthLabel = const Value.absent(),
                Value<String?> activeScheduleJson = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion.insert(
                id: id,
                profileId: profileId,
                displayName: displayName,
                form: form,
                mealRelation: mealRelation,
                quantityLabel: quantityLabel,
                status: status,
                strengthLabel: strengthLabel,
                activeScheduleJson: activeScheduleJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareMateLocalDatabase,
      $CachedMedicationsTable,
      CachedMedication,
      $$CachedMedicationsTableFilterComposer,
      $$CachedMedicationsTableOrderingComposer,
      $$CachedMedicationsTableAnnotationComposer,
      $$CachedMedicationsTableCreateCompanionBuilder,
      $$CachedMedicationsTableUpdateCompanionBuilder,
      (
        CachedMedication,
        BaseReferences<
          _$CareMateLocalDatabase,
          $CachedMedicationsTable,
          CachedMedication
        >,
      ),
      CachedMedication,
      PrefetchHooks Function()
    >;
typedef $$CachedDoseOccurrencesTableCreateCompanionBuilder =
    CachedDoseOccurrencesCompanion Function({
      required String id,
      required String profileId,
      required String medicationName,
      required DateTime plannedAt,
      required String plannedLocalDateTime,
      required String quantityLabel,
      Value<int> ruleRevision,
      required String status,
      required int version,
      Value<DateTime?> confirmedAt,
      Value<DateTime?> missedAt,
      Value<DateTime?> reminderSentAt,
      Value<DateTime?> responseDueAt,
      Value<int> snoozeCount,
      Value<DateTime?> snoozedUntil,
      Value<String?> timingClassification,
      Value<String?> pendingMutationId,
      Value<String?> syncErrorCode,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedDoseOccurrencesTableUpdateCompanionBuilder =
    CachedDoseOccurrencesCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> medicationName,
      Value<DateTime> plannedAt,
      Value<String> plannedLocalDateTime,
      Value<String> quantityLabel,
      Value<int> ruleRevision,
      Value<String> status,
      Value<int> version,
      Value<DateTime?> confirmedAt,
      Value<DateTime?> missedAt,
      Value<DateTime?> reminderSentAt,
      Value<DateTime?> responseDueAt,
      Value<int> snoozeCount,
      Value<DateTime?> snoozedUntil,
      Value<String?> timingClassification,
      Value<String?> pendingMutationId,
      Value<String?> syncErrorCode,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedDoseOccurrencesTableFilterComposer
    extends Composer<_$CareMateLocalDatabase, $CachedDoseOccurrencesTable> {
  $$CachedDoseOccurrencesTableFilterComposer({
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

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedAt => $composableBuilder(
    column: $table.plannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedLocalDateTime => $composableBuilder(
    column: $table.plannedLocalDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleRevision => $composableBuilder(
    column: $table.ruleRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get missedAt => $composableBuilder(
    column: $table.missedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderSentAt => $composableBuilder(
    column: $table.reminderSentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get responseDueAt => $composableBuilder(
    column: $table.responseDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timingClassification => $composableBuilder(
    column: $table.timingClassification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingMutationId => $composableBuilder(
    column: $table.pendingMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDoseOccurrencesTableOrderingComposer
    extends Composer<_$CareMateLocalDatabase, $CachedDoseOccurrencesTable> {
  $$CachedDoseOccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedAt => $composableBuilder(
    column: $table.plannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedLocalDateTime => $composableBuilder(
    column: $table.plannedLocalDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleRevision => $composableBuilder(
    column: $table.ruleRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get missedAt => $composableBuilder(
    column: $table.missedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderSentAt => $composableBuilder(
    column: $table.reminderSentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get responseDueAt => $composableBuilder(
    column: $table.responseDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timingClassification => $composableBuilder(
    column: $table.timingClassification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingMutationId => $composableBuilder(
    column: $table.pendingMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDoseOccurrencesTableAnnotationComposer
    extends Composer<_$CareMateLocalDatabase, $CachedDoseOccurrencesTable> {
  $$CachedDoseOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get plannedAt =>
      $composableBuilder(column: $table.plannedAt, builder: (column) => column);

  GeneratedColumn<String> get plannedLocalDateTime => $composableBuilder(
    column: $table.plannedLocalDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ruleRevision => $composableBuilder(
    column: $table.ruleRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get missedAt =>
      $composableBuilder(column: $table.missedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderSentAt => $composableBuilder(
    column: $table.reminderSentAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get responseDueAt => $composableBuilder(
    column: $table.responseDueAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeCount => $composableBuilder(
    column: $table.snoozeCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timingClassification => $composableBuilder(
    column: $table.timingClassification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingMutationId => $composableBuilder(
    column: $table.pendingMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncErrorCode => $composableBuilder(
    column: $table.syncErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedDoseOccurrencesTableTableManager
    extends
        RootTableManager<
          _$CareMateLocalDatabase,
          $CachedDoseOccurrencesTable,
          CachedDoseOccurrence,
          $$CachedDoseOccurrencesTableFilterComposer,
          $$CachedDoseOccurrencesTableOrderingComposer,
          $$CachedDoseOccurrencesTableAnnotationComposer,
          $$CachedDoseOccurrencesTableCreateCompanionBuilder,
          $$CachedDoseOccurrencesTableUpdateCompanionBuilder,
          (
            CachedDoseOccurrence,
            BaseReferences<
              _$CareMateLocalDatabase,
              $CachedDoseOccurrencesTable,
              CachedDoseOccurrence
            >,
          ),
          CachedDoseOccurrence,
          PrefetchHooks Function()
        > {
  $$CachedDoseOccurrencesTableTableManager(
    _$CareMateLocalDatabase db,
    $CachedDoseOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDoseOccurrencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedDoseOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedDoseOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> medicationName = const Value.absent(),
                Value<DateTime> plannedAt = const Value.absent(),
                Value<String> plannedLocalDateTime = const Value.absent(),
                Value<String> quantityLabel = const Value.absent(),
                Value<int> ruleRevision = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<DateTime?> missedAt = const Value.absent(),
                Value<DateTime?> reminderSentAt = const Value.absent(),
                Value<DateTime?> responseDueAt = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> timingClassification = const Value.absent(),
                Value<String?> pendingMutationId = const Value.absent(),
                Value<String?> syncErrorCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDoseOccurrencesCompanion(
                id: id,
                profileId: profileId,
                medicationName: medicationName,
                plannedAt: plannedAt,
                plannedLocalDateTime: plannedLocalDateTime,
                quantityLabel: quantityLabel,
                ruleRevision: ruleRevision,
                status: status,
                version: version,
                confirmedAt: confirmedAt,
                missedAt: missedAt,
                reminderSentAt: reminderSentAt,
                responseDueAt: responseDueAt,
                snoozeCount: snoozeCount,
                snoozedUntil: snoozedUntil,
                timingClassification: timingClassification,
                pendingMutationId: pendingMutationId,
                syncErrorCode: syncErrorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String medicationName,
                required DateTime plannedAt,
                required String plannedLocalDateTime,
                required String quantityLabel,
                Value<int> ruleRevision = const Value.absent(),
                required String status,
                required int version,
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<DateTime?> missedAt = const Value.absent(),
                Value<DateTime?> reminderSentAt = const Value.absent(),
                Value<DateTime?> responseDueAt = const Value.absent(),
                Value<int> snoozeCount = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> timingClassification = const Value.absent(),
                Value<String?> pendingMutationId = const Value.absent(),
                Value<String?> syncErrorCode = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDoseOccurrencesCompanion.insert(
                id: id,
                profileId: profileId,
                medicationName: medicationName,
                plannedAt: plannedAt,
                plannedLocalDateTime: plannedLocalDateTime,
                quantityLabel: quantityLabel,
                ruleRevision: ruleRevision,
                status: status,
                version: version,
                confirmedAt: confirmedAt,
                missedAt: missedAt,
                reminderSentAt: reminderSentAt,
                responseDueAt: responseDueAt,
                snoozeCount: snoozeCount,
                snoozedUntil: snoozedUntil,
                timingClassification: timingClassification,
                pendingMutationId: pendingMutationId,
                syncErrorCode: syncErrorCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDoseOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$CareMateLocalDatabase,
      $CachedDoseOccurrencesTable,
      CachedDoseOccurrence,
      $$CachedDoseOccurrencesTableFilterComposer,
      $$CachedDoseOccurrencesTableOrderingComposer,
      $$CachedDoseOccurrencesTableAnnotationComposer,
      $$CachedDoseOccurrencesTableCreateCompanionBuilder,
      $$CachedDoseOccurrencesTableUpdateCompanionBuilder,
      (
        CachedDoseOccurrence,
        BaseReferences<
          _$CareMateLocalDatabase,
          $CachedDoseOccurrencesTable,
          CachedDoseOccurrence
        >,
      ),
      CachedDoseOccurrence,
      PrefetchHooks Function()
    >;
typedef $$SyncMutationsTableCreateCompanionBuilder =
    SyncMutationsCompanion Function({
      required String id,
      required String installationId,
      required String occurrenceId,
      required String action,
      required int expectedVersion,
      required DateTime clientAt,
      Value<int?> snoozeMinutes,
      Value<String?> reason,
      required String previousOccurrenceJson,
      required String status,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMutationsTableUpdateCompanionBuilder =
    SyncMutationsCompanion Function({
      Value<String> id,
      Value<String> installationId,
      Value<String> occurrenceId,
      Value<String> action,
      Value<int> expectedVersion,
      Value<DateTime> clientAt,
      Value<int?> snoozeMinutes,
      Value<String?> reason,
      Value<String> previousOccurrenceJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncMutationsTableFilterComposer
    extends Composer<_$CareMateLocalDatabase, $SyncMutationsTable> {
  $$SyncMutationsTableFilterComposer({
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

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientAt => $composableBuilder(
    column: $table.clientAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousOccurrenceJson => $composableBuilder(
    column: $table.previousOccurrenceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMutationsTableOrderingComposer
    extends Composer<_$CareMateLocalDatabase, $SyncMutationsTable> {
  $$SyncMutationsTableOrderingComposer({
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

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientAt => $composableBuilder(
    column: $table.clientAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousOccurrenceJson => $composableBuilder(
    column: $table.previousOccurrenceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMutationsTableAnnotationComposer
    extends Composer<_$CareMateLocalDatabase, $SyncMutationsTable> {
  $$SyncMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurrenceId => $composableBuilder(
    column: $table.occurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientAt =>
      $composableBuilder(column: $table.clientAt, builder: (column) => column);

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get previousOccurrenceJson => $composableBuilder(
    column: $table.previousOccurrenceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMutationsTableTableManager
    extends
        RootTableManager<
          _$CareMateLocalDatabase,
          $SyncMutationsTable,
          SyncMutation,
          $$SyncMutationsTableFilterComposer,
          $$SyncMutationsTableOrderingComposer,
          $$SyncMutationsTableAnnotationComposer,
          $$SyncMutationsTableCreateCompanionBuilder,
          $$SyncMutationsTableUpdateCompanionBuilder,
          (
            SyncMutation,
            BaseReferences<
              _$CareMateLocalDatabase,
              $SyncMutationsTable,
              SyncMutation
            >,
          ),
          SyncMutation,
          PrefetchHooks Function()
        > {
  $$SyncMutationsTableTableManager(
    _$CareMateLocalDatabase db,
    $SyncMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> installationId = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<int> expectedVersion = const Value.absent(),
                Value<DateTime> clientAt = const Value.absent(),
                Value<int?> snoozeMinutes = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> previousOccurrenceJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMutationsCompanion(
                id: id,
                installationId: installationId,
                occurrenceId: occurrenceId,
                action: action,
                expectedVersion: expectedVersion,
                clientAt: clientAt,
                snoozeMinutes: snoozeMinutes,
                reason: reason,
                previousOccurrenceJson: previousOccurrenceJson,
                status: status,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String installationId,
                required String occurrenceId,
                required String action,
                required int expectedVersion,
                required DateTime clientAt,
                Value<int?> snoozeMinutes = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                required String previousOccurrenceJson,
                required String status,
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMutationsCompanion.insert(
                id: id,
                installationId: installationId,
                occurrenceId: occurrenceId,
                action: action,
                expectedVersion: expectedVersion,
                clientAt: clientAt,
                snoozeMinutes: snoozeMinutes,
                reason: reason,
                previousOccurrenceJson: previousOccurrenceJson,
                status: status,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$CareMateLocalDatabase,
      $SyncMutationsTable,
      SyncMutation,
      $$SyncMutationsTableFilterComposer,
      $$SyncMutationsTableOrderingComposer,
      $$SyncMutationsTableAnnotationComposer,
      $$SyncMutationsTableCreateCompanionBuilder,
      $$SyncMutationsTableUpdateCompanionBuilder,
      (
        SyncMutation,
        BaseReferences<
          _$CareMateLocalDatabase,
          $SyncMutationsTable,
          SyncMutation
        >,
      ),
      SyncMutation,
      PrefetchHooks Function()
    >;

class $CareMateLocalDatabaseManager {
  final _$CareMateLocalDatabase _db;
  $CareMateLocalDatabaseManager(this._db);
  $$LocalAccountBindingsTableTableManager get localAccountBindings =>
      $$LocalAccountBindingsTableTableManager(_db, _db.localAccountBindings);
  $$CachedPatientProfilesTableTableManager get cachedPatientProfiles =>
      $$CachedPatientProfilesTableTableManager(_db, _db.cachedPatientProfiles);
  $$CachedMedicationsTableTableManager get cachedMedications =>
      $$CachedMedicationsTableTableManager(_db, _db.cachedMedications);
  $$CachedDoseOccurrencesTableTableManager get cachedDoseOccurrences =>
      $$CachedDoseOccurrencesTableTableManager(_db, _db.cachedDoseOccurrences);
  $$SyncMutationsTableTableManager get syncMutations =>
      $$SyncMutationsTableTableManager(_db, _db.syncMutations);
}
