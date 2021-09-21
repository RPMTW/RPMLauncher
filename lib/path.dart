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
  static Directory get currentDataHome =>
      Directory(Config.getValue('data_home'));

  Future<void> init() async {
    _root = Directory(join(
        (await getApplicationDocumentsDirectory()).absolute.path,
        "RPMLauncher",
        "data"));

    if (!_root.existsSync()) {
      _root.createSync(recursive: true);
    }
    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    if (!ConfigFile.existsSync()) {
      ConfigFile.create(recursive: true);
      ConfigFile.writeAsStringSync("{}");
    }
    if (!AccountFile.existsSync()) {
      AccountFile.create(recursive: true);
      AccountFile.writeAsStringSync("{}");
    }
    GameRepository.init();

    if (!currentDataHome.existsSync()) {
      currentDataHome.createSync(recursive: true);
    }
  }
}
