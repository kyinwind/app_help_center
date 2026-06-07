import 'help_video_link.dart';

class VersionHistoryItem {
  VersionHistoryItem({
    String? id,
    required this.versionName,
    required this.publishedAt,
    required this.changes,
    this.videoTitle,
    this.videoLinks = const [],
  }) : id = id ?? _makeId(versionName, publishedAt);

  final String id;
  final String versionName;
  final DateTime publishedAt;
  final String changes;
  final String? videoTitle;
  final List<HelpVideoLink> videoLinks;

  bool get hasVideoLinks => videoLinks.isNotEmpty;

  VersionHistoryItem copyWith({
    String? id,
    String? versionName,
    DateTime? publishedAt,
    String? changes,
    String? videoTitle,
    List<HelpVideoLink>? videoLinks,
  }) {
    return VersionHistoryItem(
      id: id ?? this.id,
      versionName: versionName ?? this.versionName,
      publishedAt: publishedAt ?? this.publishedAt,
      changes: changes ?? this.changes,
      videoTitle: videoTitle ?? this.videoTitle,
      videoLinks: videoLinks ?? this.videoLinks,
    );
  }

  factory VersionHistoryItem.fromJson(Map<String, dynamic> json) {
    final publishedAt =
        _parseDate(json['publishedAt'] ?? json['published_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return VersionHistoryItem(
      id: json['id'] as String?,
      versionName:
          json['versionName'] as String? ?? json['version'] as String? ?? '',
      publishedAt: publishedAt,
      changes: _parseChanges(json['changes']),
      videoTitle:
          json['videoTitle'] as String? ?? json['video_title'] as String?,
      videoLinks: (json['videoLinks'] as List<dynamic>? ??
              json['video_links'] as List<dynamic>? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .map(HelpVideoLink.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versionName': versionName,
      'publishedAt': publishedAt.toIso8601String(),
      'changes': changes,
      if (videoTitle != null) 'videoTitle': videoTitle,
      if (videoLinks.isNotEmpty)
        'videoLinks': videoLinks.map((link) => link.toJson()).toList(),
    };
  }

  static String _makeId(String versionName, DateTime publishedAt) {
    return '$versionName-${publishedAt.millisecondsSinceEpoch}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _parseChanges(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is List<dynamic>) {
      return value.map((item) => item.toString()).join('\n');
    }
    return '';
  }
}

class VersionHistorySupplement {
  const VersionHistorySupplement({
    required this.id,
    this.videoTitle,
    this.videoLinks,
  });

  final String id;
  final String? videoTitle;
  final List<HelpVideoLink>? videoLinks;

  factory VersionHistorySupplement.fromJson(Map<String, dynamic> json) {
    return VersionHistorySupplement(
      id: json['id'] as String,
      videoTitle:
          json['videoTitle'] as String? ?? json['video_title'] as String?,
      videoLinks: (json['videoLinks'] as List<dynamic>? ??
              json['video_links'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(HelpVideoLink.fromJson)
          .toList(),
    );
  }
}
