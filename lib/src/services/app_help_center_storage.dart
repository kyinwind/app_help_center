import 'package:shared_preferences/shared_preferences.dart';

class AppHelpCenterStorage {
  AppHelpCenterStorage({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<DateTime?> lastViewedVersionPublishedAt(String key) async {
    final milliseconds = (await _prefs).getInt(key);
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> setLastViewedVersionPublishedAt(
    String key,
    DateTime publishedAt,
  ) async {
    await (await _prefs).setInt(key, publishedAt.millisecondsSinceEpoch);
  }

  Future<Set<String>> readAnnouncementIds(String key) async {
    return ((await _prefs).getStringList(key) ?? const []).toSet();
  }

  Future<void> setReadAnnouncementIds(String key, Set<String> ids) async {
    await (await _prefs).setStringList(key, ids.toList()..sort());
  }

  Future<void> reset({
    required String versionHistoryStorageKey,
    required String announcementStorageKey,
  }) async {
    final prefs = await _prefs;
    await prefs.remove(versionHistoryStorageKey);
    await prefs.remove(announcementStorageKey);
  }
}
