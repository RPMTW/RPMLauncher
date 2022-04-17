// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

import 'I18n.dart';

class Config {
  static File _configFile = GameRepository.getConfigFile();
  static Map _config = json.decode(_configFile.readAsStringSync());

  Config(File configFile) {
    _configFile = configFile;
    if (!configFile.existsSync()) {
      configFile.createSync(recursive: true);
      configFile.writeAsStringSync(json.encode({}));
    }
    _config = json.decode(configFile.readAsStringSync());
  }

  static final Map defaultConfigMap = {
    "init": false,
    "auto_java": true,
    "java_max_ram": 4096.0,
    "java_jvm_args": [], //Jvm 參數
    "lang_code": I18n.getLanguageCode(), //系統預設語言
    "check_assets": true,
    "game_width": 854,
    "game_height": 480,
    "max_log_length": 300,
    "show_log": true,
    "auto_dependencies": true,
    "theme_id": 0,
    "update_channel": "stable",
    "data_home": LauncherPath.defaultDataHome.absolute.path,
    "ga_client_id":
        "${Random().nextInt(0x7FFFFFFF)}.${DateTime.now().millisecondsSinceEpoch / 1000}",
    "auto_full_screen": false,
    "validate_account": true,
    "auto_close_log_screen": false,
    "wrapper_command": null,
    "discord_rpc": true
  };

  static void change(String key, value) {
    Config(_configFile).Change(key, value);
  }

  void Change(String key, value) {
    _config[key] = value;
    Save();
  }

  static Map toMap() {
    return Config(_configFile).ToMap();
  }

  Map ToMap() {
    return _config;
  }

  static dynamic getValue(String key, {String? defaultValue}) {
    return Config(_configFile).GetValue(key, defaultValue: defaultValue);
  }

  dynamic GetValue(String key, {String? defaultValue}) {
    if (!_config.containsKey(key)) {
      _config[key] = defaultConfigMap[key] ?? defaultValue;
      Save();
    }
    return _config[key] ?? defaultValue;
  }

  static void save() {
    Config(_configFile).Save();
  }

  void Save() {
    try {
      _configFile.writeAsStringSync(json.encode(_config));
    } on FileSystemException {}
  }
}
