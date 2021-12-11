import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:uuid/uuid.dart';

class GameRepository {
  static Directory _instanceRootDir =
      Directory(join(dataHome.absolute.path, "instances"));
  static Directory _versionRootDir =
      Directory(join(dataHome.absolute.path, "versions"));

  static void init(Directory _root) {
    File configFile = File(join(_root.path, "config.json"));
    File accountFile = File(join(_root.path, "accounts.json"));
    if (!configFile.existsSync()) {
      configFile.create(recursive: true);
      configFile.writeAsStringSync("{}");
    }
    if (!accountFile.existsSync()) {
      accountFile.create(recursive: true);
      accountFile.writeAsStringSync("{}");
    }
    Uttily.createFolderOptimization(_instanceRootDir);
  }

  static Directory getInstanceRootDir() {
    return _instanceRootDir;
  }

  static File getConfigFile() {
    File _file =
        File(join(RPMPath.currentConfigHome.absolute.path, "config.json"));

    if (!_file.existsSync()) {
      _file.create(recursive: true);
      _file.writeAsStringSync(json.encode({}));
    }
    return _file;
  }

  static File getAccountFile() {
    File _file =
        File(join(RPMPath.currentConfigHome.absolute.path, "accounts.json"));

    if (!_file.existsSync()) {
      _file.create(recursive: true);
      _file.writeAsStringSync(json.encode({}));
    }
    return _file;
  }

  static Directory getVersionsRootDir() {
    return _versionRootDir;
  }

  static Directory getAssetsDir() {
    return Directory(join(dataHome.path, "assets"));
  }

  static File getAssetsObjectFile(String hash) {
    return File(join(
        getAssetsDir().absolute.path, "objects", hash.substring(0, 2), hash));
  }

  static Directory getVersionsDir(String versionID) {
    return Directory(join(_versionRootDir.absolute.path, versionID));
  }

  static Directory getNativesDir(String versionID) {
    return Directory(join(getVersionsDir(versionID).absolute.path, "natives"));
  }

  static Directory getNativesTempDir() {
    return Directory(join(dataHome.absolute.path, "temp_natives", Uuid().v4()));
  }

  static File getClientJar(String versionID) {
    File _file =
        File(join(getVersionsDir(versionID).absolute.path, "$versionID.jar"));

    if (!_file.existsSync()) {
      /// RPMLauncher 舊版放置位置
      _file = File(join(getVersionsDir(versionID).absolute.path, "client.jar"));
    }
    return _file;
  }

  static File getArgsFile(String versionID, ModLoader loader,
      {String? loaderVersion}) {
    if (loader != ModLoader.vanilla && loaderVersion == null) {
      throw Exception(
          "Mod loaders other than the vanilla require loader version parameters");
    }

    String argsPath = join(getVersionsDir(versionID).absolute.path, "args");
    switch (loader) {
      case ModLoader.fabric:
        return File(join(argsPath, "Fabric", "$loaderVersion.json"));
      case ModLoader.forge:
        return File(join(argsPath, "Forge", "$loaderVersion.json"));
      case ModLoader.vanilla:
        return File(join(argsPath, "args.json"));
      default:
        throw Exception("Unknown loader, failed to get Args");
    }
  }

  static Directory getLibraryGlobalDir() {
    return Directory(join(dataHome.absolute.path, "libraries"));
  }
}
