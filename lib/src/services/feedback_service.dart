import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

    // When attachments are present, use multipart/form-data
    // Mirrors SwiftHelpCenter's createMultipartBody()
    if (payload.hasAttachments) {
      await _sendDiscordMultipart(url, payload);
    } else {
      await _postJson(url, {
        'content': payload.combinedContent,
      });
    }
  }

  /// Send feedback to Discord with image attachments using multipart/form-data.
  ///
  /// Mirrors SwiftHelpCenter's `sendToDiscord()` with attachments branch.
  /// Uses the Discord API's multipart upload format:
  /// - `payload_json` field with the text content
  /// - `files[0]`..`files[N]` fields with image data
  Future<void> _sendDiscordMultipart(
    Uri url,
    HelpFeedbackPayload payload,
  ) async {
    final request = http.MultipartRequest('POST', url);

    // payload_json with content text
    final payloadJson = jsonEncode({'content': payload.combinedContent});
    request.fields['payload_json'] = payloadJson;

    // Attach image files
    for (int i = 0; i < payload.attachments.length; i++) {
      final bytes = payload.attachments[i];
      final filename = payload.attachmentFilenames.isNotEmpty
          ? payload.attachmentFilenames[i]
          : 'screenshot_$i.png';

      // Determine MIME type from filename extension
      final mimeType = _mimeTypeForFilename(filename);

      request.files.add(
        http.MultipartFile.fromBytes(
          'files[$i]',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final client = _client ?? http.Client();
    try {
      final streamResponse = await client.send(request);
      final response = await http.Response.fromStream(streamResponse);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorText = response.body;
        throw StateError(
          'Discord multipart upload failed (${response.statusCode}): $errorText',
        );
      }
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  /// Determine MIME type from filename extension.
  /// Mirrors SwiftHelpCenter's `mimeTypeFor(url:)`.
  String _mimeTypeForFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'txt':
      case 'log':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _sendDingTalk(
    HelpFeedbackConfig config,
    HelpFeedbackPayload payload,
  ) async {
    final url = config.dingTalkWebhookUrl;
    if (url == null) {
      return;
    }
    final content =
        config.dingTalkContentBuilder?.call(payload) ?? payload.combinedContent;

    await _postJson(url, {
      'msgtype': 'text',
      'text': {
        'content': content,
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
