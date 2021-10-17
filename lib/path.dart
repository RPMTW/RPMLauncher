import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/Config.dart';

late final Directory _root;

class RPMPath {
  static Directory get defaultDataHome => _root;
  static Directory get currentConfigHome => defaultDataHome;
  static Directory get currentDataHome {
    try {
      return Directory(Config.getValue('data_home'));
    } catch (e) {
      init();
      return Directory(Config.getValue('data_home'));
    }
  }

  static Future<void> init() async {
    try {
      _root = Directory(join(
          (await getApplicationDocumentsDirectory()).absolute.path,
          "RPMLauncher",
          "data"));
    } catch (e) {
      _root = Directory(join(
          (await getApplicationSupportDirectory()).absolute.path,
          "RPMLauncher",
          "data"));
    }

    if (!_root.existsSync()) {
      _root.createSync(recursive: true);
    }
    File configFile = GameRepository.getConfigFile();
    File accountFile = GameRepository.getAccountFile();
    if (!configFile.existsSync()) {
      configFile.create(recursive: true);
      configFile.writeAsStringSync("{}");
    }
    if (!accountFile.existsSync()) {
      accountFile.create(recursive: true);
      accountFile.writeAsStringSync("{}");
    }

    if (!currentDataHome.existsSync()) {
      currentDataHome.createSync(recursive: true);
    }
    GameRepository.init();
  }
}
