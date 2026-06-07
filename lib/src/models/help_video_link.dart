class HelpVideoLink {
  const HelpVideoLink({
    required this.title,
    required this.url,
  });

  final String title;
  final Uri url;

  String get id => url.toString();

  factory HelpVideoLink.fromJson(Map<String, dynamic> json) {
    return HelpVideoLink(
      title: json['title'] as String? ?? '',
      url: Uri.parse(json['url'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url.toString(),
    };
  }
}
