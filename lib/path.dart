import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/main.dart';


class path {
  Future init() async {
    dataHome = Directory(
        join((await getApplicationSupportDirectory()).absolute.path, "data"));
    if (!Directory(join(dataHome.absolute.path)).existsSync()) {
      Directory(join(dataHome.absolute.path)).createSync();
    }
    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    if (!await Directory(dataHome.absolute.path).exists()) {
      Directory(dataHome.absolute.path).createSync();
    }
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
