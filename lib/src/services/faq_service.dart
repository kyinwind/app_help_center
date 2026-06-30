import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_help_center_config.dart';
import '../models/help_faq_item.dart';

/// Fetches and parses remote FAQ items.
class FaqService {
  /// Creates an FAQ service with an optional HTTP client.
  const FaqService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// Fetches FAQ items using AppHelpCenterConfig.remoteFaqUrl.
  Future<List<HelpFaqItem>> fetch(AppHelpCenterConfig config) async {
    final url = config.remoteFaqUrl;
    if (url == null) {
      return const [];
    }

    final client = _client ?? http.Client();
    try {
      final response = await client.get(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Remote FAQ request failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final parser = config.remoteFaqParser;
      if (parser != null) {
        return parser(decoded);
      }

      return parseFaqItems(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  /// Parses FAQ JSON from a list or wrapped object.
  static List<HelpFaqItem> parseFaqItems(Object? decoded) {
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HelpFaqItem.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final items = decoded['faqItems'] ?? decoded['faq'] ?? decoded['items'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(HelpFaqItem.fromJson)
            .toList();
      }
    }

    return const [];
  }
}
