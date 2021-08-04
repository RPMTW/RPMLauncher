import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart';

import '../path.dart';
import 'i18n.dart';

class Config {
  static io.Directory _ConfigFolder = configHome;
  static io.File _ConfigFile =
      io.File(join(_ConfigFolder.absolute.path, "config.json"));
  static Map _config = json.decode(_ConfigFile.readAsStringSync());

  var DefaultConfigObject = {
    "java_path": "",
    "auto_java": true,
    "java_max_ram": 4096,
    "lang_code": i18n().GetLanguageCode(), //系統預設語言
    "check_assets": true,
    "game_width": 1920,
    "game_height": 1080
  };

  void Change(key, value) {
    _config[key] = value;
    Save();
  }

  static Map Get() {
    return _config;
  }

  dynamic GetValue(key) {
    if (!_config.containsKey(key)) {
      _config[key] = DefaultConfigObject[key];
      Save();
    }
    return _config[key];
  }

  void Save() {
    _ConfigFile.writeAsStringSync(json.encode(_config));
  }
}
