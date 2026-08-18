import 'package:caremate/features/care/domain/care_access_gateway.dart';

abstract interface class CaregiverAlertNotifier {
  Future<void> initialize();

  Future<void> show(CaregiverAlert alert);
}

class NoopCaregiverAlertNotifier implements CaregiverAlertNotifier {
  const NoopCaregiverAlertNotifier();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(CaregiverAlert alert) async {}
}
