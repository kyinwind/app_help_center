import 'package:flutter/widgets.dart';

import 'models/help_announcement.dart';
import 'models/help_faq_item.dart';
import 'models/help_feedback.dart';
import 'models/help_quick_link.dart';
import 'models/review_prompt.dart';
import 'models/version_history_item.dart';

/// Parses a remote announcements response into help center announcements.
typedef AnnouncementRemoteParser = List<HelpAnnouncement> Function(
  Object decodedJson,
);

/// Parses a remote version supplement response into version metadata.
typedef VersionSupplementRemoteParser = List<VersionHistorySupplement> Function(
  Object decodedJson,
);

/// Parses a remote FAQ response into help center FAQ items.
typedef FaqRemoteParser = List<HelpFaqItem> Function(
  Object decodedJson,
);

/// Configuration for an AppHelpCenterPage and its controller.
class AppHelpCenterConfig {
  /// Creates a help center configuration.
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
    this.remoteFaqUrl,
    this.remoteFaqParser,
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
    this.reviewPrompt,
  });

  /// App name shown in the help center header and feedback metadata.
  final String appName;

  /// Local announcements bundled with the app.
  final List<HelpAnnouncement> announcements;

  /// Optional URL for fetching remote announcements.
  final Uri? remoteAnnouncementsUrl;

  /// Custom parser for remoteAnnouncementsUrl responses.
  final AnnouncementRemoteParser? remoteAnnouncementsParser;

  /// Local version history entries bundled with the app.
  final List<VersionHistoryItem> versionHistory;

  /// Optional URL for fetching version video/article supplements.
  final Uri? remoteVersionSupplementUrl;

  /// Custom parser for remoteVersionSupplementUrl responses.
  final VersionSupplementRemoteParser? remoteVersionSupplementParser;

  /// Custom quick links shown before or after generated defaults.
  final List<HelpQuickLink> quickLinks;

  /// Frequently asked questions shown in the FAQ section.
  final List<HelpFaqItem> faqItems;

  /// Optional URL for fetching remote FAQ items.
  final Uri? remoteFaqUrl;

  /// Custom parser for remoteFaqUrl responses.
  final FaqRemoteParser? remoteFaqParser;

  /// Whether feedback, rating, and support defaults are generated when configured.
  final bool includeDefaultQuickLinks;

  /// URL opened by the default support action.
  final Uri? supportUrl;

  /// URL opened by the default rating action.
  final Uri? ratingUrl;

  /// Built-in feedback form and submission channel configuration.
  final HelpFeedbackConfig? feedback;

  /// Custom support action callback.
  final Future<void> Function()? onOpenSupport;

  /// Custom rating action callback.
  final Future<void> Function()? onOpenRating;

  /// Locale used for built-in strings and date formatting.
  final Locale? locale;

  /// String overrides keyed by the built-in localization keys.
  final Map<String, String> copyOverrides;

  /// Whether remote announcements and supplements load when the page opens.
  final bool refreshRemoteOnOpen;

  /// Whether the version section initially shows only the latest relevant entry.
  final bool showOnlyLatestVersionByDefault;

  /// SharedPreferences key for the last read version timestamp.
  final String versionHistoryStorageKey;

  /// SharedPreferences key for read announcement ids.
  final String announcementStorageKey;

  /// Whether existing versions are treated as read on first load.
  final bool markExistingVersionsAsReadOnFirstLoad;

  /// Optional review prompt behavior configuration.
  final ReviewPromptConfig? reviewPrompt;
}
