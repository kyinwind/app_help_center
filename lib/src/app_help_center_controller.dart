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

class AppHelpCenterController extends ChangeNotifier {
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

  final AppHelpCenterConfig config;
  final AppHelpCenterStorage storage;
  final AnnouncementService _announcementService;
  final VersionSupplementService _versionSupplementService;
  final FeedbackService _feedbackService;
  final HelpLinkLauncher _linkLauncher;
  final ReviewPromptManager? _reviewPromptManager;

  /// The review prompt manager, accessible from UI for showing the dialog.
  /// Returns `null` when reviewPrompt config is not provided.
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

  bool get isLoading => _isLoading;
  bool get isLoadingVersionSupplements => _isLoadingVersionSupplements;
  Object? get lastError => _lastError;
  DateTime get lastViewedVersionPublishedAt => _lastViewedVersionPublishedAt;

  List<VersionHistoryItem> get versionHistory => _versionHistory;

  List<HelpAnnouncement> get announcements {
    final byId = <String, HelpAnnouncement>{
      for (final item in _localAnnouncements) item.id: item,
      for (final item in _remoteAnnouncements) item.id: item,
    };
    return _sortAnnouncements(byId.values.where((item) => !item.isExpired));
  }

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

  bool get hasUnreadAnnouncements {
    return announcements.any(isAnnouncementUnread);
  }

  bool get hasUnreadVersions {
    return versionHistory.any(isVersionUnread);
  }

  bool get hasUnreadContent => hasUnreadAnnouncements || hasUnreadVersions;

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

  bool isAnnouncementUnread(HelpAnnouncement item) {
    return !_readAnnouncementIds.contains(item.id);
  }

  bool isVersionUnread(VersionHistoryItem item) {
    return item.publishedAt.isAfter(_lastViewedVersionPublishedAt);
  }

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

  Future<void> resetReadState() async {
    await storage.reset(
      versionHistoryStorageKey: config.versionHistoryStorageKey,
      announcementStorageKey: config.announcementStorageKey,
    );
    _lastViewedVersionPublishedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _readAnnouncementIds = {};
    notifyListeners();
  }

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

  FeedbackService get feedbackService => _feedbackService;

  bool get hasFeedback => config.feedback?.isConfigured == true;

  Future<void> openWebFormFeedback() async {
    _recordReviewPromptAction('feedback.webForm');
    final url = config.feedback?.webFormUrl;
    if (url != null) {
      await _linkLauncher.open(url);
    }
  }

  Future<void> openUrl(Uri url) async {
    await _linkLauncher.open(url);
  }

  /// Check whether the review prompt should be shown for the given action type.
  ///
  /// Returns `true` if the dual threshold (click count + day count) is met.
  /// Mirrors SwiftHelpCenter's `checkReviewPopup(_:)` top-level function.
  ///
  /// If `true`, the caller should call `showReviewPromptDialog()` from the view.
  bool checkReviewPrompt(String actType) {
    return _recordReviewPromptAction(actType);
  }

  bool _recordReviewPromptAction(String actType) {
    return _reviewPromptManager?.needShowPopup(actType) ?? false;
  }

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
