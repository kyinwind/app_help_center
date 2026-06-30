import 'package:app_help_center/app_help_center.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_help_center example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AppHelpCenterPage(config: _config),
    );
  }
}

final _config = AppHelpCenterConfig(
  appName: 'Demo App',
  supportUrl: Uri.parse('https://example.com/support'),
  ratingUrl: Uri.parse('https://example.com/rate'),
  feedback: HelpFeedbackConfig(
    email: 'feedback@example.com',
    webFormUrl: Uri.parse('https://example.com/feedback'),
    submitHandler: (payload) async {
      debugPrint(payload.combinedContent);
    },
  ),
  reviewPrompt: ReviewPromptConfig(
    appName: 'Demo App',
    defaultClickThreshold: 5,
    defaultDaysThreshold: 3,
    onReview: () {
      debugPrint('Open your store listing or in-app review flow here.');
    },
  ),
  remoteVersionSupplementUrl:
      Uri.parse('https://example.com/version-supplements.json'),
  announcements: [
    HelpAnnouncement(
      id: 'welcome-help-center',
      title: 'Welcome to the help center',
      message:
          'Use this area for product announcements, support notices, and user communication.',
      publishedAt: DateTime(2026, 6, 3),
      level: HelpAnnouncementLevel.info,
      linkTitle: 'View project',
      linkUrl: Uri.parse('https://github.com/kyinwind/app_help_center'),
      isPinned: true,
    ),
    HelpAnnouncement(
      id: 'scheduled-maintenance',
      title: 'Support maintenance notice',
      message:
          'The support page may be briefly unavailable during maintenance. Email feedback remains available.',
      publishedAt: DateTime(2026, 6),
      level: HelpAnnouncementLevel.warning,
      expiresAt: DateTime(2026, 7),
    ),
  ],
  versionHistory: [
    VersionHistoryItem(
      versionName: 'v1.1.0',
      publishedAt: DateTime(2026, 6, 6),
      changes:
          '1. Added remote announcements\n2. Improved help center layout\n3. Fixed several experience issues',
      videoTitle: 'Release walkthrough',
      videoLinks: [
        HelpVideoLink(title: 'YouTube', url: Uri.parse('https://youtube.com')),
        HelpVideoLink(
          title: 'Bilibili',
          url: Uri.parse('https://bilibili.com'),
        ),
      ],
    ),
    VersionHistoryItem(
      versionName: 'v1.0.0',
      publishedAt: DateTime(2026, 5, 20),
      changes:
          'Initial release with help center, FAQ, quick links, and rating entry points.',
    ),
  ],
  quickLinks: [
    HelpQuickLink.url(
      title: 'User guide',
      subtitle: 'Read the online documentation',
      icon: Icons.menu_book_outlined,
      url: Uri.parse('https://example.com/guide'),
    ),
  ],
  faqItems: [
    const HelpFaqItem(
      question: 'How do I get started?',
      answer:
          'Import app_help_center, create an AppHelpCenterConfig, then show AppHelpCenterPage.',
    ),
    const HelpFaqItem(
      question: 'Which remote announcement format is supported?',
      answer:
          'Use a SwiftHelpCenter-style JSON array or wrap the array in an announcements field.',
    ),
  ],
);
