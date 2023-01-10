import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

class GameRepository {
  static File getAccountFile() {
    return File(join(LauncherPath.currentConfigHome.path, 'accounts.json'));
  }

  static Directory getDatabaseDirectory() {
    return Directory(join(dataHome.path, 'database'));
  }

  static Directory getCollectionsDirectory() {
    return Directory(join(dataHome.path, 'collections'));
  }

  static Directory getMetaDirectory() {
    return Directory(join(dataHome.path, 'meta'));
  }
}
