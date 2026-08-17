import 'package:caremate/features/insights/domain/insights_models.dart';

class InsightsFailure implements Exception {
  const InsightsFailure(this.message);

  final String message;
}

abstract interface class InsightsGateway {
  Future<List<InventoryPositionSummary>> listInventory({
    required String accessToken,
    required String profileId,
  });

  Future<InventoryPositionSummary> createStockAdjustment({
    required String accessToken,
    required double delta,
    required String positionId,
    required String quantityUnit,
    required String reason,
  });

  Future<InventoryPositionSummary> updateLowStockThreshold({
    required String accessToken,
    required int expectedVersion,
    required double lowStockThreshold,
    required String positionId,
  });

  Future<AdherenceIndicator> getIndicator({
    required String accessToken,
    required DateTime from,
    required String profileId,
    required DateTime to,
  });
}
