import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for the review prompt manager.
///
/// Mirrors SwiftHelpCenter's `ReviewPromptConfiguration` with dual threshold
/// logic (click count + day count) and four action buttons.
class ReviewPromptConfig {
  const ReviewPromptConfig({
    required this.appName,
    this.defaultClickThreshold = 30,
    this.defaultDaysThreshold = 3,
    this.onOpenSettings,
    this.onReview,
    this.storageKey = 'app_help_center.review_prompt',
  });

  /// App name displayed in the prompt (also used as storage context).
  final String appName;

  /// Number of tracked actions required before showing the prompt.
  /// Default is 30, matching SwiftHelpCenter.
  final int defaultClickThreshold;

  /// Number of days required before showing the prompt.
  /// Default is 3, matching SwiftHelpCenter.
  final int defaultDaysThreshold;

  /// Custom callback when the user taps "Go to Settings".
  /// If null, the prompt simply dismisses without action.
  final VoidCallback? onOpenSettings;

  /// Custom callback when the user taps "Go to Review".
  /// Use this to open your store listing, in-app review flow, or rating page.
  /// If null, the button only dismisses the prompt and silences future prompts.
  final VoidCallback? onReview;

  /// SharedPreferences key prefix for persisting prompt state.
  final String storageKey;
}

// ---------------------------------------------------------------------------
// Internal data models (mirrors SwiftHelpCenter's ClickMenuHistory &
// ReviewPromptInfo)
// ---------------------------------------------------------------------------

class _ClickMenuHistory {
  const _ClickMenuHistory({required this.actType, required this.clickDate});

  final String actType;
  final DateTime clickDate;

  Map<String, dynamic> toMap() => {
        'actType': actType,
        'clickDate': clickDate.toIso8601String(),
      };

  factory _ClickMenuHistory.fromMap(Map<String, dynamic> map) =>
      _ClickMenuHistory(
        actType: map['actType'] as String,
        clickDate: DateTime.parse(map['clickDate'] as String),
      );
}

class _ReviewPromptInfo {
  const _ReviewPromptInfo({
    this.lastPromptDate,
    this.hasReviewed = false,
    required this.maxClickCount,
    required this.maxDaysCount,
    this.isShowReviewPopup = false,
    this.neverPrompt = false,
  });

  final DateTime? lastPromptDate;
  final bool hasReviewed;
  final int maxClickCount;
  final int maxDaysCount;
  final bool isShowReviewPopup;
  final bool neverPrompt;

  Map<String, dynamic> toMap() => {
        'lastPromptDate': lastPromptDate?.toIso8601String(),
        'hasReviewed': hasReviewed,
        'maxClickCount': maxClickCount,
        'maxDaysCount': maxDaysCount,
        'isShowReviewPopup': isShowReviewPopup,
        'neverPrompt': neverPrompt,
      };

  factory _ReviewPromptInfo.fromMap(Map<String, dynamic> map) =>
      _ReviewPromptInfo(
        lastPromptDate: map['lastPromptDate'] != null
            ? DateTime.parse(map['lastPromptDate'] as String)
            : null,
        hasReviewed: map['hasReviewed'] as bool? ?? false,
        maxClickCount: map['maxClickCount'] as int,
        maxDaysCount: map['maxDaysCount'] as int,
        isShowReviewPopup: map['isShowReviewPopup'] as bool? ?? false,
        neverPrompt: map['neverPrompt'] as bool? ?? false,
      );

  _ReviewPromptInfo copyWith({
    DateTime? lastPromptDate,
    bool? hasReviewed,
    int? maxClickCount,
    int? maxDaysCount,
    bool? isShowReviewPopup,
    bool? neverPrompt,
  }) =>
      _ReviewPromptInfo(
        lastPromptDate: lastPromptDate ?? this.lastPromptDate,
        hasReviewed: hasReviewed ?? this.hasReviewed,
        maxClickCount: maxClickCount ?? this.maxClickCount,
        maxDaysCount: maxDaysCount ?? this.maxDaysCount,
        isShowReviewPopup: isShowReviewPopup ?? this.isShowReviewPopup,
        neverPrompt: neverPrompt ?? this.neverPrompt,
      );
}

// ---------------------------------------------------------------------------
// ReviewPromptManager
// ---------------------------------------------------------------------------

