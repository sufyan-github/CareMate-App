import 'package:drift/drift.dart';

part 'caremate_local_database.g.dart';

class LocalAccountBindings extends Table {
  IntColumn get slot => integer().withDefault(const Constant(1))();
  TextColumn get userId => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {slot};
}

class CachedPatientProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get timezone => text()();
  IntColumn get version => integer()();
  TextColumn get accessRole => text()();
  BoolColumn get canManage => boolean()();
  BoolColumn get canReceiveMissedDoseAlerts =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get canViewMedicationPlan =>
      boolean().withDefault(const Constant(true))();
  IntColumn get missedDoseGraceMinutes =>
      integer().withDefault(const Constant(45))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedMedications extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get displayName => text()();
  TextColumn get form => text()();
  TextColumn get mealRelation =>
      text().withDefault(const Constant('UNSPECIFIED'))();
  TextColumn get quantityLabel => text()();
  TextColumn get status => text()();
  TextColumn get strengthLabel => text().nullable()();
  TextColumn get activeScheduleJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedDoseOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get medicationName => text()();
  DateTimeColumn get plannedAt => dateTime()();
  TextColumn get plannedLocalDateTime => text()();
  TextColumn get quantityLabel => text()();
  IntColumn get ruleRevision => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  IntColumn get version => integer()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  DateTimeColumn get missedAt => dateTime().nullable()();
  DateTimeColumn get reminderSentAt => dateTime().nullable()();
  DateTimeColumn get responseDueAt => dateTime().nullable()();
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  TextColumn get timingClassification => text().nullable()();
  TextColumn get pendingMutationId => text().nullable()();
  TextColumn get syncErrorCode => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncMutations extends Table {
  TextColumn get id => text()();
  TextColumn get installationId => text()();
  TextColumn get occurrenceId => text()();
  TextColumn get action => text()();
  IntColumn get expectedVersion => integer()();
  DateTimeColumn get clientAt => dateTime()();
  IntColumn get snoozeMinutes => integer().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get previousOccurrenceJson => text()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalAccountBindings,
    CachedPatientProfiles,
    CachedMedications,
    CachedDoseOccurrences,
    SyncMutations,
  ],
)
class CareMateLocalDatabase extends _$CareMateLocalDatabase {
  CareMateLocalDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          cachedMedications,
          cachedMedications.mealRelation,
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          cachedPatientProfiles,
          cachedPatientProfiles.canReceiveMissedDoseAlerts,
        );
        await migrator.addColumn(
          cachedPatientProfiles,
          cachedPatientProfiles.canViewMedicationPlan,
        );
        await migrator.addColumn(
          cachedPatientProfiles,
          cachedPatientProfiles.missedDoseGraceMinutes,
        );
      }
    },
  );
}
