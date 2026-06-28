import 'help_video_link.dart';

/// Version history entry displayed in the help center.
class VersionHistoryItem {
  /// Creates a version history entry.
  VersionHistoryItem({
    String? id,
    required this.versionName,
    required this.publishedAt,
    required this.changes,
    this.videoTitle,
    this.videoLinks = const [],
  }) : id = id ?? _makeId(versionName, publishedAt);

  /// Stable identifier used for remote supplement merging.
  final String id;

  /// Version name shown to users, such as v1.2.0.
  final String versionName;

  /// Publication date used for sorting, display, and unread state.
  final DateTime publishedAt;

  /// Release notes or changelog text.
  final String changes;

  /// Optional heading for training videos or release links.
  final String? videoTitle;

  /// Optional videos or article links attached to this version.
  final List<HelpVideoLink> videoLinks;

  /// Whether this version has any attached video or article links.
  bool get hasVideoLinks => videoLinks.isNotEmpty;

  /// Creates a copy with selected fields replaced.
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

  /// Creates a version history entry from JSON.
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

  /// Converts this version history entry to JSON.
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

/// Remote metadata that can enrich a local VersionHistoryItem.
class VersionHistorySupplement {
  /// Creates version supplement metadata.
  const VersionHistorySupplement({
    required this.id,
    this.videoTitle,
    this.videoLinks,
  });

  /// Version id or version name matched against local version history.
  final String id;

  /// Optional heading for attached videos or links.
  final String? videoTitle;

  /// Optional links to attach to the matched version.
  final List<HelpVideoLink>? videoLinks;

  /// Creates a version supplement from JSON.
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
