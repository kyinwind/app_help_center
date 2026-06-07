import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_help_center_config.dart';
import '../models/help_announcement.dart';

class AnnouncementService {
  const AnnouncementService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<HelpAnnouncement>> fetch(AppHelpCenterConfig config) async {
    final url = config.remoteAnnouncementsUrl;
    if (url == null) {
      return const [];
    }

    final client = _client ?? http.Client();
    try {
      final response = await client.get(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Remote announcement request failed: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final parser = config.remoteAnnouncementsParser;
      if (parser != null) {
        return parser(decoded);
      }

      return parseAnnouncements(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  static List<HelpAnnouncement> parseAnnouncements(Object? decoded) {
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(HelpAnnouncement.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final items = decoded['announcements'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(HelpAnnouncement.fromJson)
            .toList();
      }
    }

    return const [];
  }
}
