import 'dart:io';

import 'package:caremate/features/auth/domain/refresh_session_lock.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Serializes refresh-token rotation across the UI and WorkManager isolates.
class FileRefreshSessionLock implements RefreshSessionLock {
  const FileRefreshSessionLock();

  @override
  Future<T> synchronized<T>(Future<T> Function() operation) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final lockFile = File(
      path.join(supportDirectory.path, 'caremate-refresh-session.lock'),
    );
    final handle = await lockFile.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      return await operation();
    } finally {
      await handle.unlock();
      await handle.close();
    }
  }
}
