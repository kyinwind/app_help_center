import 'dart:typed_data';

enum HelpFeedbackChannel {
  email,
  webForm,
  discordWebhook,
  dingTalkWebhook,
  custom,
}

typedef HelpFeedbackSubmitHandler = Future<void> Function(
  HelpFeedbackPayload payload,
);

typedef DingTalkContentBuilder = String Function(
  HelpFeedbackPayload payload,
);

class HelpFeedbackConfig {
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

  final String? email;
  final Uri? webFormUrl;
  final Uri? discordWebhookUrl;
  final Uri? dingTalkWebhookUrl;
  final DingTalkContentBuilder? dingTalkContentBuilder;
  final HelpFeedbackSubmitHandler? submitHandler;
  final String subject;
  final bool includeSystemInfo;
  final bool allowChannelSelection;

  /// Whether to show screenshot picker when Discord channel is selected.
  /// Mirrors SwiftHelpCenter's `ScreenshotPickerView`.
  final bool allowScreenshots;

  /// Maximum number of screenshots allowed.
  /// Default 5, matching SwiftHelpCenter.
  final int maxScreenshots;

  bool get isConfigured => availableChannels.isNotEmpty;

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

class HelpFeedbackPayload {
  const HelpFeedbackPayload({
    required this.content,
    this.contact,
    this.systemInfo,
    this.channels = const [],
    this.attachments = const [],
    this.attachmentFilenames = const [],
  });

  final String content;
  final String? contact;
  final String? systemInfo;
  final List<HelpFeedbackChannel> channels;

  /// Raw image bytes for Discord multipart upload (PNG/JPEG).
  /// Up to 5 images, matching SwiftHelpCenter's max.
  final List<Uint8List> attachments;

  /// Corresponding filenames for each attachment (e.g. "screenshot1.png").
  /// Must match `attachments` length if provided.
  final List<String> attachmentFilenames;

  /// Whether any image attachments are present.
  bool get hasAttachments => attachments.isNotEmpty;

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
