enum HelpAnnouncementLevel {
  info,
  success,
  warning,
  critical,
}

class HelpAnnouncement {
  const HelpAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.publishedAt,
    this.level = HelpAnnouncementLevel.info,
    this.linkTitle,
    this.linkUrl,
    this.isPinned = false,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String message;
  final DateTime publishedAt;
  final HelpAnnouncementLevel level;
  final String? linkTitle;
  final Uri? linkUrl;
  final bool isPinned;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiresAt = this.expiresAt;
    return expiresAt != null && DateTime.now().isAfter(expiresAt);
  }

  factory HelpAnnouncement.fromJson(Map<String, dynamic> json) {
    final publishedAt = _parseDate(json['publishedAt']) ??
        _parseDate(json['published_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return HelpAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: (json['message'] ?? json['body'] ?? '') as String,
      publishedAt: publishedAt,
      level: HelpAnnouncementLevel.values.firstWhere(
        (value) => value.name == json['level'],
        orElse: () => HelpAnnouncementLevel.info,
      ),
      linkTitle: json['linkTitle'] as String? ?? json['link_title'] as String?,
      linkUrl: _parseUri(json['linkURL'] ?? json['linkUrl'] ?? json['url']),
      isPinned:
          json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      expiresAt: _parseDate(json['expiresAt'] ?? json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'publishedAt': publishedAt.toIso8601String(),
      'level': level.name,
      if (linkTitle != null) 'linkTitle': linkTitle,
      if (linkUrl != null) 'linkURL': linkUrl.toString(),
      'isPinned': isPinned,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
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

  static Uri? _parseUri(Object? value) {
    if (value is Uri) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return Uri.tryParse(value);
    }
    return null;
  }
}
