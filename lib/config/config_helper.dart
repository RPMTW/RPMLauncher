import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/config/json_storage.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

final ConfigHelper configHelper = ConfigHelper();

class ConfigHelper extends JsonStorage {
  ConfigHelper()
      : super(File(join(LauncherPath.defaultDataHome.path, 'config.json')));

  @override
  Future<void> init() async {
    if (file.existsSync()) {
      final String stringMap = file.readAsStringSync();
      if (stringMap.isNotEmpty) {
        final Object? data = json.decode(stringMap);
        if (data is Map && !data.containsKey('schema_version')) {
          await _migrateOldConfig(data);
        }
      }
    } else {
      await setItem('schema_version', 1);
    }

    await super.init();
  }

  /// Migrate the old config to new config.
  Future<void> _migrateOldConfig(Map config) async {
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

    await writeData(newConfig);
  }
}
