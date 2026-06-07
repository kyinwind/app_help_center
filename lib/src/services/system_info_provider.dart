import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class SystemInfoProvider {
  const SystemInfoProvider();

  String collect({
    required String appName,
    Locale? locale,
  }) {
    return [
      'App: $appName',
      'Platform: ${defaultTargetPlatform.name}',
      'Locale: ${locale?.toLanguageTag() ?? PlatformDispatcher.instance.locale.toLanguageTag()}',
      'Flutter mode: ${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug'}',
    ].join('\n');
  }
}
