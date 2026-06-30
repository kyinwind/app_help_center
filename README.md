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
- FAQ disclosure list with optional remote JSON loading.
- Built-in feedback form with email, web form, webhook, custom submit channels, screenshot upload, and character-count display.
- Discord webhook support with multipart image upload.
- Review prompt manager with dual click/day thresholds, four-button dialog, and persistent silent state.
- Quick links for URLs, feedback, rating, and support.
- Built-in Chinese and English copy for generic help center UI.
- Advanced caller copy overrides for product-specific wording tweaks.
- Light and dark theme support through Flutter `ThemeData`.

## Install

```yaml
dependencies:
  app_help_center: ^0.2.6
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
    dingTalkContentBuilder: (payload) => payload.combinedContent,
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
  remoteFaqUrl: Uri.parse('https://example.com/faq.json'),
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
    dingTalkContentBuilder: (payload) => payload.combinedContent,
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

### DingTalk Message Content

DingTalk robots may require every incoming message to contain a configured
security keyword. Keep that keyword in your app layer instead of hard-coding it
inside the package. Use `dingTalkContentBuilder` to customize only the DingTalk
message body:

```dart
HelpFeedbackConfig(
  dingTalkWebhookUrl: Uri.parse('https://oapi.dingtalk.com/robot/send?...'),
  dingTalkContentBuilder: (payload) => 'feedback\n${payload.combinedContent}',
);
```

If `dingTalkContentBuilder` is omitted, DingTalk receives
`payload.combinedContent` unchanged.

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


## Remote FAQ Items

Use `faqItems` for bundled FAQ content and `remoteFaqUrl` for optional remote
updates after the app ships. Remote loading is best-effort: when the device is
offline, the server is unavailable, or the JSON cannot be parsed, the help
center keeps showing the local FAQ items and does not surface an error.

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  faqItems: [
    HelpFaqItem(
      id: 'contact',
      question: 'How do I contact support?',
      answer: 'Use the support link in the help center.',
    ),
  ],
  remoteFaqUrl: Uri.parse('https://example.com/faq.json'),
);
```

The default parser accepts either a JSON array:

```json
[
  {
    "id": "contact",
    "question": "How do I contact support?",
    "answer": "Use the support link in the help center."
  }
]
```

Or an object with a `faqItems`, `faq`, or `items` array:

```json
{
  "faqItems": [
    {
      "id": "contact",
      "question": "How do I contact support?",
      "answer": "Use the support link in the help center."
    }
  ]
}
```

Each item supports `id`, `question`, and `answer`. The parser also accepts
`title` as an alias for `question`, and `content` as an alias for `answer`.
When `id` is omitted, the question text is used as the identifier.

Remote FAQ items are merged with local FAQ items by `id`: a remote item with the
same `id` replaces the local item, while new remote items are appended after the
local list. This lets you ship reliable fallback content and update selected
answers remotely.

Use `remoteFaqParser` when your endpoint has a custom schema:

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  remoteFaqUrl: Uri.parse('https://example.com/help-center-faq.json'),
  remoteFaqParser: (decodedJson) {
    final items = decodedJson as List<dynamic>;
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return HelpFaqItem(
        id: map['slug'] as String?,
        question: map['q'] as String? ?? '',
        answer: map['a'] as String? ?? '',
      );
    }).toList();
  },
);
```

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

## Internationalization and API Responsibilities

`app_help_center` has built-in English and Chinese copy for the generic help
center UI. The plugin chooses copy from `AppHelpCenterConfig.locale`; if `locale`
is omitted, it falls back to `Localizations.localeOf(context)`.

```dart
AppHelpCenterPage(
  config: AppHelpCenterConfig(
    appName: 'Demo App',
    locale: Localizations.localeOf(context),
    announcements: [...],
    versionHistory: [...],
    faqItems: [...],
    supportUrl: Uri.parse('https://example.com/support'),
    feedback: HelpFeedbackConfig(email: 'feedback@example.com'),
  ),
);
```

### What the plugin owns

The plugin owns and localizes generic help-center UI copy, including:

- Page title and subtitle.
- Section names: announcements, quick links, version history, FAQ.
- Badges, counters, empty states, loading states, and expand/collapse actions.
- Built-in quick link labels for feedback, rating, and support.
- Feedback form labels, hints, validation, success/failure messages, screenshots,
  and character-count copy.
- Review prompt copy.

Host apps normally should not duplicate these strings in their own app-level
localization files.

### What the host app owns

The host app owns product-specific content and behavior, including:

- `appName`.
- Local or remote announcements.
- Version history records and remote version supplement URLs.
- FAQ question/answer content.
- Custom quick links.
- Support/rating URLs or callbacks.
- Feedback submission channels and webhook content builders.
- App-specific storage keys.
- Review prompt thresholds and callbacks.

These strings belong to the host app because they describe the host product, not
the generic help center component.

### Copy overrides

`copyOverrides` remains available as an advanced escape hatch:

```dart
AppHelpCenterConfig(
  appName: 'Demo App',
  locale: Localizations.localeOf(context),
  copyOverrides: {
    'feedback': 'Contact Us',
  },
);
```

Use `copyOverrides` only to adjust a few built-in plugin labels. Do not use it
as a full translation table. If the generic built-in wording is wrong or missing
for a locale, fix it in `AppHelpCenterLocalizations` so every host app benefits.

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
