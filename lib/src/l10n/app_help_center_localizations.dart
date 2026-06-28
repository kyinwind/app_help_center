import 'package:flutter/widgets.dart';

/// Lightweight localization helper used by the built-in help center UI.
class AppHelpCenterLocalizations {
  /// Creates localized copy with optional per-key overrides.
  const AppHelpCenterLocalizations({
    required this.locale,
    this.overrides = const {},
  });

  /// Locale used to choose built-in copy and format dates.
  final Locale locale;

  /// Per-key text overrides applied before built-in strings.
  final Map<String, String> overrides;

  /// Creates localizations from a BuildContext.
  static AppHelpCenterLocalizations of(
    BuildContext context, {
    Locale? locale,
    Map<String, String> overrides = const {},
  }) {
    return AppHelpCenterLocalizations(
      locale: locale ?? Localizations.localeOf(context),
      overrides: overrides,
    );
  }

  /// Returns localized text for the key, falling back to English and then the key.
  String text(String key) {
    return overrides[key] ?? _localizedMap[key] ?? _english[key] ?? key;
  }

  /// Returns localized text with {value} replaced by value.
  String format(String key, Object value) {
    return text(key).replaceAll('{value}', value.toString());
  }

  Map<String, String> get _localizedMap {
    final languageCode = locale.languageCode.toLowerCase();
    if (languageCode == 'zh') {
      return _chinese;
    }
    return _english;
  }

  static const _english = {
    'title': 'Help Center',
    'subtitle': 'Announcements, product updates, FAQ, and support.',
    'announcements': 'Announcements',
    'quickLinks': 'Quick Links',
    'versionHistory': 'Version History',
    'faq': 'FAQ',
    'feedback': 'Send Feedback',
    'rating': 'Rate App',
    'support': 'Open Support',
    'markAllRead': 'Mark All Read',
    'new': 'New',
    'pinned': 'Pinned',
    'viewDetails': 'View Details',
    'viewAllAnnouncements': 'View All Announcements',
    'collapseAnnouncements': 'Collapse Announcements',
    'viewAllVersions': 'View All Versions',
    'collapseVersions': 'Collapse Version History',
    'noVersionHistory': 'No version history yet',
    'noVersionHistoryMessage': 'Configured version records will appear here.',
    'announcement.info': 'Info',
    'announcement.success': 'Done',
    'announcement.warning': 'Notice',
    'announcement.critical': 'Important',
    'announcementCount': '{value} total',
    'unreadAnnouncementCount': '{value} unread',
    'versionCount': '{value} versions',
    'unreadVersionCount': '{value} unread versions',
    'loading': 'Loading...',
    'feedbackTitle': 'Send Feedback',
    'feedbackContent': 'Feedback',
    'feedbackContentHint': 'Tell us what happened or what you expected.',
    'feedbackContact': 'Contact',
    'feedbackContactHint': 'Email or other contact info (optional)',
    'feedbackChannels': 'Channels',
    'feedbackIncludeSystemInfo': 'Include system info',
    'feedbackSubmit': 'Send',
    'feedbackSuccess': 'Feedback sent',
    'feedbackFailure': 'Failed to send feedback',
    'feedbackRequired': 'Please enter feedback.',
    'feedback.email': 'Email',
    'feedback.webForm': 'Web Form',
    'feedback.discordWebhook': 'Discord',
    'feedback.dingTalkWebhook': 'DingTalk',
    'feedback.custom': 'Custom',
    'feedbackFollowUp':
        'We read every piece of feedback and use it to improve the product.',
    'feedbackRate': 'Rate App',
    'feedbackTechSupport': 'Tech Support',
    'feedbackCharCount': '{value} / 1700',
    'screenshotAdd': 'Add screenshot',
    'screenshotMax': 'Max 5 screenshots',
    'reviewPrompt.title': 'Enjoying this app?',
    'reviewPrompt.request':
        'A quick rating on the App Store would help us a lot. Thanks for your support!',
    'reviewPrompt.never': 'Never prompt',
    'reviewPrompt.holdOn': 'Hold on',
    'reviewPrompt.settings': 'Go to settings',
    'reviewPrompt.review': 'Go to review',
  };

  static const _chinese = {
    'title': '帮助中心',
    'subtitle': '公告、版本更新、常见问题和技术支持。',
    'announcements': '公告',
    'quickLinks': '快速入口',
    'versionHistory': '版本历史',
    'faq': '常见问题',
    'feedback': '反馈问题',
    'rating': '给应用评分',
    'support': '打开技术支持',
    'markAllRead': '全部已读',
    'new': '新',
    'pinned': '置顶',
    'viewDetails': '查看详情',
    'viewAllAnnouncements': '查看全部公告',
    'collapseAnnouncements': '收起公告',
    'viewAllVersions': '查看全部版本',
    'collapseVersions': '收起版本历史',
    'noVersionHistory': '暂无版本历史',
    'noVersionHistoryMessage': '配置版本记录后会显示在这里。',
    'announcement.info': '公告',
    'announcement.success': '完成',
    'announcement.warning': '提醒',
    'announcement.critical': '重要',
    'announcementCount': '共 {value} 条',
    'unreadAnnouncementCount': '{value} 条未读',
    'versionCount': '共 {value} 个版本',
    'unreadVersionCount': '{value} 个版本未读',
    'loading': '加载中...',
    'feedbackTitle': '反馈问题',
    'feedbackContent': '反馈内容',
    'feedbackContentHint': '告诉我们遇到了什么问题，或你期待怎样改进。',
    'feedbackContact': '联系方式',
    'feedbackContactHint': '邮箱或其他联系方式（可选）',
    'feedbackChannels': '反馈渠道',
    'feedbackIncludeSystemInfo': '附带系统信息',
    'feedbackSubmit': '发送',
    'feedbackSuccess': '反馈已发送',
    'feedbackFailure': '反馈发送失败',
    'feedbackRequired': '请先填写反馈内容。',
    'feedback.email': '邮件',
    'feedback.webForm': '网页表单',
    'feedback.discordWebhook': 'Discord',
    'feedback.dingTalkWebhook': '钉钉',
    'feedback.custom': '自定义',
    'feedbackFollowUp': '我们会认真阅读每一条反馈，用来持续改进产品。',
    'feedbackRate': '给应用评分',
    'feedbackTechSupport': '技术支持',
    'feedbackCharCount': '{value} / 1700',
    'screenshotAdd': '添加截图',
    'screenshotMax': '最多 5 张截图',
    'reviewPrompt.title': '觉得这个应用不错？',
    'reviewPrompt.request': '在 App Store 给个评分对我们帮助很大，感谢你的支持！',
    'reviewPrompt.never': '不再提醒',
    'reviewPrompt.holdOn': '稍后再说',
    'reviewPrompt.settings': '去设置',
    'reviewPrompt.review': '去评价',
  };
}
