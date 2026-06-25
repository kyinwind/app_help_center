# app_help_center

A lightweight Help Center and user communication kit for Flutter apps.

`app_help_center` helps Flutter apps present announcements, version history, FAQ,
quick links, support links, feedback entry points, and rating links in one place.
It is inspired by the product experience of SwiftHelpCenter, but rebuilt with
pure Flutter/Dart UI and models.

## Features

- Help center page for Android, iOS, macOS, and Windows.
- Local and remote announcements.
- SwiftHelpCenter-compatible announcement JSON.
- Announcement unread state, pinned items, levels, details link, and expiration.
- Version history with latest-only default view and expand-all behavior.
- Video links for version history items.
- FAQ disclosure list.
- Built-in feedback form with email, web form, webhook, custom submit channels, screenshot upload, and character-count display.
- Discord webhook support with multipart image upload.
- Review prompt manager with dual click/day thresholds, four-button dialog, and persistent silent state.
- Quick links for URLs, feedback, rating, and support.
- Built-in Chinese and English copy.
- Caller copy overrides.
- Light and dark theme support through Flutter `ThemeData`.

## Install

```yaml
dependencies:
  app_help_center: ^0.2.2
```

## Basic Usage

```dart
import 'package:app_help_center/app_help_center.dart';
import 'package:flutter/material.dart';

final config = AppHelpCenterConfig(
  appName: 'Demo App',
  supportUrl: Uri.parse('https://example.com/support'),
  ratingUrl: Uri.parse('https://example.com/rate'),
  feedback: HelpFeedbackConfig(
    email: 'feedback@example.com',
    webFormUrl: Uri.parse('https://example.com/feedback'),
    discordWebhookUrl: Uri.parse('https://discord.com/api/webhooks/...'),
    dingTalkWebhookUrl:
        Uri.parse('https://oapi.dingtalk.com/robot/send?access_token=...'),
    allowScreenshots: true,
    submitHandler: (payload) async {
      // Send to your own backend.
    },
  ),
  announcements: [
    HelpAnnouncement(
      id: 'welcome',
      title: 'Welcome',
      message: 'Thanks for trying the help center.',
      publishedAt: DateTime(2026, 6, 6),
      level: HelpAnnouncementLevel.info,
      isPinned: true,
    ),
  ],
  versionHistory: [
    VersionHistoryItem(
      versionName: 'v1.0.0',
      publishedAt: DateTime(2026, 6, 6),
      changes: 'Initial release.',
    ),
  ],
  remoteVersionSupplementUrl: Uri.parse(
    'https://example.com/version-supplements.json',
  ),
  faqItems: [
    HelpFaqItem(
      question: 'How do I get started?',
      answer: 'Create AppHelpCenterConfig and show AppHelpCenterPage.',
    ),
  ],
);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppHelpCenterPage(config: config);
  }
}
```

## Help Center Button with Unread Badge

Use `AppHelpCenterController` to drive a help center button. The controller is
a `ChangeNotifier`; listen to it to show a badge when there are unread
announcements or new version entries.

```dart
class _MyAppState extends State<MyApp> {
  late final _helpController = AppHelpCenterController(config: _helpConfig);

  @override
  void initState() {
    super.initState();
    _helpController.load();
  }

  @override
  void dispose() {
    _helpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          HelpCenterButton(controller: _helpController),
        ],
      ),
    );
  }
}

class HelpCenterButton extends StatefulWidget {
  final AppHelpCenterController controller;

  const HelpCenterButton({super.key, required this.controller});

  @override
  State<HelpCenterButton> createState() => _HelpCenterButtonState();
}

class _HelpCenterButtonState extends State<HelpCenterButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: widget.controller.hasUnreadContent,
      child: IconButton(
        icon: const Icon(Icons.help_outline),
        tooltip: 'Help Center',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppHelpCenterPage(
                config: widget.controller.config,
                controller: widget.controller,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

Key points:

- **`controller.addListener` + `setState`** keeps the badge in sync. The
  controller notifies listeners whenever unread state changes.
- **`controller.hasUnreadContent`** returns `true` when there are unread
  announcements or unseen version history entries. Use `hasUnreadAnnouncements`
  and `hasUnreadVersions` to query individually.
- **Pass the same controller** to `AppHelpCenterPage` so the page can mark
  items as read while the badge stays in sync.
- **Call `controller.load()`** once at startup to pull remote data and restore
  read state from disk.

## Remote Announcements

Remote announcements may be a JSON array:

```json
[
  {
    "id": "scheduled-maintenance-2026-06",
    "title": "Maintenance Notice",
    "message": "Support will be briefly unavailable during maintenance.",
    "publishedAt": "2026-06-01",
    "level": "warning",
    "linkTitle": "Learn More",
    "linkURL": "https://example.com/support/maintenance",
    "isPinned": false,
    "expiresAt": "2026-06-09"
  }
]
```

Or wrapped in an `announcements` field:

```json
{
  "announcements": []
}
```

Configure it with:

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  remoteAnnouncementsUrl: Uri.parse(
    'https://raw.githubusercontent.com/your/repo/main/announcements.json',
  ),
);
```

