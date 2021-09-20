import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:rpmlauncher/Launcher/GameRepository.dart';

import 'i18n.dart';

class Config {
  static io.File _ConfigFile = GameRepository.getConfigFile();
  static Map _config = json.decode(_ConfigFile.readAsStringSync());

  Config(File ConfigFile) {
    _ConfigFile = ConfigFile;
    _config = json.decode(ConfigFile.readAsStringSync());
  }

  static final DefaultConfigObject = {
    "init": false,
    "java_path_8": "",
    "java_path_16": "",
    "auto_java": true,
    "java_max_ram": 4096,
    "java_jvm_args": [], //Jvm 參數
    "lang_code": i18n.getLanguageCode(), //系統預設語言
    "check_assets": true,
    "game_width": 854,
    "game_height": 480,
    "max_log_length": 500,
    "show_log": false,
    "auto_dependencies": true,
    "theme_id": 0,
    "update_channel": "stable"
  };

  static void change(String key, value) {
    Config(_ConfigFile).Change(key, value);
  }

  void Change(String key, value) {
    _config[key] = value;
    Save();
  }

  static Map get() {
    return Config(_ConfigFile).Get();
  }

  Map Get() {
    return _config;
  }

  static dynamic getValue(String key) {
    return Config(_ConfigFile).GetValue(key);
  }

  dynamic GetValue(String key) {
    Update();
    if (!_config.containsKey(key)) {
      _config[key] = DefaultConfigObject[key];
      Save();
    }
    return _config[key];
  }

  static void save() {
    Config(_ConfigFile).Save();
  }

  void Save() {
    _ConfigFile.writeAsStringSync(json.encode(_config));
  }

  static void update() {
    Config(_ConfigFile).Update();
  }

  void Update() {
    _config = json.decode(_ConfigFile.readAsStringSync());
  }
}
