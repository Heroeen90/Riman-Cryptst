import 'dart:convert';

enum InsightCategory {
  security,
  storage,
  behavior,
  compliance
}

enum InsightSeverity {
  low,
  medium,
  high,
  critical
}

class IntelligenceInsight {
  final String insightId;
  final InsightCategory category;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final InsightSeverity severity;
  final bool isResolved;
  final String recommendationEn;
  final String recommendationAr;
  final DateTime timestamp;

  IntelligenceInsight({
    required this.insightId,
    required this.category,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.severity,
    this.isResolved = false,
    required this.recommendationEn,
    required this.recommendationAr,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'insightId': insightId,
        'category': category.name,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'severity': severity.name,
        'isResolved': isResolved,
        'recommendationEn': recommendationEn,
        'recommendationAr': recommendationAr,
        'timestamp': timestamp.toIso8601String(),
      };

  factory IntelligenceInsight.fromJson(Map<String, dynamic> json) => IntelligenceInsight(
        insightId: json['insightId'] as String,
        category: InsightCategory.values.firstWhere((e) => e.name == json['category']),
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        severity: InsightSeverity.values.firstWhere((e) => e.name == json['severity']),
        isResolved: json['isResolved'] as bool? ?? false,
        recommendationEn: json['recommendationEn'] as String,
        recommendationAr: json['recommendationAr'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class RiskMetricNode {
  final String metricId;
  final String nameEn;
  final String nameAr;
  final double currentScore; // 0.0 to 100.0 (where higher means higher vulnerability/risk)
  final String statusLabelEn;
  final String statusLabelAr;

  RiskMetricNode({
    required this.metricId,
    required this.nameEn,
    required this.nameAr,
    required this.currentScore,
    required this.statusLabelEn,
    required this.statusLabelAr,
  });

  Map<String, dynamic> toJson() => {
        'metricId': metricId,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'currentScore': currentScore,
        'statusLabelEn': statusLabelEn,
        'statusLabelAr': statusLabelAr,
      };

  factory RiskMetricNode.fromJson(Map<String, dynamic> json) => RiskMetricNode(
        metricId: json['metricId'] as String,
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        currentScore: (json['currentScore'] as num).toDouble(),
        statusLabelEn: json['statusLabelEn'] as String,
        statusLabelAr: json['statusLabelAr'] as String,
      );
}

class StorageTelemetryPoint {
  final DateTime recordTime;
  final int totalFilesTracked;
  final int symmetricCipherBytes;
  final int asymmetricCipherBytes;
  final double cumulativeGrowthRate;

  StorageTelemetryPoint({
    required this.recordTime,
    required this.totalFilesTracked,
    required this.symmetricCipherBytes,
    required this.asymmetricCipherBytes,
    required this.cumulativeGrowthRate,
  });

  Map<String, dynamic> toJson() => {
        'recordTime': recordTime.toIso8601String(),
        'totalFilesTracked': totalFilesTracked,
        'symmetricCipherBytes': symmetricCipherBytes,
        'asymmetricCipherBytes': asymmetricCipherBytes,
        'cumulativeGrowthRate': cumulativeGrowthRate,
      };

  factory StorageTelemetryPoint.fromJson(Map<String, dynamic> json) => StorageTelemetryPoint(
        recordTime: DateTime.parse(json['recordTime'] as String),
        totalFilesTracked: json['totalFilesTracked'] as int,
        symmetricCipherBytes: json['symmetricCipherBytes'] as int,
        asymmetricCipherBytes: json['asymmetricCipherBytes'] as int,
        cumulativeGrowthRate: (json['cumulativeGrowthRate'] as num).toDouble(),
      );
}

class BehaviorAuditReport {
  final String recordId;
  final String actorRole;
  final String operationTypeEn;
  final String operationTypeAr;
  final double anomalyConfidence; // 0.0 to 1.0
  final bool isSuspectedAtypical;
  final DateTime eventTime;

  BehaviorAuditReport({
    required this.recordId,
    required this.actorRole,
    required this.operationTypeEn,
    required this.operationTypeAr,
    required this.anomalyConfidence,
    required this.isSuspectedAtypical,
    required this.eventTime,
  });

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'actorRole': actorRole,
        'operationTypeEn': operationTypeEn,
        'operationTypeAr': operationTypeAr,
        'anomalyConfidence': anomalyConfidence,
        'isSuspectedAtypical': isSuspectedAtypical,
        'eventTime': eventTime.toIso8601String(),
      };

  factory BehaviorAuditReport.fromJson(Map<String, dynamic> json) => BehaviorAuditReport(
        recordId: json['recordId'] as String,
        actorRole: json['actorRole'] as String,
        operationTypeEn: json['operationTypeEn'] as String,
        operationTypeAr: json['operationTypeAr'] as String,
        anomalyConfidence: (json['anomalyConfidence'] as num).toDouble(),
        isSuspectedAtypical: json['isSuspectedAtypical'] as bool? ?? false,
        eventTime: DateTime.parse(json['eventTime'] as String),
      );
}
