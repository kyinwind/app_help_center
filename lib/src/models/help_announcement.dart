/// Visual importance level for a help center announcement.
enum HelpAnnouncementLevel {
  /// Informational announcement.
  info,

  /// Completed or successful event.
  success,

  /// Notice that may need user attention.
  warning,

  /// Important announcement that should stand out.
  critical,
}

/// Announcement displayed in the help center.
class HelpAnnouncement {
  /// Creates a help center announcement.
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

  /// Stable identifier used for read-state tracking and remote merging.
  final String id;

  /// Announcement title.
  final String title;

  /// Main announcement body text.
  final String message;

  /// Publication date used for sorting and display.
  final DateTime publishedAt;

  /// Visual level used for badge color and icon.
  final HelpAnnouncementLevel level;

  /// Optional label for the details link.
  final String? linkTitle;

  /// Optional details URL opened from the expanded card.
  final Uri? linkUrl;

  /// Whether the announcement is sorted before unpinned announcements.
  final bool isPinned;

  /// Optional expiration date after which the announcement is hidden.
  final DateTime? expiresAt;

  /// Whether expiresAt has passed.
  bool get isExpired {
    final expiresAt = this.expiresAt;
    return expiresAt != null && DateTime.now().isAfter(expiresAt);
  }

  /// Creates an announcement from SwiftHelpCenter-compatible JSON.
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

  /// Converts this announcement to JSON.
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
