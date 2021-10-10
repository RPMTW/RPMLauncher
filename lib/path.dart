// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/Config.dart';

late final Directory _root;

class path {
  static Directory get DefaultDataHome => _root;
  static Directory get currentConfigHome => DefaultDataHome;
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
    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    GameRepository.init();
    if (!ConfigFile.existsSync()) {
      ConfigFile.create(recursive: true);
      ConfigFile.writeAsStringSync("{}");
    }
    if (!AccountFile.existsSync()) {
      AccountFile.create(recursive: true);
      AccountFile.writeAsStringSync("{}");
    }

    if (!currentDataHome.existsSync()) {
      currentDataHome.createSync(recursive: true);
    }
  }
}
