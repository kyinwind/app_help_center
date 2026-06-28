import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Collects lightweight app and platform details for feedback payloads.
class SystemInfoProvider {
  /// Creates a system information provider.
  const SystemInfoProvider();

  /// Collects app name, platform, locale, and Flutter build mode.
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
