import 'package:flutter/material.dart';

class RimanCommand {
  final String command;
  final String descriptionEn;
  final String descriptionAr;
  final String category;
  final IconData icon;

  const RimanCommand({
    required this.command,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.category,
    required this.icon,
  });
}

class UniversalSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'vault' (Smart Vaults), 'file' (File Shield), 'note' (Secure Notes), 'journal' (Secure Journal), 'telemetry' (Sentinel/Kernel), 'log', 'capsule'
  final String category;
  final String destinationTabKey;
  final int tabIndex;

  const UniversalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.category,
    required this.destinationTabKey,
    required this.tabIndex,
  });
}

class GlobalActivityItem {
  final String id;
  final String titleEn;
  final String titleAr;
  final String detailsEn;
  final String detailsAr;
  final DateTime timestamp;
  final String severity; // 'info', 'warning', 'critical', 'success'
  final String source; // 'System', 'Vault', 'Sentinel', 'Network', 'Cloud'

  const GlobalActivityItem({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.detailsEn,
    required this.detailsAr,
    required this.timestamp,
    required this.severity,
    required this.source,
  });
}

class SmartWidgetConfig {
  final String key;
  final String nameEn;
  final String nameAr;
  final bool isEnabled;
  final int order;

  const SmartWidgetConfig({
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.isEnabled,
    required this.order,
  });

  SmartWidgetConfig copyWith({
    bool? isEnabled,
    int? order,
  }) {
    return SmartWidgetConfig(
      key: key,
      nameEn: nameEn,
      nameAr: nameAr,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }
}
