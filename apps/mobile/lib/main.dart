import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/features/sync/application/background_sync_entrypoint.dart';
import 'package:caremate/features/sync/data/workmanager_sync_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform)) {
    try {
      await Workmanager().initialize(careMateBackgroundSyncDispatcher);
      await Workmanager().registerPeriodicTask(
        'caremate-periodic-dose-sync',
        careMateDoseSyncTask,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        frequency: const Duration(minutes: 15),
        tag: 'caremate-sync',
      );
    } on Exception {
      // Foreground/manual sync remains available if background setup fails.
    }
  }
  runApp(const CareMateApp());
}
