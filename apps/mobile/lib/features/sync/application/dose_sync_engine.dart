import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';

class DoseSyncEngine {
  const DoseSyncEngine({required this.gateway, required this.store});

  final DoseSyncGateway gateway;
  final DoseMutationStore store;

  Future<int> syncPending(String accessToken) async {
    final pending = await store.pending();
    if (pending.isEmpty) return 0;
    final results = await gateway.push(accessToken, pending);
    final expectedIds = pending.map((mutation) => mutation.id).toSet();
    for (final result in results) {
      if (!expectedIds.contains(result.mutationId)) continue;
      await store.applyResult(result);
    }
    return results
        .where((result) => result.status != SyncMutationStatus.retryLater)
        .length;
  }
}
