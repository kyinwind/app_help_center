import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_help_center_config.dart';
import '../models/training_video.dart';

/// Fetches and parses remote training videos.
class TrainingVideoService {
  /// Creates a service with an optional HTTP client.
  const TrainingVideoService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// Fetches videos from AppHelpCenterConfig.trainingVideos.remoteUrl.
  Future<List<TrainingVideo>> fetch(AppHelpCenterConfig config) async {
    final videoConfig = config.trainingVideos;
    final url = videoConfig?.remoteUrl;
    if (url == null) return const [];

    final client = _client ?? http.Client();
    try {
      final response = await client.get(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Remote training video request failed: ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(response.body);
      final parser = videoConfig?.remoteParser;
      return parser?.call(decoded) ?? parseTrainingVideos(decoded);
    } finally {
      if (_client == null) client.close();
    }
  }

  /// Parses a JSON array and skips malformed or invalid entries individually.
  static List<TrainingVideo> parseTrainingVideos(Object? decoded) {
    if (decoded is! List<dynamic>) return const [];
    final items = <TrainingVideo>[];
    for (final value in decoded) {
      if (value is! Map<String, dynamic>) continue;
      try {
        final item = TrainingVideo.fromJson(value);
        if (item.isValid) items.add(item);
      } catch (_) {
        // A malformed entry must not hide the remaining valid videos.
      }
    }
    if (decoded.isNotEmpty && items.isEmpty) {
      throw const FormatException('No valid training videos.');
    }
    return items;
  }
}
