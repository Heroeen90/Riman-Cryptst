import 'dart:convert';

class ForensicFileIntegrity {
  final String id;
  final String resourceId;
  final String resourceName;
  final String resourceType; // 'vault', 'file', 'note', 'journal'
  final String sha256Hash;
  final String sha512Hash;
  final DateTime registeredAt;
  final DateTime lastCheckedAt;
  final bool isTampered;
  final String originalMetadata;

  ForensicFileIntegrity({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.resourceType,
    required this.sha256Hash,
    required this.sha512Hash,
    required this.registeredAt,
    required this.lastCheckedAt,
    required this.isTampered,
    required this.originalMetadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'resourceName': resourceName,
        'resourceType': resourceType,
        'sha255Hash': sha256Hash, // preserving key but correct property name sha256Hash is fine
        'sha256Hash': sha256Hash,
        'sha512Hash': sha512Hash,
        'registeredAt': registeredAt.toIso8601String(),
        'lastCheckedAt': lastCheckedAt.toIso8601String(),
        'isTampered': isTampered,
        'originalMetadata': originalMetadata,
      };

  factory ForensicFileIntegrity.fromJson(Map<String, dynamic> json) => ForensicFileIntegrity(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        resourceName: json['resourceName'] as String,
        resourceType: json['resourceType'] as String,
        sha256Hash: (json['sha256Hash'] ?? json['sha255Hash'] ?? '') as String,
        sha512Hash: (json['sha512Hash'] ?? '') as String,
        registeredAt: DateTime.parse(json['registeredAt'] as String),
        lastCheckedAt: DateTime.parse(json['lastCheckedAt'] as String),
        isTampered: json['isTampered'] as bool? ?? false,
        originalMetadata: json['originalMetadata'] as String? ?? '',
      );
}

class TamperEvent {
  final String id;
  final String resourceId;
  final String resourceName;
  final String details;
  final DateTime timestamp;
  final String severity; // 'Low', 'Medium', 'High', 'Critical'
  final bool isResolved;
  final String resolutionNotes;

  TamperEvent({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.details,
    required this.timestamp,
    required this.severity,
    required this.isResolved,
    this.resolutionNotes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'resourceName': resourceName,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
        'severity': severity,
        'isResolved': isResolved,
        'resolutionNotes': resolutionNotes,
      };

  factory TamperEvent.fromJson(Map<String, dynamic> json) => TamperEvent(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        resourceName: json['resourceName'] as String,
        details: json['details'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        severity: json['severity'] as String? ?? 'Medium',
        isResolved: json['isResolved'] as bool? ?? false,
        resolutionNotes: json['resolutionNotes'] as String? ?? '',
      );
}

class AuditLogEntry {
  final String id;
  final String action;
  final String entityType;
  final String details;
  final DateTime timestamp;
  final String inspector;

  AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.details,
    required this.timestamp,
    required this.inspector,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'entityType': entityType,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
        'inspector': inspector,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        action: json['action'] as String,
        entityType: json['entityType'] as String,
        details: json['details'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        inspector: json['inspector'] as String,
      );
}
