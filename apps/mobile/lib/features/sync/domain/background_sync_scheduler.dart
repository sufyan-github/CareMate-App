abstract interface class BackgroundSyncScheduler {
  Future<void> schedule();
}

class NoopBackgroundSyncScheduler implements BackgroundSyncScheduler {
  const NoopBackgroundSyncScheduler();

  @override
  Future<void> schedule() async {}
}
