import 'package:url_launcher/url_launcher.dart';

class HelpLinkLauncher {
  const HelpLinkLauncher();

  Future<bool> open(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
