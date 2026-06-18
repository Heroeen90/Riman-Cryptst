import 'dart:convert';

class NexusLink {
  final String id;
  final String sourceId;
  final String sourceType; // 'vault', 'file', 'note', 'journal', 'capsule', 'media'
  final String sourceName;
  final String targetId;
  final String targetType; // 'vault', 'file', 'note', 'journal', 'capsule', 'media'
  final String targetName;
  final String relationType; // 'sync', 'extends', 'backup', 'reference', 'credentials', 'custom'
  final DateTime createdAt;
  final String description;

  NexusLink({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.sourceName,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    required this.relationType,
    required this.createdAt,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'sourceName': sourceName,
        'targetId': targetId,
        'targetType': targetType,
        'targetName': targetName,
        'relationType': relationType,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
      };

  factory NexusLink.fromJson(Map<String, dynamic> json) => NexusLink(
        id: json['id'] as String,
        sourceId: json['sourceId'] as String,
        sourceType: json['sourceType'] as String,
        sourceName: json['sourceName'] as String,
        targetId: json['targetId'] as String,
        targetType: json['targetType'] as String,
        targetName: json['targetName'] as String,
        relationType: json['relationType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String? ?? '',
      );
}

class NexusAsset {
  final String id;
  final String name;
  final String type; // 'vault', 'file', 'note', 'journal', 'capsule', 'media'
  final String details;
  final String category;

  NexusAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    required this.category,
  });
}
