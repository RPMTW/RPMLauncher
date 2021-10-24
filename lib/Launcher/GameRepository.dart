import 'dart:io';

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/main.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';

class GameRepository {
  static Directory _instanceRootDir =
      Directory(join(dataHome.absolute.path, "instances"));
  static Directory _versionRootDir =
      Directory(join(dataHome.absolute.path, "versions"));

  static void init(Directory _root) {
    Uttily.createFolderOptimization(Directory(join(_root.path, "instances")));

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
  }

  static Directory getInstanceRootDir() {
    return _instanceRootDir;
  }

  static File getConfigFile() {
    return File(join(RPMPath.currentConfigHome.absolute.path, "config.json"));
  }

  static File getAccountFile() {
    return File(join(RPMPath.currentConfigHome.absolute.path, "accounts.json"));
  }

  static Directory getVersionsRootDir() {
    return _versionRootDir;
  }

  static Directory getAssetsDir() {
    return Directory(join(dataHome.path, "assets"));
  }

  static Directory getVersionsDir(versionID) {
    return Directory(join(_versionRootDir.absolute.path, versionID));
  }

  static Directory getNativesDir(versionID) {
    return Directory(join(getVersionsDir(versionID).absolute.path, "natives"));
  }

  static File getClientJar(versionID) {
    return File(join(getVersionsDir(versionID).absolute.path, "client.jar"));
  }

  static File getArgsFile(String versionID, ModLoaders loader,
      {String? loaderVersion}) {
    if (loader != ModLoaders.vanilla && loaderVersion == null) {
      throw Exception(
          "Mod loaders other than the vanilla require loader version parameters");
    }

    String argsPath = join(getVersionsDir(versionID).absolute.path, "args");
    switch (loader) {
      case ModLoaders.fabric:
        return File(join(argsPath, "Fabric", "$loaderVersion.json"));
      case ModLoaders.forge:
        return File(join(argsPath, "Forge", "$loaderVersion.json"));
      case ModLoaders.vanilla:
        return File(join(argsPath, "args.json"));
      default:
        throw Exception("Unknown loader, failed to get Args");
    }
  }

  static Directory getLibraryGlobalDir() {
    return Directory(join(dataHome.absolute.path, "libraries"));
  }
}
