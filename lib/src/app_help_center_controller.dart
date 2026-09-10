import 'package:flutter/foundation.dart';

import 'app_help_center_config.dart';
import 'models/help_announcement.dart';
import 'models/help_faq_item.dart';
import 'models/help_quick_link.dart';
import 'models/review_prompt.dart';
import 'models/training_video.dart';
import 'models/version_history_item.dart';
import 'services/announcement_service.dart';
import 'services/app_help_center_storage.dart';
import 'services/faq_service.dart';
import 'services/feedback_service.dart';
import 'services/help_link_launcher.dart';
import 'services/training_video_service.dart';
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
    FaqService? faqService,
    TrainingVideoService? trainingVideoService,
    FeedbackService? feedbackService,
    HelpLinkLauncher? linkLauncher,
    ReviewPromptManager? reviewPromptManager,
  })  : storage = storage ?? AppHelpCenterStorage(),
        _announcementService =
            announcementService ?? const AnnouncementService(),
        _versionSupplementService =
            versionSupplementService ?? const VersionSupplementService(),
        _faqService = faqService ?? const FaqService(),
        _trainingVideoService =
            trainingVideoService ?? const TrainingVideoService(),
        _feedbackService = feedbackService ?? const FeedbackService(),
        _linkLauncher = linkLauncher ?? const HelpLinkLauncher(),
        _reviewPromptManager =
            reviewPromptManager ?? _createReviewPromptManager(config) {
    _versionHistory = _sortVersions(config.versionHistory);
    _localAnnouncements = _sortAnnouncements(config.announcements);
    _localFaqItems = config.faqItems;
    _localTrainingVideos =
        _validTrainingVideos(config.trainingVideos?.items ?? const []);
  }

  /// Configuration used by this controller.
  final AppHelpCenterConfig config;

  /// Storage used for read-state persistence.
  final AppHelpCenterStorage storage;
  final AnnouncementService _announcementService;
  final VersionSupplementService _versionSupplementService;
  final FaqService _faqService;
  final TrainingVideoService _trainingVideoService;
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
  bool _isLoadingRemoteAnnouncements = false;
  bool _isLoadingVersionSupplements = false;
  bool _isLoadingRemoteFaqItems = false;
  bool _isLoadingRemoteTrainingVideos = false;
  bool _didFetchRemoteAnnouncements = false;
  bool _didFetchRemoteVersionSupplements = false;
  bool _didFetchRemoteFaqItems = false;
  bool _didFetchRemoteTrainingVideos = false;
  int _announcementRequestGeneration = 0;
  int _versionRequestGeneration = 0;
  int _faqRequestGeneration = 0;
  int _trainingVideoRequestGeneration = 0;
  final Map<String, Object> _remoteErrors = {};
  DateTime _lastViewedVersionPublishedAt =
      DateTime.fromMillisecondsSinceEpoch(0);
  Set<String> _readAnnouncementIds = {};
  List<VersionHistoryItem> _versionHistory = const [];
  List<HelpAnnouncement> _localAnnouncements = const [];
  List<HelpAnnouncement> _remoteAnnouncements = const [];
  List<HelpFaqItem> _localFaqItems = const [];
  List<HelpFaqItem> _remoteFaqItems = const [];
  List<TrainingVideo> _localTrainingVideos = const [];
  List<TrainingVideo> _remoteTrainingVideos = const [];

  /// Whether the controller is loading initial or remote data.
  bool get isLoading => _isLoading;

  /// Whether remote announcements are loading.
  bool get isLoadingRemoteAnnouncements => _isLoadingRemoteAnnouncements;

  /// Whether remote version supplements are currently loading.
  bool get isLoadingVersionSupplements => _isLoadingVersionSupplements;

  /// Whether remote FAQ items are loading.
  bool get isLoadingRemoteFaqItems => _isLoadingRemoteFaqItems;

  /// Whether remote training videos are loading.
  bool get isLoadingRemoteTrainingVideos => _isLoadingRemoteTrainingVideos;

  /// Latest errors by optional remote source.
  ///
  /// Failed optional sources keep their last successful snapshots and do not
  /// prevent other sources from refreshing.
  Map<String, Object> get remoteErrors => Map.unmodifiable(_remoteErrors);

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

  /// FAQ items from local config and remote FAQ JSON.
  List<HelpFaqItem> get faqItems {
    return _mergeFaqItems(local: _localFaqItems, remote: _remoteFaqItems);
  }

  /// Valid local videos merged with the latest successful remote snapshot.
  List<TrainingVideo> get trainingVideos => _mergeTrainingVideos(
        local: _localTrainingVideos,
        remote: _remoteTrainingVideos,
      );

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

  /// Loads persisted state and optionally refreshes remote content in parallel.
  ///
  /// Set [forceRemoteRefresh] for pull-to-refresh or an explicit retry. Normal
  /// loads fetch each configured source at most once.
  Future<void> load({
    bool refreshRemote = true,
    bool forceRemoteRefresh = false,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _loadReadState();
      if (refreshRemote) {
        await Future.wait([
          fetchRemoteAnnouncements(ifNeeded: !forceRemoteRefresh),
          fetchRemoteVersionSupplements(ifNeeded: !forceRemoteRefresh),
          fetchRemoteFaqItems(ifNeeded: !forceRemoteRefresh),
          fetchRemoteTrainingVideos(ifNeeded: !forceRemoteRefresh),
        ]);
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

  /// Fetches remote announcements, replacing the last successful snapshot.
  Future<void> fetchRemoteAnnouncements({bool ifNeeded = false}) async {
    if (config.remoteAnnouncementsUrl == null ||
        (ifNeeded && _didFetchRemoteAnnouncements)) {
      return;
    }
    _didFetchRemoteAnnouncements = true;
    final generation = ++_announcementRequestGeneration;
    _isLoadingRemoteAnnouncements = true;
    _remoteErrors.remove('announcements');
    notifyListeners();
    try {
      final remote = await _announcementService.fetch(config);
      if (generation == _announcementRequestGeneration) {
        _remoteAnnouncements = remote;
      }
    } catch (error) {
      if (generation == _announcementRequestGeneration) {
        _remoteErrors['announcements'] = error;
      }
    } finally {
      if (generation == _announcementRequestGeneration) {
        _isLoadingRemoteAnnouncements = false;
        notifyListeners();
      }
    }
  }

  /// Fetches remote FAQ items and merges them into faqItems.
  Future<void> fetchRemoteFaqItems({bool ifNeeded = false}) async {
    if (config.remoteFaqUrl == null || (ifNeeded && _didFetchRemoteFaqItems)) {
      return;
    }
    _didFetchRemoteFaqItems = true;
    final generation = ++_faqRequestGeneration;
    _isLoadingRemoteFaqItems = true;
    _remoteErrors.remove('faq');
    notifyListeners();
    try {
      final remote = await _faqService.fetch(config);
      if (generation == _faqRequestGeneration) _remoteFaqItems = remote;
    } catch (error) {
      if (generation == _faqRequestGeneration) _remoteErrors['faq'] = error;
    } finally {
      if (generation == _faqRequestGeneration) {
        _isLoadingRemoteFaqItems = false;
        notifyListeners();
      }
    }
  }

  /// Refreshes the remote snapshot while preserving current content on failure.
  Future<void> fetchRemoteTrainingVideos({bool ifNeeded = false}) async {
    if (config.trainingVideos?.remoteUrl == null ||
        (ifNeeded && _didFetchRemoteTrainingVideos)) {
      return;
    }
    _didFetchRemoteTrainingVideos = true;
    final generation = ++_trainingVideoRequestGeneration;
    _isLoadingRemoteTrainingVideos = true;
    _remoteErrors.remove('trainingVideos');
    notifyListeners();
    try {
      final remote = await _trainingVideoService.fetch(config);
      if (generation == _trainingVideoRequestGeneration) {
        _remoteTrainingVideos = _validTrainingVideos(remote);
      }
    } catch (error) {
      if (generation == _trainingVideoRequestGeneration) {
        _remoteErrors['trainingVideos'] = error;
      }
    } finally {
      if (generation == _trainingVideoRequestGeneration) {
        _isLoadingRemoteTrainingVideos = false;
        notifyListeners();
      }
    }
  }

  /// Fetches remote version supplements and merges them into versionHistory.
  Future<void> fetchRemoteVersionSupplements({bool ifNeeded = false}) async {
    if (config.remoteVersionSupplementUrl == null ||
        (ifNeeded && _didFetchRemoteVersionSupplements)) {
      return;
    }
    _didFetchRemoteVersionSupplements = true;
    final generation = ++_versionRequestGeneration;
    _isLoadingVersionSupplements = true;
    _remoteErrors.remove('versionSupplements');
    notifyListeners();

    try {
      final supplements = await _versionSupplementService.fetch(config);
      if (generation == _versionRequestGeneration) {
        _versionHistory = _mergeVersionSupplements(
          local: _sortVersions(config.versionHistory),
          supplements: supplements,
        );
      }
    } catch (error) {
      if (generation == _versionRequestGeneration) {
        _remoteErrors['versionSupplements'] = error;
      }
    } finally {
      if (generation == _versionRequestGeneration) {
        _isLoadingVersionSupplements = false;
        notifyListeners();
      }
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

  static List<HelpFaqItem> _mergeFaqItems({
    required List<HelpFaqItem> local,
    required List<HelpFaqItem> remote,
  }) {
    final byId = <String, HelpFaqItem>{};
    final order = <String>[];

    for (final item in local) {
      byId[item.id] = item;
      order.add(item.id);
    }

    for (final item in remote) {
      if (!byId.containsKey(item.id)) {
        order.add(item.id);
      }
      byId[item.id] = item;
    }

    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!
    ];
  }

  static List<TrainingVideo> _validTrainingVideos(
    Iterable<TrainingVideo> items,
  ) =>
      items.where((item) => item.isValid).toList(growable: false);

  static List<TrainingVideo> _mergeTrainingVideos({
    required List<TrainingVideo> local,
    required List<TrainingVideo> remote,
  }) {
    final byId = <String, TrainingVideo>{};
    final order = <String>[];
    for (final item in [...local, ...remote]) {
      if (!item.isValid) continue;
      if (!byId.containsKey(item.id)) order.add(item.id);
      byId[item.id] = item;
    }
    return [for (final id in order) byId[id]!];
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
