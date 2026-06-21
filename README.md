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
- Built-in feedback form with email, web form, webhook, and custom submit channels.
- Quick links for URLs, feedback, rating, and support.
- Built-in Chinese and English copy.
- Caller copy overrides.
- Light and dark theme support through Flutter `ThemeData`.

## Install

```yaml
dependencies:
  app_help_center: ^0.2.1
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
- Discord webhook.
- DingTalk webhook.
- Custom submit handler.

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
- `0.2.x`: Feedback page, mail/webhook/custom submit handlers, system info.
- `0.3.x`: Review prompt manager with click/day thresholds.
- Later: more layout polish, screenshots, changelog parsing, and optional
  advanced integrations.

## Relationship to SwiftHelpCenter

SwiftHelpCenter is a Swift Package for macOS and iOS apps. `app_help_center`
rebuilds the same product idea for Flutter apps without binding to SwiftUI,
AppKit, or UIKit.

## License

MIT
