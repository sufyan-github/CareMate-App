import 'dart:convert';
import 'dart:math';

import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:drift/drift.dart';

class DriftDoseMutationStore implements DoseMutationStore {
  DriftDoseMutationStore(this.database);

  final CareMateLocalDatabase database;

  @override
  Future<void> bindAccount(String userId) async {
    await database.transaction(() async {
      final binding = await (database.select(
        database.localAccountBindings,
      )..where((row) => row.slot.equals(1))).getSingleOrNull();
      if (binding?.userId == userId) return;
      await _clearCachedData();
      await database
          .into(database.localAccountBindings)
          .insertOnConflictUpdate(
            LocalAccountBindingsCompanion.insert(
              userId: userId,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  @override
  Future<void> clearAll() async {
    await database.transaction(() async {
      await _clearCachedData();
      await database.delete(database.localAccountBindings).go();
    });
  }

  Future<void> _clearCachedData() async {
    await database.delete(database.syncMutations).go();
    await database.delete(database.cachedDoseOccurrences).go();
    await database.delete(database.cachedMedications).go();
    await database.delete(database.cachedPatientProfiles).go();
  }

  @override
  Future<void> cacheMedications(
    String profileId,
    List<MedicationSummary> medications,
  ) async {
    await database.transaction(() async {
      await (database.delete(
        database.cachedMedications,
      )..where((row) => row.profileId.equals(profileId))).go();
      final now = DateTime.now().toUtc();
      for (final medication in medications) {
        await database
            .into(database.cachedMedications)
            .insert(
              CachedMedicationsCompanion.insert(
                activeScheduleJson: Value(
                  medication.activeSchedule == null
                      ? null
                      : jsonEncode(_scheduleJson(medication.activeSchedule!)),
                ),
                displayName: medication.displayName,
                form: medication.form,
                id: medication.id,
                profileId: profileId,
                quantityLabel: medication.quantityLabel,
                status: medication.status,
                strengthLabel: Value(medication.strengthLabel),
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> cacheProfiles(List<PatientProfile> profiles) async {
    await database.transaction(() async {
      final existingIds =
          (await database.select(database.cachedPatientProfiles).get())
              .map((row) => row.id)
              .toSet();
      final incomingIds = profiles.map((profile) => profile.id).toSet();
      final now = DateTime.now().toUtc();
      for (final removedProfileId in existingIds.difference(incomingIds)) {
        final removedOccurrenceIds =
            (await (database.select(database.cachedDoseOccurrences)
                      ..where((row) => row.profileId.equals(removedProfileId)))
                    .get())
                .map((row) => row.id)
                .toList(growable: false);
        if (removedOccurrenceIds.isNotEmpty) {
          await (database.update(database.syncMutations)..where(
                (row) =>
                    row.occurrenceId.isIn(removedOccurrenceIds) &
                    row.status.equals(
                      SyncMutationStatus.pending.name.toUpperCase(),
                    ),
              ))
              .write(
                SyncMutationsCompanion(
                  lastErrorCode: const Value('PROFILE_ACCESS_REVOKED'),
                  lastErrorMessage: const Value(
                    'Access to this Patient Profile was revoked.',
                  ),
                  status: Value(SyncMutationStatus.rejected.name.toUpperCase()),
                  updatedAt: Value(now),
                ),
              );
        }
        await (database.delete(
          database.cachedDoseOccurrences,
        )..where((row) => row.profileId.equals(removedProfileId))).go();
        await (database.delete(
          database.cachedMedications,
        )..where((row) => row.profileId.equals(removedProfileId))).go();
        await (database.delete(
          database.cachedPatientProfiles,
        )..where((row) => row.id.equals(removedProfileId))).go();
      }
      for (final profile in profiles) {
        await database
            .into(database.cachedPatientProfiles)
            .insertOnConflictUpdate(
              CachedPatientProfilesCompanion.insert(
                accessRole: profile.accessRole,
                canManage: profile.canManage,
                displayName: profile.displayName,
                id: profile.id,
                timezone: profile.timezone,
                updatedAt: now,
                version: profile.version,
              ),
            );
      }
    });
  }

  @override
  Future<void> cacheServerOccurrences(
    String profileId,
    List<DoseOccurrenceSummary> occurrences,
  ) async {
    await database.transaction(() async {
      await (database.delete(database.cachedDoseOccurrences)..where(
            (row) =>
                row.profileId.equals(profileId) &
                row.pendingMutationId.isNull(),
          ))
          .go();
      for (final occurrence in occurrences) {
        final current = await (database.select(
          database.cachedDoseOccurrences,
        )..where((row) => row.id.equals(occurrence.id))).getSingleOrNull();
        if (current?.pendingMutationId != null) continue;
        await database
            .into(database.cachedDoseOccurrences)
            .insertOnConflictUpdate(_cachedCompanion(profileId, occurrence));
      }
    });
  }

  @override
  Future<void> enqueue(
    DoseSyncMutation mutation,
    DoseOccurrenceSummary optimistic,
  ) async {
    await database.transaction(() async {
      final cached =
          await (database.select(database.cachedDoseOccurrences)
                ..where((row) => row.id.equals(mutation.occurrenceId)))
              .getSingleOrNull();
      if (cached == null) {
        throw StateError('The Dose Occurrence must be cached before acting.');
      }
      final now = DateTime.now().toUtc();
      await database
          .into(database.syncMutations)
          .insert(
            SyncMutationsCompanion.insert(
              action: mutation.action.name.toUpperCase(),
              clientAt: mutation.clientAt.toUtc(),
              createdAt: now,
              expectedVersion: mutation.expectedVersion,
              id: mutation.id,
              installationId: mutation.installationId,
              occurrenceId: mutation.occurrenceId,
              previousOccurrenceJson: jsonEncode(
                _occurrenceJson(_summary(cached)),
              ),
              reason: Value(mutation.reason),
              snoozeMinutes: Value(mutation.snoozeMinutes),
              status: SyncMutationStatus.pending.name.toUpperCase(),
              updatedAt: now,
            ),
          );
      await database
          .into(database.cachedDoseOccurrences)
          .insertOnConflictUpdate(
            _cachedCompanion(
              cached.profileId,
              optimistic,
              pendingMutationId: Value(mutation.id),
            ),
          );
    });
  }

  @override
  Future<DoseOccurrenceSummary?> getOccurrence(String occurrenceId) async {
    final row = await (database.select(
      database.cachedDoseOccurrences,
    )..where((item) => item.id.equals(occurrenceId))).getSingleOrNull();
    return row == null ? null : _summary(row);
  }

  @override
  Future<void> applyResult(DoseSyncResult result) async {
    await database.transaction(() async {
      final now = DateTime.now().toUtc();
      final mutation = await (database.select(
        database.syncMutations,
      )..where((row) => row.id.equals(result.mutationId))).getSingleOrNull();
      if (result.status == SyncMutationStatus.retryLater) {
        if (mutation == null) return;
        final attempt = mutation.attemptCount + 1;
        if (attempt >= 10) {
          await (database.update(
            database.syncMutations,
          )..where((row) => row.id.equals(result.mutationId))).write(
            SyncMutationsCompanion(
              attemptCount: Value(attempt),
              lastErrorCode: const Value('SYNC_RETRY_EXHAUSTED'),
              lastErrorMessage: const Value(
                'CareMate stopped retrying this change. Review the dose and try again.',
              ),
              status: Value(SyncMutationStatus.rejected.name.toUpperCase()),
              updatedAt: Value(now),
            ),
          );
          final current =
              await (database.select(database.cachedDoseOccurrences)..where(
                    (row) => row.pendingMutationId.equals(result.mutationId),
                  ))
                  .getSingleOrNull();
          if (current != null) {
            await database
                .into(database.cachedDoseOccurrences)
                .insertOnConflictUpdate(
                  _cachedCompanion(
                    current.profileId,
                    _occurrenceFromJson(
                      jsonDecode(mutation.previousOccurrenceJson)
                          as Map<String, dynamic>,
                    ),
                    syncErrorCode: const Value('SYNC_RETRY_EXHAUSTED'),
                  ),
                );
          }
          return;
        }
        final baseSeconds = min(30 * pow(2, attempt - 1), 6 * 60 * 60).toInt();
        final jitteredSeconds =
            (baseSeconds * (0.75 + Random().nextDouble() * 0.5)).round();
        await (database.update(
          database.syncMutations,
        )..where((row) => row.id.equals(result.mutationId))).write(
          SyncMutationsCompanion(
            attemptCount: Value(attempt),
            lastErrorCode: Value(result.errorCode),
            lastErrorMessage: Value(result.errorMessage),
            nextAttemptAt: Value(now.add(Duration(seconds: jitteredSeconds))),
            status: Value(SyncMutationStatus.pending.name.toUpperCase()),
            updatedAt: Value(now),
          ),
        );
        return;
      }
      await (database.update(
        database.syncMutations,
      )..where((row) => row.id.equals(result.mutationId))).write(
        SyncMutationsCompanion(
          lastErrorCode: Value(result.errorCode),
          lastErrorMessage: Value(result.errorMessage),
          status: Value(result.status.name.toUpperCase()),
          updatedAt: Value(now),
        ),
      );
      final authoritative = result.authoritative;
      if (authoritative == null) {
        final current =
            await (database.select(database.cachedDoseOccurrences)..where(
                  (row) => row.pendingMutationId.equals(result.mutationId),
                ))
                .getSingleOrNull();
        if (current != null && mutation != null) {
          await database
              .into(database.cachedDoseOccurrences)
              .insertOnConflictUpdate(
                _cachedCompanion(
                  current.profileId,
                  _occurrenceFromJson(
                    jsonDecode(mutation.previousOccurrenceJson)
                        as Map<String, dynamic>,
                  ),
                  syncErrorCode: Value(result.errorCode),
                ),
              );
        }
        return;
      }
      final current = await (database.select(
        database.cachedDoseOccurrences,
      )..where((row) => row.id.equals(authoritative.id))).getSingleOrNull();
      if (current == null) return;
      await database
          .into(database.cachedDoseOccurrences)
          .insertOnConflictUpdate(
            _cachedCompanion(
              current.profileId,
              DoseOccurrenceSummary(
                confirmedAt: authoritative.confirmedAt,
                id: current.id,
                medicationName: current.medicationName,
                missedAt: authoritative.missedAt,
                plannedAt: current.plannedAt,
                plannedLocalDateTime: current.plannedLocalDateTime,
                quantityLabel: current.quantityLabel,
                reminderSentAt: authoritative.reminderSentAt,
                responseDueAt: authoritative.responseDueAt,
                ruleRevision: current.ruleRevision,
                snoozeCount: authoritative.snoozeCount,
                snoozedUntil: authoritative.snoozedUntil,
                status: authoritative.status,
                timingClassification: authoritative.timingClassification,
                version: authoritative.version,
              ),
              syncErrorCode: Value(result.errorCode),
            ),
          );
    });
  }

  @override
  Future<List<DoseOccurrenceSummary>> listCached(
    String profileId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final start = _localDate(from);
    final end = _localDate(to);
    final rows =
        await (database.select(database.cachedDoseOccurrences)
              ..where(
                (row) =>
                    row.profileId.equals(profileId) &
                    row.plannedLocalDateTime.isBiggerOrEqualValue(
                      '${start}T00:00',
                    ) &
                    row.plannedLocalDateTime.isSmallerOrEqualValue(
                      '${end}T23:59',
                    ),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.plannedAt)]))
            .get();
    return rows.map(_summary).toList(growable: false);
  }

  @override
  Future<List<MedicationSummary>> listCachedMedications(
    String profileId,
  ) async {
    final rows = await (database.select(
      database.cachedMedications,
    )..where((row) => row.profileId.equals(profileId))).get();
    return rows
        .map(
          (row) => MedicationSummary(
            activeSchedule: row.activeScheduleJson == null
                ? null
                : _schedule(
                    jsonDecode(row.activeScheduleJson!) as Map<String, dynamic>,
                  ),
            displayName: row.displayName,
            form: row.form,
            id: row.id,
            quantityLabel: row.quantityLabel,
            status: row.status,
            strengthLabel: row.strengthLabel ?? 'Not set',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<PatientProfile>> listCachedProfiles() async {
    final rows = await database.select(database.cachedPatientProfiles).get();
    return rows
        .map(
          (row) => PatientProfile(
            accessRole: row.accessRole,
            canManage: row.canManage,
            displayName: row.displayName,
            id: row.id,
            timezone: row.timezone,
            version: row.version,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<DoseSyncMutation>> pending({int limit = 50}) async {
    final now = DateTime.now().toUtc();
    final rows =
        await (database.select(database.syncMutations)
              ..where(
                (row) =>
                    row.status.equals(
                      SyncMutationStatus.pending.name.toUpperCase(),
                    ) &
                    (row.nextAttemptAt.isNull() |
                        row.nextAttemptAt.isSmallerOrEqualValue(now)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
              ..limit(limit))
            .get();
    return rows
        .map(
          (row) => DoseSyncMutation(
            action: DoseAction.values.byName(row.action.toLowerCase()),
            clientAt: row.clientAt,
            expectedVersion: row.expectedVersion,
            id: row.id,
            installationId: row.installationId,
            occurrenceId: row.occurrenceId,
            reason: row.reason,
            snoozeMinutes: row.snoozeMinutes,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final count = database.syncMutations.id.count();
    final query = database.selectOnly(database.syncMutations)
      ..addColumns([count])
      ..where(
        database.syncMutations.status.equals(
          SyncMutationStatus.pending.name.toUpperCase(),
        ),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  CachedDoseOccurrencesCompanion _cachedCompanion(
    String profileId,
    DoseOccurrenceSummary occurrence, {
    Value<String?> pendingMutationId = const Value(null),
    Value<String?> syncErrorCode = const Value(null),
  }) => CachedDoseOccurrencesCompanion.insert(
    confirmedAt: Value(occurrence.confirmedAt),
    id: occurrence.id,
    medicationName: occurrence.medicationName,
    missedAt: Value(occurrence.missedAt),
    pendingMutationId: pendingMutationId,
    plannedAt: occurrence.plannedAt.toUtc(),
    plannedLocalDateTime: occurrence.plannedLocalDateTime,
    profileId: profileId,
    quantityLabel: occurrence.quantityLabel,
    reminderSentAt: Value(occurrence.reminderSentAt),
    responseDueAt: Value(occurrence.responseDueAt),
    ruleRevision: Value(occurrence.ruleRevision),
    snoozeCount: Value(occurrence.snoozeCount),
    snoozedUntil: Value(occurrence.snoozedUntil),
    status: occurrence.status,
    syncErrorCode: syncErrorCode,
    timingClassification: Value(occurrence.timingClassification),
    updatedAt: DateTime.now().toUtc(),
    version: occurrence.version,
  );

  DoseOccurrenceSummary _summary(CachedDoseOccurrence row) =>
      DoseOccurrenceSummary(
        confirmedAt: row.confirmedAt,
        id: row.id,
        medicationName: row.medicationName,
        missedAt: row.missedAt,
        pendingSync: row.pendingMutationId != null,
        plannedAt: row.plannedAt,
        plannedLocalDateTime: row.plannedLocalDateTime,
        quantityLabel: row.quantityLabel,
        reminderSentAt: row.reminderSentAt,
        responseDueAt: row.responseDueAt,
        ruleRevision: row.ruleRevision,
        snoozeCount: row.snoozeCount,
        snoozedUntil: row.snoozedUntil,
        status: row.status,
        syncConflictCode: row.syncErrorCode,
        timingClassification: row.timingClassification,
        version: row.version,
      );

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _scheduleJson(MedicationScheduleSummary schedule) => {
    'daysOfWeek': schedule.daysOfWeek,
    'endDate': schedule.endDate?.toIso8601String(),
    'excludedDates': schedule.excludedDates
        .map((date) => date.toIso8601String())
        .toList(growable: false),
    'id': schedule.id,
    'recurrence': schedule.recurrence,
    'revision': schedule.revision,
    'startDate': schedule.startDate.toIso8601String(),
    'status': schedule.status,
    'times': schedule.times,
    'timezone': schedule.timezone,
    'version': schedule.version,
  };

  Map<String, dynamic> _occurrenceJson(DoseOccurrenceSummary occurrence) => {
    'confirmedAt': occurrence.confirmedAt?.toIso8601String(),
    'id': occurrence.id,
    'medicationName': occurrence.medicationName,
    'missedAt': occurrence.missedAt?.toIso8601String(),
    'plannedAt': occurrence.plannedAt.toIso8601String(),
    'plannedLocalDateTime': occurrence.plannedLocalDateTime,
    'quantityLabel': occurrence.quantityLabel,
    'reminderSentAt': occurrence.reminderSentAt?.toIso8601String(),
    'responseDueAt': occurrence.responseDueAt?.toIso8601String(),
    'ruleRevision': occurrence.ruleRevision,
    'snoozeCount': occurrence.snoozeCount,
    'snoozedUntil': occurrence.snoozedUntil?.toIso8601String(),
    'status': occurrence.status,
    'timingClassification': occurrence.timingClassification,
    'version': occurrence.version,
  };

  DoseOccurrenceSummary _occurrenceFromJson(Map<String, dynamic> data) =>
      DoseOccurrenceSummary(
        confirmedAt: _dateFromJson(data['confirmedAt']),
        id: data['id'] as String,
        medicationName: data['medicationName'] as String,
        missedAt: _dateFromJson(data['missedAt']),
        plannedAt: DateTime.parse(data['plannedAt'] as String),
        plannedLocalDateTime: data['plannedLocalDateTime'] as String,
        quantityLabel: data['quantityLabel'] as String,
        reminderSentAt: _dateFromJson(data['reminderSentAt']),
        responseDueAt: _dateFromJson(data['responseDueAt']),
        ruleRevision: data['ruleRevision'] as int,
        snoozeCount: data['snoozeCount'] as int,
        snoozedUntil: _dateFromJson(data['snoozedUntil']),
        status: data['status'] as String,
        timingClassification: data['timingClassification'] as String?,
        version: data['version'] as int,
      );

  DateTime? _dateFromJson(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  MedicationScheduleSummary _schedule(Map<String, dynamic> data) =>
      MedicationScheduleSummary(
        daysOfWeek: (data['daysOfWeek'] as List<dynamic>).cast<int>(),
        endDate: data['endDate'] is String
            ? DateTime.parse(data['endDate'] as String)
            : null,
        excludedDates: (data['excludedDates'] as List<dynamic>)
            .cast<String>()
            .map(DateTime.parse)
            .toList(growable: false),
        id: data['id'] as String,
        recurrence: data['recurrence'] as String,
        revision: data['revision'] as int,
        startDate: DateTime.parse(data['startDate'] as String),
        status: data['status'] as String,
        times: (data['times'] as List<dynamic>).cast<String>(),
        timezone: data['timezone'] as String,
        version: data['version'] as int,
      );
}
