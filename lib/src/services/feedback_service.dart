import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/help_feedback.dart';
import 'help_link_launcher.dart';

class FeedbackService {
  const FeedbackService({
    http.Client? client,
    HelpLinkLauncher? linkLauncher,
  })  : _client = client,
        _linkLauncher = linkLauncher ?? const HelpLinkLauncher();

  final http.Client? _client;
  final HelpLinkLauncher _linkLauncher;

  Future<void> submit({
    required HelpFeedbackConfig config,
    required HelpFeedbackPayload payload,
  }) async {
    final channels = payload.channels.isNotEmpty
        ? payload.channels
        : config.availableChannels;

    Object? lastError;
    var didSubmit = false;

    for (final channel in channels) {
      try {
        switch (channel) {
          case HelpFeedbackChannel.email:
            await _sendEmail(config, payload);
          case HelpFeedbackChannel.webForm:
            await _openWebForm(config);
          case HelpFeedbackChannel.discordWebhook:
            await _sendDiscord(config, payload);
          case HelpFeedbackChannel.dingTalkWebhook:
            await _sendDingTalk(config, payload);
          case HelpFeedbackChannel.custom:
            await config.submitHandler?.call(payload);
        }
        didSubmit = true;
      } catch (error) {
        lastError = error;
      }
    }

    if (!didSubmit && lastError != null) {
      throw StateError('Feedback submission failed: $lastError');
    }
  }

  Future<void> _sendEmail(
    HelpFeedbackConfig config,
    HelpFeedbackPayload payload,
  ) async {
    final email = config.email;
    if (email == null || email.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': config.subject,
        'body': payload.combinedContent,
      },
    );
    await _linkLauncher.open(uri);
  }

  Future<void> _openWebForm(HelpFeedbackConfig config) async {
    final url = config.webFormUrl;
    if (url != null) {
      await _linkLauncher.open(url);
    }
  }

  Future<void> _sendDiscord(
    HelpFeedbackConfig config,
    HelpFeedbackPayload payload,
  ) async {
    final url = config.discordWebhookUrl;
    if (url == null) {
      return;
    }
    await _postJson(url, {
      'content': payload.combinedContent,
    });
  }

  Future<void> _sendDingTalk(
    HelpFeedbackConfig config,
    HelpFeedbackPayload payload,
  ) async {
    final url = config.dingTalkWebhookUrl;
    if (url == null) {
      return;
    }
    await _postJson(url, {
      'msgtype': 'text',
      'text': {
        'content': payload.combinedContent,
      },
    });
  }

  Future<void> _postJson(Uri url, Map<String, dynamic> body) async {
    final client = _client ?? http.Client();
    try {
      final response = await client.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Webhook request failed: ${response.statusCode}');
      }
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}
