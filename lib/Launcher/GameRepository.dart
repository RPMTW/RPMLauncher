import 'dart:io';

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';
import 'package:rpmlauncher/path.dart';

class GameRepository {
  static Directory _instanceRootDir =
      Directory(join(dataHome.absolute.path, "instances"));
  static Directory _versionRootDir =
      Directory(join(dataHome.absolute.path, "versions"));

  static void init() {
    utility.CreateFolderOptimization(getInstanceRootDir());
    utility.CreateFolderOptimization(getVersionsRootDir());
  }

  static Directory getInstanceRootDir() {
    return _instanceRootDir;
  }

  static File getConfigFile() {
    return File(join(path.currentConfigHome.absolute.path, "config.json"));
  }

  static File getAccountFile() {
    return File(join(path.currentConfigHome.absolute.path, "accounts.json"));
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

  static File getArgsFile(String versionID, ModLoaders Loader,
      [String? loaderVersion]) {
    if (Loader != ModLoaders.vanilla && loaderVersion == null) {
      throw Exception(
          "Mod loaders other than the vanilla require loader version parameters");
    }

    String ArgsPath = join(getVersionsDir(versionID).absolute.path, "args");
    switch (Loader) {
      case ModLoaders.fabric:
        return File(join(ArgsPath, "Fabric", "$loaderVersion.json"));
      case ModLoaders.forge:
        return File(join(ArgsPath, "Forge", "$loaderVersion.json"));
      case ModLoaders.vanilla:
        return File(join(ArgsPath, "args.json"));
      default:
        throw Exception("Unknown loader, failed to get Args");
    }
  }

  static Directory getLibraryGlobalDir() {
    return Directory(join(dataHome.absolute.path, "libraries"));
  }
}
