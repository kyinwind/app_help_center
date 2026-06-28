import 'dart:convert';

import 'package:app_help_center/app_help_center.dart';
import 'package:app_help_center/src/services/announcement_service.dart';
import 'package:app_help_center/src/services/feedback_service.dart';
import 'package:app_help_center/src/services/version_supplement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parses SwiftHelpCenter compatible announcement JSON', () {
    const jsonText = '''
[
  {
    "id": "welcome-help-center",
    "title": "Welcome to the help center",
    "message": "Product announcements appear here.",
    "publishedAt": "2026-06-03",
    "level": "warning",
    "linkTitle": "View project",
    "linkURL": "https://example.com",
    "isPinned": true,
    "expiresAt": "2026-06-09"
  }
]
''';

    final items = AnnouncementService.parseAnnouncements(jsonDecode(jsonText));

    expect(items, hasLength(1));
    expect(items.first.id, 'welcome-help-center');
    expect(items.first.level, HelpAnnouncementLevel.warning);
    expect(items.first.isPinned, isTrue);
    expect(items.first.linkUrl, Uri.parse('https://example.com'));
  });

  test('sorts pinned announcements before newer announcements', () {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        announcements: [
          HelpAnnouncement(
            id: 'newer',
            title: 'Newer',
            message: 'Newer',
            publishedAt: DateTime(2026, 6, 2),
          ),
          HelpAnnouncement(
            id: 'pinned',
            title: 'Pinned',
            message: 'Pinned',
            publishedAt: DateTime(2026, 6),
            isPinned: true,
          ),
        ],
      ),
    );

    expect(
        controller.announcements.map((item) => item.id), ['pinned', 'newer']);
  });

  test('filters expired announcements', () {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        announcements: [
          HelpAnnouncement(
            id: 'expired',
            title: 'Expired',
            message: 'Expired',
            publishedAt: DateTime(2026),
            expiresAt: DateTime(2026),
          ),
          HelpAnnouncement(
            id: 'active',
            title: 'Active',
            message: 'Active',
            publishedAt: DateTime(2026),
          ),
        ],
      ),
    );

    expect(controller.announcements.map((item) => item.id), ['active']);
  });

  test('marks all content as read and resets read state', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        markExistingVersionsAsReadOnFirstLoad: false,
        announcements: [
          HelpAnnouncement(
            id: 'notice',
            title: 'Notice',
            message: 'Notice',
            publishedAt: DateTime(2026),
          ),
        ],
        versionHistory: [
          VersionHistoryItem(
            versionName: '1.0.0',
            publishedAt: DateTime(2026),
            changes: 'Initial release',
          ),
        ],
      ),
    );

    await controller.load(refreshRemote: false);
    expect(controller.hasUnreadContent, isTrue);

    await controller.markAllAsRead();
    expect(controller.hasUnreadContent, isFalse);

    await controller.resetReadState();
    expect(controller.hasUnreadContent, isTrue);
  });

  test('shows feedback quick link only when feedback is configured', () {
    SharedPreferences.setMockInitialValues({});

    final withoutFeedback = AppHelpCenterController(
      config: const AppHelpCenterConfig(appName: 'Demo'),
    );
    expect(
      withoutFeedback.quickLinks
          .where((link) => link.actionType == HelpQuickLinkActionType.feedback),
      isEmpty,
    );

    final withFeedback = AppHelpCenterController(
      config: const AppHelpCenterConfig(
        appName: 'Demo',
        feedback: HelpFeedbackConfig(email: 'feedback@example.com'),
      ),
    );
    expect(
      withFeedback.quickLinks
          .where((link) => link.actionType == HelpQuickLinkActionType.feedback),
      hasLength(1),
    );
  });

  test('custom feedback handler receives payload', () async {
    HelpFeedbackPayload? received;
    final config = HelpFeedbackConfig(
      submitHandler: (payload) async {
        received = payload;
      },
    );

    await const FeedbackService().submit(
      config: config,
      payload: const HelpFeedbackPayload(
        content: 'Something went wrong',
        channels: [HelpFeedbackChannel.custom],
      ),
    );

    expect(received?.content, 'Something went wrong');
  });

  test('parses SwiftHelpCenter compatible version supplement JSON', () {
    const jsonText = '''
[
  {
    "id": "1.8.2",
    "videoTitle": "v1.8.2 walkthrough",
    "videoLinks": [
      {
        "title": "bilibili",
        "url": "https://www.bilibili.com/video/xxx"
      }
    ]
  }
]
''';

    final supplements =
        VersionSupplementService.parseSupplements(jsonDecode(jsonText));

    expect(supplements, hasLength(1));
    expect(supplements.first.id, '1.8.2');
    expect(supplements.first.videoTitle, 'v1.8.2 walkthrough');
    expect(supplements.first.videoLinks?.first.title, 'bilibili');
  });

  test('merges remote version supplements by normalized version name',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        remoteVersionSupplementUrl:
            Uri.parse('https://example.com/videos.json'),
        versionHistory: [
          VersionHistoryItem(
            versionName: 'v1.8.2',
            publishedAt: DateTime(2026),
            changes: 'Release notes',
          ),
        ],
      ),
      versionSupplementService: _FakeVersionSupplementService([
        VersionHistorySupplement(
          id: '1.8.2',
          videoTitle: 'Walkthrough',
          videoLinks: [
            HelpVideoLink(
              title: 'Release article',
              url: Uri.parse('https://example.com/releases/1.8.2'),
            ),
          ],
        ),
      ]),
    );

    await controller.load();

    expect(controller.versionHistory.first.videoTitle, 'Walkthrough');
    expect(controller.versionHistory.first.videoLinks, hasLength(1));
  });
  testWidgets('shows announcement published date', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final config = AppHelpCenterConfig(
      appName: 'Demo',
      announcements: [
        HelpAnnouncement(
          id: 'maintenance',
          title: 'Maintenance',
          message: 'Short maintenance window.',
          publishedAt: DateTime(2026, 6, 3),
        ),
      ],
    );

    await tester
        .pumpWidget(MaterialApp(home: AppHelpCenterPage(config: config)));
    await tester.pumpAndSettle();

    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Jun 3, 2026'), findsOneWidget);
  });
  testWidgets('shows all versions by default when latest-only mode is disabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final config = AppHelpCenterConfig(
      appName: 'Demo',
      showOnlyLatestVersionByDefault: false,
      versionHistory: [
        VersionHistoryItem(
          versionName: 'v2.0.0',
          publishedAt: DateTime(2026, 6, 2),
          changes: 'Second release',
        ),
        VersionHistoryItem(
          versionName: 'v1.0.0',
          publishedAt: DateTime(2026, 6),
          changes: 'Initial release',
        ),
      ],
    );

    await tester
        .pumpWidget(MaterialApp(home: AppHelpCenterPage(config: config)));
    await tester.pumpAndSettle();

    expect(find.text('v2.0.0'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  test('support actions record review prompt activity', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: const AppHelpCenterConfig(
        appName: 'Demo',
        reviewPrompt: ReviewPromptConfig(
          appName: 'Demo',
          defaultClickThreshold: 0,
          defaultDaysThreshold: 0,
        ),
      ),
    );

    await controller.openSupport();

    expect(controller.reviewPromptManager?.shouldShowPrompt, isTrue);
  });
}

class _FakeVersionSupplementService extends VersionSupplementService {
  const _FakeVersionSupplementService(this.supplements);

  final List<VersionHistorySupplement> supplements;

  @override
  Future<List<VersionHistorySupplement>> fetch(
      AppHelpCenterConfig config) async {
    return supplements;
  }
}
