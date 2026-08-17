import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:workmanager/workmanager.dart';

const careMateDoseSyncTask = 'caremate.dose-sync';
const careMateDoseSyncUniqueWork = 'caremate-dose-sync';

class WorkmanagerSyncScheduler implements BackgroundSyncScheduler {
  const WorkmanagerSyncScheduler();

  @override
  Future<void> schedule() => Workmanager().registerOneOffTask(
    careMateDoseSyncUniqueWork,
    careMateDoseSyncTask,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(seconds: 30),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    tag: 'caremate-sync',
  );
}
