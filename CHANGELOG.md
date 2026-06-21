## 0.2.1

- Relaxed the `intl` dependency constraint to support `>=0.19.0 <0.21.0`.
- Updated deprecated color opacity calls for newer Flutter SDKs.

## 0.2.0

- Added unified feedback configuration through `AppHelpCenterConfig.feedback`.
- Added built-in `HelpFeedbackPage`.
- Added email, web form, Discord webhook, DingTalk webhook, and custom submit channels.
- Added lightweight system information collection for feedback payloads.
- Updated the default feedback quick link to appear only when feedback is configured.
- Added remote version supplements for updating version history video/article links from JSON.

## 0.1.0

- Initial MVP release.
- Added help center page for announcements, version history, quick links, FAQ, support, feedback, and rating entry points.
- Added SwiftHelpCenter-compatible remote announcement JSON parsing.
- Added unread state storage with `shared_preferences`.
- Added URL-first external actions with `url_launcher`.
- Added built-in Chinese and English copy with caller overrides.
- Added example app, README, tests, and pub.dev metadata.
