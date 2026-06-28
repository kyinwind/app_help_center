import 'package:flutter/foundation.dart';

import 'app_help_center_config.dart';
import 'models/help_announcement.dart';
import 'models/help_quick_link.dart';
import 'models/review_prompt.dart';
import 'models/version_history_item.dart';
import 'services/announcement_service.dart';
import 'services/app_help_center_storage.dart';
import 'services/feedback_service.dart';
import 'services/help_link_launcher.dart';
import 'services/version_supplement_service.dart';

/// State controller for AppHelpCenterPage.
///
/// It loads remote data, tracks unread state, opens configured actions, and
/// exposes computed lists for announcements, versions, and quick links.
class AppHelpCenterController extends ChangeNotifier {
  /// Creates a controller for the given help center config.
  AppHelpCenterController({
    required this.config,
    AppHelpCenterStorage? storage,
    AnnouncementService? announcementService,
    VersionSupplementService? versionSupplementService,
    FeedbackService? feedbackService,
    HelpLinkLauncher? linkLauncher,
    ReviewPromptManager? reviewPromptManager,
  })  : storage = storage ?? AppHelpCenterStorage(),
        _announcementService =
            announcementService ?? const AnnouncementService(),
        _versionSupplementService =
            versionSupplementService ?? const VersionSupplementService(),
        _feedbackService = feedbackService ?? const FeedbackService(),
        _linkLauncher = linkLauncher ?? const HelpLinkLauncher(),
        _reviewPromptManager =
            reviewPromptManager ?? _createReviewPromptManager(config) {
    _versionHistory = _sortVersions(config.versionHistory);
    _localAnnouncements = _sortAnnouncements(config.announcements);
  }

  /// Configuration used by this controller.
  final AppHelpCenterConfig config;

  /// Storage used for read-state persistence.
  final AppHelpCenterStorage storage;
  final AnnouncementService _announcementService;
  final VersionSupplementService _versionSupplementService;
  final FeedbackService _feedbackService;
  final HelpLinkLauncher _linkLauncher;
  final ReviewPromptManager? _reviewPromptManager;

  /// The review prompt manager, accessible from UI for showing the dialog.
  /// Returns null when reviewPrompt config is not provided.
  ReviewPromptManager? get reviewPromptManager => _reviewPromptManager;

  static ReviewPromptManager? _createReviewPromptManager(
    AppHelpCenterConfig config,
  ) {
    final promptConfig = config.reviewPrompt;
    if (promptConfig == null) return null;
    return ReviewPromptManager(config: promptConfig);
  }

  bool _isLoading = false;
  Object? _lastError;
  bool _isLoadingVersionSupplements = false;
  DateTime _lastViewedVersionPublishedAt =
      DateTime.fromMillisecondsSinceEpoch(0);
  Set<String> _readAnnouncementIds = {};
  List<VersionHistoryItem> _versionHistory = const [];
  List<HelpAnnouncement> _localAnnouncements = const [];
  List<HelpAnnouncement> _remoteAnnouncements = const [];

  /// Whether the controller is loading initial or remote data.
  bool get isLoading => _isLoading;

  /// Whether remote version supplements are currently loading.
  bool get isLoadingVersionSupplements => _isLoadingVersionSupplements;

  /// Last error captured while loading remote data, if any.
  Object? get lastError => _lastError;

  /// Latest version publication date marked as read.
  DateTime get lastViewedVersionPublishedAt => _lastViewedVersionPublishedAt;

  /// Sorted version history entries with remote supplements applied.
  List<VersionHistoryItem> get versionHistory => _versionHistory;

  /// Sorted, non-expired announcements from local and remote sources.
  List<HelpAnnouncement> get announcements {
    final byId = <String, HelpAnnouncement>{
      for (final item in _localAnnouncements) item.id: item,
      for (final item in _remoteAnnouncements) item.id: item,
    };
    return _sortAnnouncements(byId.values.where((item) => !item.isExpired));
  }

