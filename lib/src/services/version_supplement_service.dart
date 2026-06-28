import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_help_center_config.dart';
import '../models/version_history_item.dart';

/// Fetches and parses remote version supplement metadata.
class VersionSupplementService {
  /// Creates a version supplement service with an optional HTTP client.
  const VersionSupplementService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// Fetches version supplements using AppHelpCenterConfig.remoteVersionSupplementUrl.
  Future<List<VersionHistorySupplement>> fetch(
    AppHelpCenterConfig config,
  ) async {
    final url = config.remoteVersionSupplementUrl;
    if (url == null) {
      return const [];
    }

    final client = _client ?? http.Client();
    try {
      final response = await client.get(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Remote version supplement request failed: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final parser = config.remoteVersionSupplementParser;
      if (parser != null) {
        return parser(decoded);
      }

      return parseSupplements(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  /// Parses version supplement JSON from a list or wrapped object.
  static List<VersionHistorySupplement> parseSupplements(Object? decoded) {
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VersionHistorySupplement.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final items = decoded['supplements'] ?? decoded['versionSupplements'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(VersionHistorySupplement.fromJson)
            .toList();
      }
    }

    return const [];
  }
}
