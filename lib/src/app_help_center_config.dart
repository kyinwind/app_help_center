import 'package:flutter/widgets.dart';

import 'models/help_announcement.dart';
import 'models/help_faq_item.dart';
import 'models/help_feedback.dart';
import 'models/help_quick_link.dart';
import 'models/version_history_item.dart';

typedef AnnouncementRemoteParser = List<HelpAnnouncement> Function(
  Object decodedJson,
);

typedef VersionSupplementRemoteParser = List<VersionHistorySupplement> Function(
  Object decodedJson,
);

class AppHelpCenterConfig {
  const AppHelpCenterConfig({
    required this.appName,
    this.announcements = const [],
    this.remoteAnnouncementsUrl,
    this.remoteAnnouncementsParser,
    this.versionHistory = const [],
    this.remoteVersionSupplementUrl,
    this.remoteVersionSupplementParser,
    this.quickLinks = const [],
    this.faqItems = const [],
    this.includeDefaultQuickLinks = true,
    this.supportUrl,
    this.ratingUrl,
    this.feedback,
    this.onOpenSupport,
    this.onOpenRating,
    this.locale,
    this.copyOverrides = const {},
    this.refreshRemoteOnOpen = true,
    this.showOnlyLatestVersionByDefault = true,
    this.versionHistoryStorageKey =
        'app_help_center.version_history.last_viewed_published_at',
    this.announcementStorageKey = 'app_help_center.announcements.read_ids',
    this.markExistingVersionsAsReadOnFirstLoad = true,
  });

  final String appName;
  final List<HelpAnnouncement> announcements;
  final Uri? remoteAnnouncementsUrl;
  final AnnouncementRemoteParser? remoteAnnouncementsParser;
  final List<VersionHistoryItem> versionHistory;
  final Uri? remoteVersionSupplementUrl;
  final VersionSupplementRemoteParser? remoteVersionSupplementParser;
  final List<HelpQuickLink> quickLinks;
  final List<HelpFaqItem> faqItems;
  final bool includeDefaultQuickLinks;
  final Uri? supportUrl;
  final Uri? ratingUrl;
  final HelpFeedbackConfig? feedback;
  final Future<void> Function()? onOpenSupport;
  final Future<void> Function()? onOpenRating;
  final Locale? locale;
  final Map<String, String> copyOverrides;
  final bool refreshRemoteOnOpen;
  final bool showOnlyLatestVersionByDefault;
  final String versionHistoryStorageKey;
  final String announcementStorageKey;
  final bool markExistingVersionsAsReadOnFirstLoad;
}
