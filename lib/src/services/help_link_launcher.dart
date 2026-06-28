import 'package:url_launcher/url_launcher.dart';

/// Opens external links for help center actions.
class HelpLinkLauncher {
  /// Creates a link launcher.
  const HelpLinkLauncher();

  /// Opens the URL in an external application when possible.
  Future<bool> open(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
