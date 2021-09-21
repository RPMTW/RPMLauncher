import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';

late final Directory _root;

class path {
  static Directory get currentDataHome => _root;

  Future<void> init() async {
    _root = Directory(join(
        (await getApplicationDocumentsDirectory()).absolute.path,
        "RPMLauncher",
        "data"));

    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    if (!_root.existsSync()) {
      _root.createSync(recursive: true);
    }
    GameRepository.init();
    if (!ConfigFile.existsSync()) {
      ConfigFile.create(recursive: true);
      ConfigFile.writeAsStringSync("{}");
    }
    if (!AccountFile.existsSync()) {
      AccountFile.create(recursive: true);
      AccountFile.writeAsStringSync("{}");
    }
  }
}
