import 'dart:convert';

enum ArchiveState {
  Active,
  ColdStorage,
  LongTerm,
  Historical
}

class ArchiveItem {
  final String id;
  final String originalId;
  final String name;
  final String type; // 'vault', 'file', 'note', 'journal', 'media'
  final int sizeInBytes;
  final ArchiveState state;
  final double healthScore; // 0.0 to 100.0
  final bool isImmutable;
  final DateTime archivedAt;
  final DateTime lastSnapshotAt;
  final int retentionDays; // e.g., 365, or -1 for infinite
  final int ranking; // 1 to 5 stars for importance / search priority
  final String category;
  final String description;

  ArchiveItem({
    required this.id,
    required this.originalId,
    required this.name,
    required this.type,
    required this.sizeInBytes,
    required this.state,
    required this.healthScore,
    required this.isImmutable,
    required this.archivedAt,
    required this.lastSnapshotAt,
    required this.retentionDays,
    required this.ranking,
    required this.category,
    this.description = '',
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalId': originalId,
        'name': name,
        'type': type,
        'sizeInBytes': sizeInBytes,
        'state': state.index,
        'healthScore': healthScore,
        'isImmutable': isImmutable,
        'archivedAt': archivedAt.toIso8601String(),
        'lastSnapshotAt': lastSnapshotAt.toIso8601String(),
        'retentionDays': retentionDays,
        'ranking': ranking,
        'category': category,
        'description': description,
      };

  factory ArchiveItem.fromJson(Map<String, dynamic> json) => ArchiveItem(
        id: json['id'] as String,
        originalId: json['originalId'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        sizeInBytes: json['sizeInBytes'] as int,
        state: ArchiveState.values[json['state'] as int? ?? 0],
        healthScore: (json['healthScore'] as num? ?? 100.0).toDouble(),
        isImmutable: json['isImmutable'] as bool? ?? false,
        archivedAt: DateTime.parse(json['archivedAt'] as String),
        lastSnapshotAt: DateTime.parse(json['lastSnapshotAt'] as String),
        retentionDays: json['retentionDays'] as int? ?? -1,
        ranking: json['ranking'] as int? ?? 3,
        category: json['category'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
      );
}

class ArchiveSnapshot {
  final String id;
  final String archiveId;
  final DateTime timestamp;
  final int sizeInBytes;
  final String integrityHash;
  final String status; // 'Verified', 'Slight Drift', 'In Repair'

  ArchiveSnapshot({
    required this.id,
    required this.archiveId,
    required this.timestamp,
    required this.sizeInBytes,
    required this.integrityHash,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'archiveId': archiveId,
        'timestamp': timestamp.toIso8601String(),
        'sizeInBytes': sizeInBytes,
        'integrityHash': integrityHash,
        'status': status,
      };

  factory ArchiveSnapshot.fromJson(Map<String, dynamic> json) => ArchiveSnapshot(
        id: json['id'] as String,
        archiveId: json['archiveId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sizeInBytes: json['sizeInBytes'] as int,
        integrityHash: json['integrityHash'] as String,
        status: json['status'] as String,
      );
}

class ArchiveHealthMetrics {
  final double overallScore; // 0.0 to 100.0
  final int totalCapacityBytes;
  final int usedCapacityBytes;
  final int totalArchives;
  final int immutableCount;
  final int coldStorageCount;
  final int longTermCount;
  final int historicalCount;

  ArchiveHealthMetrics({
    required this.overallScore,
    required this.totalCapacityBytes,
    required this.usedCapacityBytes,
    required this.totalArchives,
    required this.immutableCount,
    required this.coldStorageCount,
    required this.longTermCount,
    required this.historicalCount,
  });
}