/// Manages the review prompt lifecycle with dual threshold logic.
///
/// Mirrors SwiftHelpCenter's `ReviewPromptManager.shared` singleton pattern.
/// The manager tracks user actions (clicks) and days since first action,
/// then triggers a review prompt when both thresholds are met.
///
/// Usage:
/// ```dart
/// final manager = ReviewPromptManager(config: myConfig);
/// if (manager.needShowPopup('AppLogin')) {
///   showReviewPromptDialog(context, manager);
/// }
/// ```
class ReviewPromptManager extends ChangeNotifier {
  ReviewPromptManager({
    required this.config,
    SharedPreferences? preferences,
  }) : _preferences = preferences {
    _initInfo();
  }

  final ReviewPromptConfig config;
  SharedPreferences? _preferences;
  _ReviewPromptInfo? _info;
  List<_ClickMenuHistory> _history = [];

  /// Whether the prompt is currently showing (used by UI to display dialog).
  bool get shouldShowPrompt => _info?.isShowReviewPopup == true;

  /// Whether the user has permanently opted out.
  bool get isNeverPrompt => _info?.neverPrompt == true;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  void _initInfo() {
    _info = _ReviewPromptInfo(
      maxClickCount: config.defaultClickThreshold,
      maxDaysCount: config.defaultDaysThreshold,
    );
    // Async load from storage will override this if data exists
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await _prefs;
    final infoJson = prefs.getString('${config.storageKey}.info');
    final historyJson = prefs.getString('${config.storageKey}.history');

    if (infoJson != null) {
      try {
        _info = _ReviewPromptInfo.fromMap(
          jsonDecode(infoJson) as Map<String, dynamic>,
        );
      } catch (_) {
        // Keep defaults on parse error
      }
    }

    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List<dynamic>;
        _history = list
            .map((e) => _ClickMenuHistory.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _history = [];
      }
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Check whether the review prompt should be shown for the given action.
  ///
  /// Mirrors SwiftHelpCenter's `needShowPopup(type:)`.
  /// Returns `true` when both click count and day thresholds are met.
  /// Automatically records the action for tracking.
  bool needShowPopup(String actType) {
    if (_info == null || _info!.neverPrompt) {
      return false;
    }

    final daysCount = _howMuchDays();

    if (!_info!.isShowReviewPopup) {
      // Record this action
      _history
          .add(_ClickMenuHistory(actType: actType, clickDate: DateTime.now()));
      _saveHistory();

      if (daysCount >= _info!.maxDaysCount &&
          _history.length > _info!.maxClickCount) {
        _info = _info!.copyWith(
          isShowReviewPopup: true,
          lastPromptDate: DateTime.now(),
        );
        _saveInfo();
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  /// User chose "Hold on" (稍后再说).
  ///
  /// Resets the popup flag and increases both thresholds:
  /// - Click threshold += 30
  /// - Days threshold += 3
  ///
  /// Mirrors SwiftHelpCenter's `holdOn()`.
  void holdOn() {
    if (_info == null) return;
    _info = _info!.copyWith(
      isShowReviewPopup: false,
      lastPromptDate: DateTime.now(),
      maxClickCount: _info!.maxClickCount + 30,
      maxDaysCount: _info!.maxDaysCount + 3,
    );
    _saveInfo();
    notifyListeners();
  }

  /// User chose "Never prompt again".
  ///
  /// Permanently suppresses the review prompt.
  /// Mirrors SwiftHelpCenter's `neverPrompt()`.
  void neverPrompt() {
    if (_info == null) return;
    _info = _info!.copyWith(
      hasReviewed: true,
      neverPrompt: true,
    );
    _saveInfo();
    notifyListeners();
  }

  /// Reset all stored data (for testing purposes).
  ///
  /// Mirrors SwiftHelpCenter's `cleanData()`.
  Future<void> cleanData() async {
    final prefs = await _prefs;
    await prefs.remove('${config.storageKey}.info');
    await prefs.remove('${config.storageKey}.history');
    _info = _ReviewPromptInfo(
      maxClickCount: config.defaultClickThreshold,
      maxDaysCount: config.defaultDaysThreshold,
    );
    _history = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  int _howMuchDays() {
    if (_history.isEmpty) return 0;
    final earliest = _history
        .map((h) => h.clickDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final startOfEarliest =
        DateTime(earliest.year, earliest.month, earliest.day);
    final startOfToday = DateTime(now.year, now.month, now.day);
    return startOfToday.difference(startOfEarliest).inDays;
  }

  Future<void> _saveInfo() async {
    final prefs = await _prefs;
    await prefs.setString(
      '${config.storageKey}.info',
      jsonEncode(_info!.toMap()),
    );
  }

  Future<void> _saveHistory() async {
    final prefs = await _prefs;
    await prefs.setString(
      '${config.storageKey}.history',
      jsonEncode(_history.map((h) => h.toMap()).toList()),
    );
  }
}
