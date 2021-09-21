import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';

late final Directory _root;

class path {
  static Directory get currentDataHome => _root;

  Future<void> init() async {
    _root = Directory(
        join((await getApplicationSupportDirectory()).absolute.path, "data"));
    if (!Directory(join(_root.absolute.path)).existsSync()) {
      Directory(join(_root.absolute.path)).createSync();
    }
    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    if (!await Directory(_root.absolute.path).exists()) {
      Directory(_root.absolute.path).createSync();
    }
    GameRepository.init();
    if (!await ConfigFile.exists()) {
      ConfigFile.create(recursive: true);
      ConfigFile.writeAsStringSync("{}");
    }
    if (!await AccountFile.exists()) {
      AccountFile.create(recursive: true);
      AccountFile.writeAsStringSync("{}");
    }
  }
}