## Feedback

Feedback is configured through `AppHelpCenterConfig`. There is no separate
global feedback manager.

If `feedback` is omitted, the help center does not show a feedback entry. If
`feedback` is configured, the help center automatically shows an internal
feedback form.

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  feedback: HelpFeedbackConfig(
    email: 'feedback@example.com',
    webFormUrl: Uri.parse('https://example.com/feedback'),
    discordWebhookUrl: Uri.parse('https://discord.com/api/webhooks/...'),
    dingTalkWebhookUrl: Uri.parse('https://oapi.dingtalk.com/robot/send?...'),
    submitHandler: (payload) async {
      await myApi.sendFeedback(payload.content);
    },
    includeSystemInfo: true,
  ),
);
```

Available channels:

- Email through `mailto:`.
- Web form URL.
- Discord webhook (with multipart image upload support).
- DingTalk webhook.
- Custom submit handler.

### Screenshots

The feedback page includes a screenshot picker when `discordWebhookUrl` is
configured. Tap the add button to pick images from your device gallery. Up to
5 screenshots can be attached per submission.

```dart
HelpFeedbackConfig(
  discordWebhookUrl: Uri.parse('https://discord.com/api/webhooks/...'),
  allowScreenshots: true,   // default: true when channel supports it
  maxScreenshots: 5,        // default: 5
);
```

### Character Count

The feedback text field shows a live character count (up to 1700 characters),
mirroring the behavior of SwiftHelpCenter.

## Review Prompt

The review prompt manager shows a native-feeling dialog after users have
interacted with the app enough times over enough days. Both thresholds must
be met before the dialog appears.

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  reviewPrompt: ReviewPromptConfig(
    appName: 'Demo App',
    defaultClickThreshold: 5,
    defaultDaysThreshold: 3,
    onOpenSettings: () {
      // Navigate to your app's settings page.
    },
    onReview: () {
      // Open your store listing, in-app review flow, or rating page.
    },
  ),
);
```

The dialog has four buttons:

| Button | Behavior |
|--------|----------|
| **Rate Now** | Calls `onReview` so you can open your store listing, in-app review flow, or rating page. |
| **Later** | Postpones the prompt by raising both thresholds (+30 clicks, +3 days). |
| **Settings** | Calls the `onOpenSettings` callback so you can open your app's settings. |
| **Never** | Silences the prompt permanently. |

Call `controller.checkReviewPrompt(actType)` from any action point in your
app to record a click. The help center page automatically records clicks for
quick links, feedback, and support actions.

## Remote Version Supplements

Version history should remain configured locally so users can always see release
notes. Remote version supplements are optional JSON files for adding or updating
video/article links after an app has already shipped.

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  versionHistory: [
    VersionHistoryItem(
      versionName: 'v1.8.2',
      publishedAt: DateTime(2026, 6, 6),
      changes: 'Release notes.',
    ),
  ],
  remoteVersionSupplementUrl: Uri.parse(
    'https://example.com/version-supplements.json',
  ),
);
```

The JSON format is compatible with SwiftHelpCenter:

```json
[
  {
    "id": "1.8.2",
    "videoTitle": "v1.8.2 walkthrough",
    "videoLinks": [
      {
        "title": "Bilibili",
        "url": "https://www.bilibili.com/video/xxx"
      },
      {
        "title": "Release article",
        "url": "https://example.com/releases/1.8.2"
      }
    ]
  }
]
```

`id` can match the local version item `id`, `versionName`, or a normalized
version name without the leading `v`.

## Platform Notes

The core help center UI, models, remote announcements, unread state, and
localization are implemented in Flutter/Dart and are designed for Android, iOS,
macOS, and Windows.

Platform-specific actions such as opening store pages, mail clients, support
pages, and video links depend on the host platform and the configured URLs.
The first version keeps this URL-first and lightweight. More advanced callbacks
and custom platform integrations are planned for later versions.

## Roadmap

- `0.1.x`: Help Center MVP.
- `0.2.x`: Feedback page, mail/webhook/custom submit handlers, system info, screenshots, review prompt manager with click/day thresholds.
- Later: more layout polish, changelog parsing, design system module, and optional advanced integrations.

## Relationship to SwiftHelpCenter

SwiftHelpCenter is a Swift Package for macOS and iOS apps. `app_help_center`
rebuilds the same product idea for Flutter apps without binding to SwiftUI,
AppKit, or UIKit. Key features including announcements, version history,
feedback, review prompt manager, and remote data fetching have been ported
to pure Dart/Flutter.

## License

MIT
