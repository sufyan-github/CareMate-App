class StockAdjustmentSummary {
  const StockAdjustmentSummary({
    required this.createdAt,
    required this.delta,
    required this.id,
    required this.reason,
  });

  factory StockAdjustmentSummary.fromJson(Map<String, dynamic> json) =>
      StockAdjustmentSummary(
        createdAt: DateTime.parse(json['createdAt'] as String),
        delta: (json['delta'] as num).toDouble(),
        id: json['id'] as String,
        reason: json['reason'] as String,
      );

  final DateTime createdAt;
  final double delta;
  final String id;
  final String reason;
}

class InventoryPositionSummary {
  const InventoryPositionSummary({
    required this.adjustments,
    required this.estimatedDaysRemaining,
    required this.estimatedQuantity,
    required this.id,
    required this.isLowStock,
    required this.lowStockThreshold,
    required this.medicationId,
    required this.medicationName,
    required this.projectedRunOutAt,
    required this.quantityUnit,
    required this.version,
  });

  factory InventoryPositionSummary.fromJson(Map<String, dynamic> json) =>
      InventoryPositionSummary(
        adjustments: (json['adjustments'] as List<dynamic>)
            .map(
              (item) =>
                  StockAdjustmentSummary.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
        estimatedQuantity: (json['estimatedQuantity'] as num).toDouble(),
        id: json['id'] as String,
        isLowStock: json['isLowStock'] as bool,
        lowStockThreshold: (json['lowStockThreshold'] as num).toDouble(),
        medicationId: json['medicationId'] as String,
        medicationName: json['medicationName'] as String,
        projectedRunOutAt: json['projectedRunOutAt'] == null
            ? null
            : DateTime.parse(json['projectedRunOutAt'] as String),
        quantityUnit: json['quantityUnit'] as String,
        version: json['version'] as int,
      );

  final List<StockAdjustmentSummary> adjustments;
  final int? estimatedDaysRemaining;
  final double estimatedQuantity;
  final String id;
  final bool isLowStock;
  final double lowStockThreshold;
  final String medicationId;
  final String medicationName;
  final DateTime? projectedRunOutAt;
  final String quantityUnit;
  final int version;
}

class IndicatorCounts {
  const IndicatorCounts({
    required this.lateConfirmed,
    required this.missed,
    required this.onTimeConfirmed,
    required this.skipped,
    required this.unresolved,
  });

  factory IndicatorCounts.fromJson(Map<String, dynamic> json) =>
      IndicatorCounts(
        lateConfirmed: json['lateConfirmed'] as int,
        missed: json['missed'] as int,
        onTimeConfirmed: json['onTimeConfirmed'] as int,
        skipped: json['skipped'] as int,
        unresolved: json['unresolved'] as int,
      );

  final int lateConfirmed;
  final int missed;
  final int onTimeConfirmed;
  final int skipped;
  final int unresolved;
}

class AdherenceIndicator {
  const AdherenceIndicator({
    required this.counts,
    required this.denominator,
    required this.disclaimer,
    required this.from,
    required this.numerator,
    required this.percentage,
    required this.timezone,
    required this.to,
  });

  factory AdherenceIndicator.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    return AdherenceIndicator(
      counts: IndicatorCounts.fromJson(json['counts'] as Map<String, dynamic>),
      denominator: json['denominator'] as int,
      disclaimer: json['disclaimer'] as String,
      from: DateTime.parse(period['from'] as String),
      numerator: json['numerator'] as int,
      percentage: (json['percentage'] as num?)?.toDouble(),
      timezone: period['timezone'] as String,
      to: DateTime.parse(period['to'] as String),
    );
  }

  final IndicatorCounts counts;
  final int denominator;
  final String disclaimer;
  final DateTime from;
  final int numerator;
  final double? percentage;
  final String timezone;
  final DateTime to;
}
