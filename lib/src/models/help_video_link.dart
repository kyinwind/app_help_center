/// Video or article link attached to a version history entry.
class HelpVideoLink {
  /// Creates a link to external training or release content.
  const HelpVideoLink({
    required this.title,
    required this.url,
  });

  /// Link title shown in the help center.
  final String title;

  /// Destination URL opened when the link is tapped.
  final Uri url;

  /// Stable id derived from the URL.
  String get id => url.toString();

  /// Creates a video link from JSON.
  factory HelpVideoLink.fromJson(Map<String, dynamic> json) {
    return HelpVideoLink(
      title: json['title'] as String? ?? '',
      url: Uri.parse(json['url'] as String),
    );
  }

  /// Converts this link to JSON.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url.toString(),
    };
  }
}
