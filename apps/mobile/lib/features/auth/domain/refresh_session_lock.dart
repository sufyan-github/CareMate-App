abstract interface class RefreshSessionLock {
  Future<T> synchronized<T>(Future<T> Function() operation);
}

class NoopRefreshSessionLock implements RefreshSessionLock {
  const NoopRefreshSessionLock();

  @override
  Future<T> synchronized<T>(Future<T> Function() operation) => operation();
}
