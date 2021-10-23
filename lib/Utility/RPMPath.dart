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
      return Directory.current;
    }
  }

  static Future<void> init() async {
    try {
      _root = Directory(join(
          (await getApplicationDocumentsDirectory()).absolute.path,
          "RPMLauncher",
          "data"));
    } catch (e) {
      _root = Directory(
          join(Directory.current.absolute.path, "RPMLauncher", "data"));
    }

    if (!_root.existsSync()) {
      _root.createSync(recursive: true);
    }

    if (!currentDataHome.existsSync()) {
      currentDataHome.createSync(recursive: true);
    }
    GameRepository.init();
  }
}
