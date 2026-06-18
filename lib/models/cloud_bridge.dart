import 'dart:convert';

enum CloudProviderType {
  googleDrive,
  dropbox,
  oneDrive
}

enum SyncStatus {
  idle,
  pending,
  syncing,
  success,
  failed
}

class CloudProfile {
  final String profileId;
  final CloudProviderType provider;
  final String accountEmail;
  final bool isConnected;
  final bool isolatedMetadataOnly; // zero-knowledge toggle
  final DateTime? lastSyncTime;

  CloudProfile({
    required this.profileId,
    required this.provider,
    required this.accountEmail,
    required this.isConnected,
    this.isolatedMetadataOnly = true,
    this.lastSyncTime,
  });

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'provider': provider.name,
        'accountEmail': accountEmail,
        'isConnected': isConnected,
        'isolatedMetadataOnly': isolatedMetadataOnly,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      };

  factory CloudProfile.fromJson(Map<String, dynamic> json) => CloudProfile(
        profileId: json['profileId'] as String,
        provider: CloudProviderType.values.firstWhere((e) => e.name == json['provider']),
        accountEmail: json['accountEmail'] as String,
        isConnected: json['isConnected'] as bool? ?? false,
        isolatedMetadataOnly: json['isolatedMetadataOnly'] as bool? ?? true,
        lastSyncTime: json['lastSyncTime'] != null ? DateTime.parse(json['lastSyncTime'] as String) : null,
      );
}

class SecureBackupPackage {
  final String packageId;
  final String nameEn;
  final String nameAr;
  final List<String> bundledItemIds;
  final int totalBytes;
  final String encryptedDigest; // Local-only SHA-256 hash
  final String localKeyFingerprint; // Fingerprint of Riman's cryptographic key
  final DateTime createdAt;
  final DateTime? syncedAt;
  final SyncStatus status;

  SecureBackupPackage({
    required this.packageId,
    required this.nameEn,
    required this.nameAr,
    required this.bundledItemIds,
    required this.totalBytes,
    required this.encryptedDigest,
    required this.localKeyFingerprint,
    required this.createdAt,
    this.syncedAt,
    required this.status,
  });

  String get sizeFormatted {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'bundledItemIds': bundledItemIds,
        'totalBytes': totalBytes,
        'encryptedDigest': encryptedDigest,
        'localKeyFingerprint': localKeyFingerprint,
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
        'status': status.name,
      };

  factory SecureBackupPackage.fromJson(Map<String, dynamic> json) => SecureBackupPackage(
        packageId: json['packageId'] as String,
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        bundledItemIds: List<String>.from(json['bundledItemIds'] as Iterable),
        totalBytes: json['totalBytes'] as int,
        encryptedDigest: json['encryptedDigest'] as String,
        localKeyFingerprint: json['localKeyFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt'] as String) : null,
        status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      );
}

class SyncConflict {
  final String conflictId;
  final String filenameEn;
  final String filenameAr;
  final String itemType;
  final DateTime localTime;
  final DateTime cloudTime;
  final int localSizeBytes;
  final int cloudSizeBytes;
  final bool isResolved;
  final String? chosenResolution; // 'use_local', 'use_cloud', 'merge'

  SyncConflict({
    required this.conflictId,
    required this.filenameEn,
    required this.filenameAr,
    required this.itemType,
    required this.localTime,
    required this.cloudTime,
    required this.localSizeBytes,
    required this.cloudSizeBytes,
    this.isResolved = false,
    this.chosenResolution,
  });

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'filenameEn': filenameEn,
        'filenameAr': filenameAr,
        'itemType': itemType,
        'localTime': localTime.toIso8601String(),
        'cloudTime': cloudTime.toIso8601String(),
        'localSizeBytes': localSizeBytes,
        'cloudSizeBytes': cloudSizeBytes,
        'isResolved': isResolved,
        'chosenResolution': chosenResolution,
      };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
        conflictId: json['conflictId'] as String,
        filenameEn: json['filenameEn'] as String,
        filenameAr: json['filenameAr'] as String,
        itemType: json['itemType'] as String,
        localTime: DateTime.parse(json['localTime'] as String),
        cloudTime: DateTime.parse(json['cloudTime'] as String),
        localSizeBytes: json['localSizeBytes'] as int,
        cloudSizeBytes: json['cloudSizeBytes'] as int,
        isResolved: json['isResolved'] as bool? ?? false,
        chosenResolution: json['chosenResolution'] as String?,
      );
}

class CloudSyncMetrics {
  final double syncReadinessScore; // 0.0 - 100.0
  final double backupIntegrityScore; // 0.0 - 100.0
  final double syncSecurityScore; // 0.0 - 100.0
  final DateTime lastCheckTime;

  CloudSyncMetrics({
    required this.syncReadinessScore,
    required this.backupIntegrityScore,
    required this.syncSecurityScore,
    required this.lastCheckTime,
  });

  Map<String, dynamic> toJson() => {
        'syncReadinessScore': syncReadinessScore,
        'backupIntegrityScore': backupIntegrityScore,
        'syncSecurityScore': syncSecurityScore,
        'lastCheckTime': lastCheckTime.toIso8601String(),
      };

  factory CloudSyncMetrics.fromJson(Map<String, dynamic> json) => CloudSyncMetrics(
        syncReadinessScore: (json['syncReadinessScore'] as num).toDouble(),
        backupIntegrityScore: (json['backupIntegrityScore'] as num).toDouble(),
        syncSecurityScore: (json['syncSecurityScore'] as num).toDouble(),
        lastCheckTime: DateTime.parse(json['lastCheckTime'] as String),
      );
}
