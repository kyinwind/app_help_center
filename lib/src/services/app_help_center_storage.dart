import 'package:shared_preferences/shared_preferences.dart';

/// Persistence adapter for help center read state.
class AppHelpCenterStorage {
  /// Creates storage backed by SharedPreferences.
  AppHelpCenterStorage({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Reads the latest version publication date marked as read.
  Future<DateTime?> lastViewedVersionPublishedAt(String key) async {
    final milliseconds = (await _prefs).getInt(key);
    if (milliseconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  /// Persists the latest version publication date marked as read.
  Future<void> setLastViewedVersionPublishedAt(
    String key,
    DateTime publishedAt,
  ) async {
    await (await _prefs).setInt(key, publishedAt.millisecondsSinceEpoch);
  }

  /// Reads ids of announcements marked as read.
  Future<Set<String>> readAnnouncementIds(String key) async {
    return ((await _prefs).getStringList(key) ?? const []).toSet();
  }

  /// Persists ids of announcements marked as read.
  Future<void> setReadAnnouncementIds(String key, Set<String> ids) async {
    await (await _prefs).setStringList(key, ids.toList()..sort());
  }

  /// Clears all stored announcement and version read state.
  Future<void> reset({
    required String versionHistoryStorageKey,
    required String announcementStorageKey,
  }) async {
    final prefs = await _prefs;
    await prefs.remove(versionHistoryStorageKey);
    await prefs.remove(announcementStorageKey);
  }
}
