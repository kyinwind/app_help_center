# API Responsibilities

`app_help_center` owns the generic help-center experience. Host apps should pass product-specific content and configuration only.

## Plugin-owned copy

The plugin localizes and renders these generic UI labels internally through `AppHelpCenterLocalizations`:

- Page title and subtitle
- Section names: announcements, quick links, version history, FAQ
- Badges and counters: new, pinned, unread, total counts
- Empty and loading states
- Feedback form labels, hints, success/failure messages
- Built-in quick link labels for feedback, rating, and support
- Review prompt copy

Host apps normally should not pass `copyOverrides`.

## Host app-owned content

The host app should provide only product-specific data:

- `appName`
- `locale`
- Local or remote announcements
- Version history entries and remote supplement URLs
- FAQ question/answer content
- Custom quick links
- Support/rating URLs or callbacks
- Feedback submission channels
- App-specific storage keys
- Review prompt thresholds and callbacks

## Advanced overrides

`copyOverrides` is intentionally kept as an escape hatch. Use it only when the default plugin wording needs product-specific customization. Do not use it to provide a full translation table.

## Example

```dart
AppHelpCenterPage(
  config: AppHelpCenterConfig(
    appName: 'ExampleApp',
    locale: Localizations.localeOf(context),
    announcements: [...],
    versionHistory: [...],
    faqItems: [...],
    supportUrl: Uri.parse('https://example.com/support'),
    feedback: HelpFeedbackConfig(email: 'support@example.com'),
  ),
);
```
