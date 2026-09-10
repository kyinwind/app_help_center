/// A training video shown in the help center.
class TrainingVideo {
  /// Creates a video with a stable [id], caller-localized [title], and web URL.
  const TrainingVideo({
    required this.id,
    required this.title,
    required this.url,
  });

  /// Stable identifier used when merging local and remote content.
  final String id;

  /// Caller-localized title displayed verbatim.
  final String title;

  /// HTTP or HTTPS URL opened for this video.
  final Uri url;

  /// Whether this item contains all required, safe-to-display values.
  bool get isValid =>
      id.trim().isNotEmpty &&
      title.trim().isNotEmpty &&
      (url.scheme == 'http' || url.scheme == 'https') &&
      url.host.isNotEmpty;

  /// Creates a training video from the SwiftHelpCenter-compatible JSON schema.
  factory TrainingVideo.fromJson(Map<String, dynamic> json) {
    return TrainingVideo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: Uri.tryParse(json['url'] as String? ?? '') ?? Uri(),
    );
  }

  /// Converts this video to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url.toString(),
      };
}

/// Local and remote training-video sources.
///
/// This mirrors SwiftHelpCenter's training-video configuration so host apps can
/// use the same mental model on Apple and Flutter platforms.
class TrainingVideoConfig {
  /// Creates a training-video configuration.
  const TrainingVideoConfig({
    this.items = const [],
    this.remoteUrl,
    this.remoteParser,
  });

  /// Caller-localized videos bundled with the app.
  final List<TrainingVideo> items;

  /// Optional SwiftHelpCenter-compatible JSON endpoint.
  final Uri? remoteUrl;

  /// Optional parser for endpoints with a custom response schema.
  final List<TrainingVideo> Function(Object decodedJson)? remoteParser;
}
