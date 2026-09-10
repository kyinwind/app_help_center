import 'dart:convert';
import 'dart:async';

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

  test('parses remote FAQ JSON formats', () {
    final arrayItems = FaqService.parseFaqItems(jsonDecode('''
[
  {"id":"contact","question":"How do I contact support?","answer":"Use support."}
]
'''));
    final wrappedItems = FaqService.parseFaqItems(jsonDecode('''
{
  "faqItems": [
    {"id":"billing","question":"How does billing work?","answer":"Monthly."}
  ]
}
'''));

    expect(arrayItems.single.id, 'contact');
    expect(wrappedItems.single.question, 'How does billing work?');
  });

  test('remote FAQ items merge with local items', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        remoteFaqUrl: Uri.parse('https://example.com/faq.json'),
        faqItems: [
          const HelpFaqItem(
            id: 'contact',
            question: 'Old contact question',
            answer: 'Old answer',
          ),
          const HelpFaqItem(
            id: 'local',
            question: 'Local only',
            answer: 'Keep me',
          ),
        ],
      ),
      faqService: const _FakeFaqService([
        HelpFaqItem(
          id: 'contact',
          question: 'New contact question',
          answer: 'New answer',
        ),
        HelpFaqItem(
          id: 'remote',
          question: 'Remote only',
          answer: 'Add me',
        ),
      ]),
    );

    await controller.load();

    expect(controller.faqItems.map((item) => item.id), [
      'contact',
      'local',
      'remote',
    ]);
    expect(controller.faqItems.first.question, 'New contact question');
  });

  test('remote FAQ failures keep local FAQ items without load error', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        remoteFaqUrl: Uri.parse('https://example.com/faq.json'),
        faqItems: [
          const HelpFaqItem(
            id: 'local',
            question: 'Local question',
            answer: 'Local answer',
          ),
        ],
      ),
      faqService: const _FailingFaqService(),
    );

    await controller.load();

    expect(controller.lastError, isNull);
    expect(controller.faqItems.single.id, 'local');
  });
  test('parses SwiftHelpCenter compatible training video JSON', () {
    final items = TrainingVideoService.parseTrainingVideos(jsonDecode('''
[
  {"id":"start","title":"Getting started","url":"https://example.com/start"},
  {"id":"bad","title":"Bad URL","url":"file:///tmp/video.mov"},
  {"title":"Missing id","url":"https://example.com/missing"}
]
'''));
    expect(items, hasLength(1));
    expect(items.single.id, 'start');
  });

  test('remote training videos override by id and append in stable order',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/training-videos.json'),
          items: [
            TrainingVideo(
              id: 'start',
              title: 'Local title',
              url: Uri.parse('https://example.com/local'),
            ),
            TrainingVideo(
              id: 'local',
              title: 'Local only',
              url: Uri.parse('https://example.com/local-only'),
            ),
          ],
        ),
      ),
      trainingVideoService: _FakeTrainingVideoService([
        TrainingVideo(
          id: 'start',
          title: 'Remote title',
          url: Uri.parse('https://example.com/remote'),
        ),
        TrainingVideo(
          id: 'remote',
          title: 'Remote only',
          url: Uri.parse('https://example.com/remote-only'),
        ),
      ]),
    );
    await controller.load();
    expect(controller.trainingVideos.map((item) => item.id),
        ['start', 'local', 'remote']);
    expect(controller.trainingVideos.first.title, 'Remote title');
  });

  test('successful empty training snapshot removes remote-only videos',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = _SequenceTrainingVideoService([
      [
        TrainingVideo(
          id: 'remote',
          title: 'Remote',
          url: Uri.parse('https://example.com/remote'),
        ),
      ],
      const [],
    ]);
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/videos.json'),
        ),
      ),
      trainingVideoService: service,
    );

    await controller.fetchRemoteTrainingVideos();
    expect(controller.trainingVideos, hasLength(1));
    await controller.fetchRemoteTrainingVideos();
    expect(controller.trainingVideos, isEmpty);
  });

  test('failed training refresh retains snapshot and exposes source error',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = _SequenceTrainingVideoService([
      [
        TrainingVideo(
          id: 'remote',
          title: 'Remote',
          url: Uri.parse('https://example.com/remote'),
        ),
      ],
      StateError('offline'),
      const [],
    ]);
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/videos.json'),
        ),
      ),
      trainingVideoService: service,
    );

    await controller.fetchRemoteTrainingVideos();
    await controller.fetchRemoteTrainingVideos();
    expect(controller.trainingVideos, hasLength(1));
    expect(controller.remoteErrors, contains('trainingVideos'));
    await controller.fetchRemoteTrainingVideos();
    expect(controller.trainingVideos, isEmpty);
    expect(controller.remoteErrors, isNot(contains('trainingVideos')));
  });

  test('latest training request wins and loading state follows its generation',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = _DeferredTrainingVideoService();
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/videos.json'),
        ),
      ),
      trainingVideoService: service,
    );

    final first = controller.fetchRemoteTrainingVideos();
    final second = controller.fetchRemoteTrainingVideos();
    expect(controller.isLoadingRemoteTrainingVideos, isTrue);
    service.requests[1].complete([
      TrainingVideo(
        id: 'new',
        title: 'New',
        url: Uri.parse('https://example.com/new'),
      ),
    ]);
    await second;
    expect(controller.isLoadingRemoteTrainingVideos, isFalse);
    service.requests[0].complete([
      TrainingVideo(
        id: 'old',
        title: 'Old',
        url: Uri.parse('https://example.com/old'),
      ),
    ]);
    await first;
    expect(controller.trainingVideos.single.id, 'new');
  });

  test('if-needed load fetches training videos only once', () async {
    SharedPreferences.setMockInitialValues({});
    final service = _CountingTrainingVideoService();
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/videos.json'),
        ),
      ),
      trainingVideoService: service,
    );
    await controller.load();
    await controller.load();
    expect(service.fetchCount, 1);
    await controller.load(forceRemoteRefresh: true);
    expect(service.fetchCount, 2);
  });

  testWidgets('shows training videos and expands overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final videos = List.generate(
      6,
      (index) => TrainingVideo(
        id: 'video-$index',
        title: 'Training video number $index',
        url: Uri.parse('https://example.com/video-$index'),
      ),
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: AppHelpCenterPage(
        config: AppHelpCenterConfig(
          appName: 'Demo',
          trainingVideos: TrainingVideoConfig(items: videos),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Training Videos'), findsOneWidget);
    expect(find.text('View all (6)'), findsOneWidget);
    expect(find.text('Training video number 5'), findsNothing);
    await tester.tap(find.text('View all (6)'));
    await tester.pumpAndSettle();
    expect(find.text('Training video number 5'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('quick links appear before training videos', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: AppHelpCenterPage(
        config: AppHelpCenterConfig(
          appName: 'Demo',
          quickLinks: [
            HelpQuickLink.url(
              title: 'Guide',
              icon: Icons.book,
              url: Uri.parse('https://example.com/guide'),
            ),
          ],
          trainingVideos: TrainingVideoConfig(items: [
            TrainingVideo(
              id: 'start',
              title: 'Start',
              url: Uri.parse('https://example.com/start'),
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Quick Links')).dy,
      lessThan(tester.getTopLeft(find.text('Training Videos')).dy),
    );
  });

  testWidgets('standard help-center button opens the page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
        body: AppHelpCenterButton(
          config: AppHelpCenterConfig(appName: 'Demo'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Help Center'));
    await tester.pumpAndSettle();
    expect(find.byType(AppHelpCenterPage), findsOneWidget);
    expect(find.text('No version history yet'), findsOneWidget);
  });

  test('remote sources start in parallel and expose independent loading state',
      () async {
    SharedPreferences.setMockInitialValues({});
    final gate = Completer<void>();
    final announcements = _GatedAnnouncementService(gate.future);
    final versions = _GatedVersionSupplementService(gate.future);
    final faqs = _GatedFaqService(gate.future);
    final videos = _GatedTrainingVideoService(gate.future);
    final controller = AppHelpCenterController(
      config: AppHelpCenterConfig(
        appName: 'Demo',
        remoteAnnouncementsUrl: Uri.parse('https://example.com/a.json'),
        remoteVersionSupplementUrl: Uri.parse('https://example.com/v.json'),
        remoteFaqUrl: Uri.parse('https://example.com/f.json'),
        trainingVideos: TrainingVideoConfig(
          remoteUrl: Uri.parse('https://example.com/t.json'),
        ),
      ),
      announcementService: announcements,
      versionSupplementService: versions,
      faqService: faqs,
      trainingVideoService: videos,
    );

    final loading = controller.load();
    while (!videos.called) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(announcements.called, isTrue);
    expect(versions.called, isTrue);
    expect(faqs.called, isTrue);
    expect(controller.isLoadingRemoteAnnouncements, isTrue);
    expect(controller.isLoadingVersionSupplements, isTrue);
    expect(controller.isLoadingRemoteFaqItems, isTrue);
    expect(controller.isLoadingRemoteTrainingVideos, isTrue);
    gate.complete();
    await loading;
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

class _FakeFaqService extends FaqService {
  const _FakeFaqService(this.items);

  final List<HelpFaqItem> items;

  @override
  Future<List<HelpFaqItem>> fetch(AppHelpCenterConfig config) async {
    return items;
  }
}

class _FailingFaqService extends FaqService {
  const _FailingFaqService();

  @override
  Future<List<HelpFaqItem>> fetch(AppHelpCenterConfig config) async {
    throw StateError('offline');
  }
}

class _FakeTrainingVideoService extends TrainingVideoService {
  const _FakeTrainingVideoService(this.items);

  final List<TrainingVideo> items;

  @override
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) async => items;
}

class _SequenceTrainingVideoService extends TrainingVideoService {
  _SequenceTrainingVideoService(this.results);

  final List<Object> results;
  var index = 0;

  @override
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) async {
    final result = results[index++];
    if (result is Error) throw result;
    return (result as List).cast<TrainingVideo>();
  }
}

class _DeferredTrainingVideoService extends TrainingVideoService {
  final requests = <Completer<List<TrainingVideo>>>[];

  @override
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) {
    final completer = Completer<List<TrainingVideo>>();
    requests.add(completer);
    return completer.future;
  }
}

class _CountingTrainingVideoService extends TrainingVideoService {
  var fetchCount = 0;

  @override
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) async {
    fetchCount++;
    return const [];
  }
}

class _GatedAnnouncementService extends AnnouncementService {
  _GatedAnnouncementService(this.gate);
  final Future<void> gate;
  var called = false;

  @override
  Future<List<HelpAnnouncement>> fetch(AppHelpCenterConfig config) async {
    called = true;
    await gate;
    return const [];
  }
}

class _GatedVersionSupplementService extends VersionSupplementService {
  _GatedVersionSupplementService(this.gate);
  final Future<void> gate;
  var called = false;

  @override
  Future<List<VersionHistorySupplement>> fetch(
      AppHelpCenterConfig config) async {
    called = true;
    await gate;
    return const [];
  }
}

class _GatedFaqService extends FaqService {
  _GatedFaqService(this.gate);
  final Future<void> gate;
  var called = false;

  @override
  Future<List<HelpFaqItem>> fetch(AppHelpCenterConfig config) async {
    called = true;
    await gate;
    return const [];
  }
}

class _GatedTrainingVideoService extends TrainingVideoService {
  _GatedTrainingVideoService(this.gate);
  final Future<void> gate;
  var called = false;

  @override
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) async {
    called = true;
    await gate;
    return const [];
  }
}
