import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmlauncher/util/logger.dart';

class ConfigHelper {
  /// Local copy of config.
  static Map<String, Object>? _cachedConfig;

  /// The config file.
  static final File _file =
      File(join(LauncherPath.defaultDataHome.path, 'config.json'));

  static Future<void> init() async {
    if (_file.existsSync()) {
      final String stringMap = _file.readAsStringSync();
      if (stringMap.isNotEmpty) {
        final Object? data = json.decode(stringMap);
        if (data is Map && !data.containsKey('schema_version')) {
          await _migrateOldConfig(data);
        }
      }
    } else {
      await set('schema_version', 1);
    }

    await _readConfig();
  }

  /// Gets the config from the stored file. Once read, the config are
  /// maintained in memory.
  static Future<Map<String, Object>> _readConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    Map<String, Object> config = <String, Object>{};
    if (_file.existsSync()) {
      final String stringMap = _file.readAsStringSync();
      if (stringMap.isNotEmpty) {
        final Object? data = json.decode(stringMap);
        if (data is Map) {
          config = data.cast<String, Object>();
        }
      }
    }
    _cachedConfig = config;

    return config;
  }

  /// Writes the cached config to disk. Returns [true] if the operation
  /// succeeded.
  static Future<bool> _writeConfig(Map<String, Object> config) async {
    try {
      if (!_file.existsSync()) {
        _file.createSync(recursive: true);
      }
      final String stringMap = json.encode(config);
      _file.writeAsStringSync(stringMap);
    } catch (e, s) {
      logger.error(ErrorType.config, 'Error saving config to disk: $e',
          stackTrace: s);
      return false;
    }
    return true;
  }

  /// Migrate the old config to new config.
  static Future<void> _migrateOldConfig(Map config) async {
    final Map<String, Object> newConfig = {};

    handle(String oldKey, String newKey) {
      if (config[oldKey] != null) {
        newConfig[newKey] = config[oldKey];
      }
    }

    newConfig['schema_version'] = 1;
    handle('init', 'init');
    handle('auto_java', 'auto_install_java');
    handle('java_max_ram', 'jvm_max_ram');
    handle('java_jvm_args', 'jvm_args');
    handle('lang_code', 'language');
    handle('check_assets', 'check_assets_integrity');
    handle('game_width', 'game_window_width');
    handle('game_height', 'game_window_height');
    handle('max_log_length', 'game_log_max_line_count');
    handle('show_log', 'show_game_logs');
    handle('auto_close_log_screen', 'auto_close_game_logs_screen');
    handle('auto_dependencies', 'auto_download_mod_dependencies');
    handle('theme_id', 'theme_id');
    handle('update_channel', 'update_channel');
    handle('data_home', 'launcher_data_dir');
    handle('ga_client_id', 'google_analytics_client_id');
    handle('auto_full_screen', 'auto_full_screen');
    handle('validate_account', 'check_account_validity');
    handle('wrapper_command', 'wrapper_command');
    handle('discord_rpc', 'enable_discord_rpc');
    handle('background', 'background_image_file');
    handle('java_path_8', 'java_path_8');
    handle('java_path_16', 'java_path_16');
    handle('java_path_17', 'java_path_17');

    await _writeConfig(newConfig);
  }

  /// Get the value of the key by the config file.
  static T? get<T>(String key) {
    Object? value = _cachedConfig?[key];
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  /// Set the value of the key to the config file.
  /// If the value is null, the key will be removed.
  static Future<void> set<T>(String key, T? value) async {
    final config = await _readConfig();

    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }

    _cachedConfig = config;

    await _writeConfig(config);
  }

  /// Get all keys and values in the config file.
  static Future<Map<String, Object?>> getAll() async {
    return await _readConfig();
  }
}
