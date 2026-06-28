import 'dart:typed_data';

/// Submission channel supported by the built-in feedback form.
enum HelpFeedbackChannel {
  /// Opens an email client with a prefilled message.
  email,

  /// Opens an external web form URL.
  webForm,

  /// Sends feedback to a Discord webhook.
  discordWebhook,

  /// Sends feedback to a DingTalk robot webhook.
  dingTalkWebhook,

  /// Calls the app-provided custom submit handler.
  custom,
}

/// Callback used to submit feedback to an app-owned destination.
typedef HelpFeedbackSubmitHandler = Future<void> Function(
  HelpFeedbackPayload payload,
);

/// Builds the DingTalk text message from a feedback payload.
typedef DingTalkContentBuilder = String Function(
  HelpFeedbackPayload payload,
);

/// Configuration for the built-in feedback form and its channels.
class HelpFeedbackConfig {
  /// Creates feedback configuration.
  const HelpFeedbackConfig({
    this.email,
    this.webFormUrl,
    this.discordWebhookUrl,
    this.dingTalkWebhookUrl,
    this.dingTalkContentBuilder,
    this.submitHandler,
    this.subject = 'App Feedback',
    this.includeSystemInfo = true,
    this.allowChannelSelection = true,
    this.allowScreenshots = true,
    this.maxScreenshots = 5,
  });

  /// Email address used by the email channel.
  final String? email;

  /// URL opened by the web form channel.
  final Uri? webFormUrl;

  /// Discord webhook URL used by the Discord channel.
  final Uri? discordWebhookUrl;

  /// DingTalk robot webhook URL used by the DingTalk channel.
  final Uri? dingTalkWebhookUrl;

  /// Optional builder for customizing DingTalk message text.
  final DingTalkContentBuilder? dingTalkContentBuilder;

  /// Optional callback used by the custom channel.
  final HelpFeedbackSubmitHandler? submitHandler;

  /// Email subject used by the email channel.
  final String subject;

  /// Whether the feedback form includes collected system information by default.
  final bool includeSystemInfo;

  /// Whether users can choose among multiple configured channels.
  final bool allowChannelSelection;

  /// Whether to show screenshot picker when Discord channel is selected.
  /// Mirrors SwiftHelpCenter's ScreenshotPickerView.
  final bool allowScreenshots;

  /// Maximum number of screenshots allowed.
  /// Default 5, matching SwiftHelpCenter.
  final int maxScreenshots;

  /// Whether at least one feedback channel is configured.
  bool get isConfigured => availableChannels.isNotEmpty;

  /// Channels available for this configuration.
  List<HelpFeedbackChannel> get availableChannels {
    return [
      if (email != null && email!.isNotEmpty) HelpFeedbackChannel.email,
      if (webFormUrl != null) HelpFeedbackChannel.webForm,
      if (discordWebhookUrl != null) HelpFeedbackChannel.discordWebhook,
      if (dingTalkWebhookUrl != null) HelpFeedbackChannel.dingTalkWebhook,
      if (submitHandler != null) HelpFeedbackChannel.custom,
    ];
  }
}

/// Feedback data submitted from HelpFeedbackConfig channels.
class HelpFeedbackPayload {
  /// Creates a feedback payload.
  const HelpFeedbackPayload({
    required this.content,
    this.contact,
    this.systemInfo,
    this.channels = const [],
    this.attachments = const [],
    this.attachmentFilenames = const [],
  });

  /// Main feedback text entered by the user.
  final String content;

  /// Optional contact information entered by the user.
  final String? contact;

  /// Optional collected system information.
  final String? systemInfo;

  /// Channels selected for this submission.
  final List<HelpFeedbackChannel> channels;

  /// Raw image bytes for Discord multipart upload (PNG/JPEG).
  /// Up to 5 images, matching SwiftHelpCenter's max.
  final List<Uint8List> attachments;

  /// Corresponding filenames for each attachment (e.g. "screenshot1.png").
  /// Must match attachments length if provided.
  final List<String> attachmentFilenames;

  /// Whether any image attachments are present.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Combined text sent to channels that accept a single message body.
  String get combinedContent {
    final buffer = StringBuffer(content.trim());
    if (contact != null && contact!.trim().isNotEmpty) {
      buffer.write('\n\nContact: ${contact!.trim()}');
    }
    if (systemInfo != null && systemInfo!.trim().isNotEmpty) {
      buffer.write('\n\nSystem Info:\n${systemInfo!.trim()}');
    }
    return buffer.toString();
  }
}
