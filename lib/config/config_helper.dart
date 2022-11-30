import 'package:shared_preferences/shared_preferences.dart';

class ConfigHelper {
  static late final SharedPreferences _prefs;

  /// Initialize the config helper
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the value of the key by the config file.
  static T? get<T>(String key) {
    Object? value = _prefs.get(key);
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  /// Set the value of the key to the config file.
  /// If the value is null, the key will be removed.
  ///
  /// Support types:
  /// - boolean
  /// - int
  /// - double
  /// - String
  /// - List<String>
  static Future<void> set<T>(String key, T? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      throw Exception('Unsupported config data type');
    }
  }

  /// Get all keys and values in the config file.
  static Map<String, Object?> getAll() {
    final Map<String, Object?> map = {};

    _prefs.getKeys().forEach((key) {
      map[key] = _prefs.get(key);
    });

    return map;
  }
}