  /// Quick links to show, including generated defaults when enabled.
  List<HelpQuickLink> get quickLinks {
    if (!config.includeDefaultQuickLinks) {
      return config.quickLinks;
    }

    final customLinks = config.quickLinks;
    final links = <HelpQuickLink>[];

    final hasFeedback = customLinks.any(
      (link) => link.actionType == HelpQuickLinkActionType.feedback,
    );
    final hasRating = customLinks.any(
      (link) => link.actionType == HelpQuickLinkActionType.rating,
    );
    final hasSupport = customLinks.any(
      (link) => link.actionType == HelpQuickLinkActionType.support,
    );

    if (!hasFeedback && config.feedback?.isConfigured == true) {
      links.add(HelpQuickLink.feedback());
    }
    if (!hasRating &&
        (config.ratingUrl != null || config.onOpenRating != null)) {
      links.add(HelpQuickLink.rating());
    }
    if (!hasSupport &&
        (config.supportUrl != null || config.onOpenSupport != null)) {
      links.add(HelpQuickLink.support());
    }

    links.addAll(customLinks);
    return links;
  }

  /// Whether any visible announcement has not been marked as read.
  bool get hasUnreadAnnouncements {
    return announcements.any(isAnnouncementUnread);
  }

  /// Whether any version entry is newer than the last read version date.
  bool get hasUnreadVersions {
    return versionHistory.any(isVersionUnread);
  }

  /// Whether announcements or versions contain unread content.
  bool get hasUnreadContent => hasUnreadAnnouncements || hasUnreadVersions;

