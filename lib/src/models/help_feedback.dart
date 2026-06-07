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

class HelpFeedbackConfig {
  const HelpFeedbackConfig({
    this.email,
    this.webFormUrl,
    this.discordWebhookUrl,
    this.dingTalkWebhookUrl,
    this.submitHandler,
    this.subject = 'App Feedback',
    this.includeSystemInfo = true,
    this.allowChannelSelection = true,
  });

  final String? email;
  final Uri? webFormUrl;
  final Uri? discordWebhookUrl;
  final Uri? dingTalkWebhookUrl;
  final HelpFeedbackSubmitHandler? submitHandler;
  final String subject;
  final bool includeSystemInfo;
  final bool allowChannelSelection;

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
  });

  final String content;
  final String? contact;
  final String? systemInfo;
  final List<HelpFeedbackChannel> channels;

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
