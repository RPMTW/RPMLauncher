import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/io.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:uuid/uuid.dart';

class GameRepository {
  static void init(Directory root) {
    File configFile = File(join(root.path, 'config.json'));
    File accountFile = File(join(root.path, 'accounts.json'));
    if (!configFile.existsSync()) {
      configFile.create(recursive: true);
      configFile.writeAsStringSync('{}');
    }
    if (!accountFile.existsSync()) {
      accountFile.create(recursive: true);
      accountFile.writeAsStringSync('{}');
    }
    IOUtil.createFolderOptimization(getInstanceRootDir());
  }

  static Directory getInstanceRootDir() {
    return Directory(join(dataHome.absolute.path, 'instances'));
  }

  static File getConfigFile() {
    File file =
        File(join(LauncherPath.currentConfigHome.absolute.path, 'config.json'));

    if (!file.existsSync()) {
      file.create(recursive: true);
      file.writeAsStringSync(json.encode({}));
    }
    return file;
  }

  static File getAccountFile() {
    File file = File(
        join(LauncherPath.currentConfigHome.absolute.path, 'accounts.json'));

    if (!file.existsSync()) {
      file.create(recursive: true);
      file.writeAsStringSync(json.encode({}));
    }

    return file;
  }

  static Directory getVersionsRootDir() {
    return Directory(join(dataHome.absolute.path, 'versions'));
  }

  static Directory getAssetsDir() {
    return Directory(join(dataHome.path, 'assets'));
  }

  static File getAssetsObjectFile(String hash) {
    return File(join(
        getAssetsDir().absolute.path, 'objects', hash.substring(0, 2), hash));
  }

  static Directory getVersionsDir(String versionID) {
    return Directory(join(getVersionsRootDir().absolute.path, versionID));
  }

  static Directory getNativesDir(String versionID) {
    return Directory(join(getVersionsDir(versionID).absolute.path, 'natives'));
  }

  static Directory getNativesTempDir() {
    return Directory(
        join(dataHome.absolute.path, 'temp_natives', const Uuid().v4()));
  }

  static Directory getTempDir() {
    return Directory(join(dataHome.absolute.path, 'temp'));
  }

  static Directory getDatabaseDir() {
    return Directory(join(dataHome.absolute.path, 'database'));
  }

  static File getModIconFile(String hash) {
    return File(join(getTempDir().path, 'mod_icons', '$hash.png'));
  }

  static File getForgeProfileFile(String versionID) {
    return File(join(getVersionsDir(versionID).path, 'forge_profile.json'));
  }

  static Directory getLibraryGlobalDir() {
    return Directory(join(dataHome.absolute.path, 'libraries'));
  }
}
