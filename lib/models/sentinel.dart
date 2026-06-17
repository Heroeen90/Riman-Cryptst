import 'dart:convert';

class SentinelAnomaly {
  final String id;
  final String type; // 'access_pattern', 'decryption_failure', 'signature_drop', 'entropy_anomaly'
  final String severity; // 'Low', 'Medium', 'High', 'Critical'
  final String descriptionEn;
  final String descriptionAr;
  final DateTime detectedAt;
  final bool isResolved;
  final String? resourceId;

  SentinelAnomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.detectedAt,
    this.isResolved = false,
    this.resourceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'severity': severity,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'detectedAt': detectedAt.toIso8601String(),
        'isResolved': isResolved,
        'resourceId': resourceId,
      };

  factory SentinelAnomaly.fromJson(Map<String, dynamic> json) => SentinelAnomaly(
        id: json['id'] as String,
        type: json['type'] as String,
        severity: json['severity'] as String? ?? 'Medium',
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
        resourceId: json['resourceId'] as String?,
      );
}

class SentinelRecommendation {
  final String id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String metricImpact; // e.g., '+15% Score'
  final String category; // 'vault', 'key', 'watchdog', 'backups'
  final bool isApplied;

  SentinelRecommendation({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.metricImpact,
    required this.category,
    this.isApplied = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'metricImpact': metricImpact,
        'category': category,
        'isApplied': isApplied,
      };

  factory SentinelRecommendation.fromJson(Map<String, dynamic> json) => SentinelRecommendation(
        id: json['id'] as String,
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        metricImpact: json['metricImpact'] as String,
        category: json['category'] as String,
        isApplied: json['isApplied'] as bool? ?? false,
      );
}

class SentinelMission {
  final String id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final int rewardScore;

  SentinelMission({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.progress,
    required this.isCompleted,
    required this.rewardScore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'progress': progress,
        'isCompleted': isCompleted,
        'rewardScore': rewardScore,
      };

  factory SentinelMission.fromJson(Map<String, dynamic> json) => SentinelMission(
        id: json['id'] as String,
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        rewardScore: json['rewardScore'] as int? ?? 10,
      );
}

class SentinelScoreHistory {
  final DateTime timestamp;
  final double score;

  SentinelScoreHistory({
    required this.timestamp,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'score': score,
      };

  factory SentinelScoreHistory.fromJson(Map<String, dynamic> json) => SentinelScoreHistory(
        timestamp: DateTime.parse(json['timestamp'] as String),
        score: (json['score'] as num).toDouble(),
      );
}