  /// Loads persisted read state and optionally refreshes remote content.
  Future<void> load({bool refreshRemote = true}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _loadReadState();
      if (refreshRemote) {
        if (config.remoteAnnouncementsUrl != null) {
          _remoteAnnouncements = await _announcementService.fetch(config);
        }
        if (config.remoteVersionSupplementUrl != null) {
          await fetchRemoteVersionSupplements();
        }
      }
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns whether the item has not been marked as read.
  bool isAnnouncementUnread(HelpAnnouncement item) {
    return !_readAnnouncementIds.contains(item.id);
  }

  /// Returns whether the item is newer than the last read version date.
  bool isVersionUnread(VersionHistoryItem item) {
    return item.publishedAt.isAfter(_lastViewedVersionPublishedAt);
  }

  /// Marks an announcement as read and persists the read id.
  Future<void> markAnnouncementRead(HelpAnnouncement item) async {
    if (!isAnnouncementUnread(item)) {
      return;
    }
    _readAnnouncementIds = {..._readAnnouncementIds, item.id};
    await storage.setReadAnnouncementIds(
      config.announcementStorageKey,
      _readAnnouncementIds,
    );
    notifyListeners();
  }

  /// Marks a version entry as read through its publication date.
  Future<void> markVersionRead(VersionHistoryItem item) async {
    if (!isVersionUnread(item)) {
      return;
    }
    _lastViewedVersionPublishedAt = item.publishedAt;
    await storage.setLastViewedVersionPublishedAt(
      config.versionHistoryStorageKey,
      item.publishedAt,
    );
    notifyListeners();
  }

  /// Marks all currently visible announcements and versions as read.
  Future<void> markAllAsRead() async {
    final latestVersionDate = versionHistory
        .map((item) => item.publishedAt)
        .fold<DateTime?>(null, (latest, item) {
      if (latest == null || item.isAfter(latest)) {
        return item;
      }
      return latest;
    });

    if (latestVersionDate != null) {
      _lastViewedVersionPublishedAt = latestVersionDate;
      await storage.setLastViewedVersionPublishedAt(
        config.versionHistoryStorageKey,
        latestVersionDate,
      );
    }

    _readAnnouncementIds = {
      ..._readAnnouncementIds,
      ...announcements.map((item) => item.id),
    };
    await storage.setReadAnnouncementIds(
      config.announcementStorageKey,
      _readAnnouncementIds,
    );
    notifyListeners();
  }

  /// Clears persisted read state for announcements and version history.
  Future<void> resetReadState() async {
    await storage.reset(
      versionHistoryStorageKey: config.versionHistoryStorageKey,
      announcementStorageKey: config.announcementStorageKey,
    );
    _lastViewedVersionPublishedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _readAnnouncementIds = {};
    notifyListeners();
  }

  /// Opens or invokes the action represented by the link.
  Future<void> openQuickLink(HelpQuickLink link) async {
    _recordReviewPromptAction('quickLink.${link.actionType.name}');

    final onTap = link.onTap;
    if (onTap != null) {
      onTap();
      return;
    }

    switch (link.actionType) {
      case HelpQuickLinkActionType.url:
        final url = link.url;
        if (url != null) {
          await _linkLauncher.open(url);
        }
      case HelpQuickLinkActionType.feedback:
        break;
      case HelpQuickLinkActionType.rating:
        await openRating(recordReviewAction: false);
      case HelpQuickLinkActionType.support:
        await openSupport(recordReviewAction: false);
    }
  }

  /// Opens the configured support callback or URL.
  Future<void> openSupport({bool recordReviewAction = true}) async {
    if (recordReviewAction) {
      _recordReviewPromptAction('support');
    }
    final callback = config.onOpenSupport;
    if (callback != null) {
      await callback();
      return;
    }
    final url = config.supportUrl;
    if (url != null) {
      await _linkLauncher.open(url);
    }
  }

  /// Opens the configured rating callback or URL.
  Future<void> openRating({bool recordReviewAction = true}) async {
    if (recordReviewAction) {
      _recordReviewPromptAction('rating');
    }
    final callback = config.onOpenRating;
    if (callback != null) {
      await callback();
      return;
    }
    final url = config.ratingUrl;
    if (url != null) {
      await _linkLauncher.open(url);
    }
  }

  /// Feedback service used by the built-in feedback page.
  FeedbackService get feedbackService => _feedbackService;

  /// Whether the built-in feedback form has at least one configured channel.
  bool get hasFeedback => config.feedback?.isConfigured == true;

  /// Opens the configured web form feedback URL, if present.
  Future<void> openWebFormFeedback() async {
    _recordReviewPromptAction('feedback.webForm');
    final url = config.feedback?.webFormUrl;
    if (url != null) {
      await _linkLauncher.open(url);
    }
  }

  /// Opens an arbitrary external the URL using the configured link launcher.
  Future<void> openUrl(Uri url) async {
    await _linkLauncher.open(url);
  }

  /// Check whether the review prompt should be shown for the given action type.
  ///
  /// Returns true if the dual threshold (click count + day count) is met.
  /// Mirrors SwiftHelpCenter's checkReviewPopup top-level function.
  ///
  /// If true, the caller should call showReviewPromptDialog from the view.
  bool checkReviewPrompt(String actType) {
    return _recordReviewPromptAction(actType);
  }

  bool _recordReviewPromptAction(String actType) {
    return _reviewPromptManager?.needShowPopup(actType) ?? false;
  }

  /// Fetches remote version supplements and merges them into versionHistory.
  Future<void> fetchRemoteVersionSupplements() async {
    _isLoadingVersionSupplements = true;
    notifyListeners();

    try {
      final supplements = await _versionSupplementService.fetch(config);
      _versionHistory = _mergeVersionSupplements(
        local: _versionHistory,
        supplements: supplements,
      );
    } finally {
      _isLoadingVersionSupplements = false;
      notifyListeners();
    }
  }

  Future<void> _loadReadState() async {
    final storedDate = await storage.lastViewedVersionPublishedAt(
      config.versionHistoryStorageKey,
    );

    if (storedDate != null) {
      _lastViewedVersionPublishedAt = storedDate;
    } else if (config.markExistingVersionsAsReadOnFirstLoad &&
        versionHistory.isNotEmpty) {
      _lastViewedVersionPublishedAt = versionHistory.first.publishedAt;
      await storage.setLastViewedVersionPublishedAt(
        config.versionHistoryStorageKey,
        _lastViewedVersionPublishedAt,
      );
    }

    _readAnnouncementIds = await storage.readAnnouncementIds(
      config.announcementStorageKey,
    );
  }

  static List<VersionHistoryItem> _sortVersions(
    Iterable<VersionHistoryItem> items,
  ) {
    return items.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  static List<VersionHistoryItem> _mergeVersionSupplements({
    required List<VersionHistoryItem> local,
    required List<VersionHistorySupplement> supplements,
  }) {
    final supplementsByKey = <String, VersionHistorySupplement>{};
    for (final supplement in supplements) {
      supplementsByKey[supplement.id] = supplement;
      supplementsByKey[_normalizedVersionKey(supplement.id)] = supplement;
    }

    return _sortVersions(
      local.map((item) {
        final supplement = supplementsByKey[item.id] ??
            supplementsByKey[item.versionName] ??
            supplementsByKey[_normalizedVersionKey(item.versionName)];
        if (supplement == null) {
          return item;
        }
        return item.copyWith(
          videoTitle: supplement.videoTitle,
          videoLinks: supplement.videoLinks,
        );
      }),
    );
  }

  static String _normalizedVersionKey(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.startsWith('v')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  static List<HelpAnnouncement> _sortAnnouncements(
    Iterable<HelpAnnouncement> items,
  ) {
    return items.toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.publishedAt.compareTo(a.publishedAt);
      });
  }
}
