import 'dart:convert';

enum ProfileType {
  personal,
  work,
  research,
  private
}

enum EnterpriseRole {
  owner,
  auditor,
  developer,
  restricted
}

class EnterpriseProfile {
  final String id;
  final String nameEn;
  final String nameAr;
  final ProfileType type;
  final EnterpriseRole role;
  final String credentialToken;
  final bool isMfaActive;

  EnterpriseProfile({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.type,
    required this.role,
    required this.credentialToken,
    this.isMfaActive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'type': type.name,
        'role': role.name,
        'credentialToken': credentialToken,
        'isMfaActive': isMfaActive,
      };

  factory EnterpriseProfile.fromJson(Map<String, dynamic> json) => EnterpriseProfile(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        type: ProfileType.values.firstWhere((e) => e.name == json['type']),
        role: EnterpriseRole.values.firstWhere((e) => e.name == json['role']),
        credentialToken: json['credentialToken'] as String? ?? 'TOKEN_GEN',
        isMfaActive: json['isMfaActive'] as bool? ?? false,
      );
}

class SecureWorkspace {
  final String id;
  final String profileId;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String templateType; // 'Military', 'Finance', 'R&D', 'General'
  final List<String> isolatedResourceIds; // Isolated file/vault element keys
  final DateTime createdAt;
  final bool isSealed;

  SecureWorkspace({
    required this.id,
    required this.profileId,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.templateType,
    required this.isolatedResourceIds,
    required this.createdAt,
    this.isSealed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'templateType': templateType,
        'isolatedResourceIds': isolatedResourceIds,
        'createdAt': createdAt.toIso8601String(),
        'isSealed': isSealed,
      };

  factory SecureWorkspace.fromJson(Map<String, dynamic> json) => SecureWorkspace(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        templateType: json['templateType'] as String? ?? 'General',
        isolatedResourceIds: List<String>.from(json['isolatedResourceIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isSealed: json['isSealed'] as bool? ?? false,
      );
}

class WorkspaceActivityLog {
  final String id;
  final String workspaceId;
  final String profileId;
  final String detailsEn;
  final String detailsAr;
  final String severity; // 'info', 'warning', 'critical'
  final DateTime timestamp;

  WorkspaceActivityLog({
    required this.id,
    required this.workspaceId,
    required this.profileId,
    required this.detailsEn,
    required this.detailsAr,
    required this.severity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'profileId': profileId,
        'detailsEn': detailsEn,
        'detailsAr': detailsAr,
        'severity': severity,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkspaceActivityLog.fromJson(Map<String, dynamic> json) => WorkspaceActivityLog(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String,
        profileId: json['profileId'] as String,
        detailsEn: json['detailsEn'] as String,
        detailsAr: json['detailsAr'] as String,
        severity: json['severity'] as String? ?? 'info',
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
