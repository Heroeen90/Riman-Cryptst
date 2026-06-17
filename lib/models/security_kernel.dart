import 'dart:convert';

enum KeyStatus {
  active,
  suspended,
  destroyed
}

class CryptographicKeyMeta {
  final String keyId;
  final String algorithm; // 'AES-256-GCM', 'ChaCha20-Poly1305', 'Quantum-Kyber'
  final KeyStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int bitStrength;
  final String contextOwner;

  CryptographicKeyMeta({
    required this.keyId,
    required this.algorithm,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.bitStrength,
    required this.contextOwner,
  });

  Map<String, dynamic> toJson() => {
        'keyId': keyId,
        'algorithm': algorithm,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'bitStrength': bitStrength,
        'contextOwner': contextOwner,
      };

  factory CryptographicKeyMeta.fromJson(Map<String, dynamic> json) => CryptographicKeyMeta(
        keyId: json['keyId'] as String,
        algorithm: json['algorithm'] as String,
        status: KeyStatus.values.firstWhere((e) => e.name == json['status']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        bitStrength: json['bitStrength'] as int,
        contextOwner: json['contextOwner'] as String? ?? 'KernelRoot',
      );
}

class MemoryPagePartition {
  final String pageIndex;
  final int allocatedBytes;
  final String dataClassification; // 'Keys', 'DecryptedCache', 'IdentityTokens'
  final DateTime lastAccessTime;
  final bool isScrubbed;

  MemoryPagePartition({
    required this.pageIndex,
    required this.allocatedBytes,
    required this.dataClassification,
    required this.lastAccessTime,
    this.isScrubbed = false,
  });

  Map<String, dynamic> toJson() => {
        'pageIndex': pageIndex,
        'allocatedBytes': allocatedBytes,
        'dataClassification': dataClassification,
        'lastAccessTime': lastAccessTime.toIso8601String(),
        'isScrubbed': isScrubbed,
      };

  factory MemoryPagePartition.fromJson(Map<String, dynamic> json) => MemoryPagePartition(
        pageIndex: json['pageIndex'] as String,
        allocatedBytes: json['allocatedBytes'] as int,
        dataClassification: json['dataClassification'] as String,
        lastAccessTime: DateTime.parse(json['lastAccessTime'] as String),
        isScrubbed: json['isScrubbed'] as bool? ?? false,
      );
}

class GuardianSession {
  final String sessionId;
  final String tokenHash;
  final String associatedProfileId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int timeToLiveSeconds;
  final bool isActive;

  GuardianSession({
    required this.sessionId,
    required this.tokenHash,
    required this.associatedProfileId,
    required this.createdAt,
    required this.expiresAt,
    required this.timeToLiveSeconds,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'tokenHash': tokenHash,
        'associatedProfileId': associatedProfileId,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'timeToLiveSeconds': timeToLiveSeconds,
        'isActive': isActive,
      };

  factory GuardianSession.fromJson(Map<String, dynamic> json) => GuardianSession(
        sessionId: json['sessionId'] as String,
        tokenHash: json['tokenHash'] as String,
        associatedProfileId: json['associatedProfileId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        timeToLiveSeconds: json['timeToLiveSeconds'] as int? ?? 1800,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class EnforcementPolicy {
  final String policyId;
  final String labelEn;
  final String labelAr;
  final String scope; // 'MFA', 'RESOURCE_ISOLATION', 'MEDIA_EXPORT', 'KEY_ROTATION'
  final bool isEnforced;
  final int severityMultiplier;

  EnforcementPolicy({
    required this.policyId,
    required this.labelEn,
    required this.labelAr,
    required this.scope,
    required this.isEnforced,
    required this.severityMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'policyId': policyId,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'scope': scope,
        'isEnforced': isEnforced,
        'severityMultiplier': severityMultiplier,
      };

  factory EnforcementPolicy.fromJson(Map<String, dynamic> json) => EnforcementPolicy(
        policyId: json['policyId'] as String,
        labelEn: json['labelEn'] as String,
        labelAr: json['labelAr'] as String,
        scope: json['scope'] as String,
        isEnforced: json['isEnforced'] as bool? ?? true,
        severityMultiplier: json['severityMultiplier'] as int? ?? 1,
      );
}

class KernelSecurityEvent {
  final String eventId;
  final String eventCategory; // 'KEY_OP', 'MEMORY_OP', 'POLICY_BREACH', 'SESSION_OP'
  final String detailsEn;
  final String detailsAr;
  final String threatLevel; // 'low', 'medium', 'high', 'critical'
  final DateTime timestamp;

  KernelSecurityEvent({
    required this.eventId,
    required this.eventCategory,
    required this.detailsEn,
    required this.detailsAr,
    required this.threatLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventCategory': eventCategory,
        'detailsEn': detailsEn,
        'detailsAr': detailsAr,
        'threatLevel': threatLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  factory KernelSecurityEvent.fromJson(Map<String, dynamic> json) => KernelSecurityEvent(
        eventId: json['eventId'] as String,
        eventCategory: json['eventCategory'] as String,
        detailsEn: json['detailsEn'] as String,
        detailsAr: json['detailsAr'] as String,
        threatLevel: json['threatLevel'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
