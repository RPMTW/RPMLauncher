import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:uuid/uuid.dart';

class GameRepository {
  static final Directory _instanceRootDir =
      Directory(join(dataHome.absolute.path, "instances"));
  static final Directory _versionRootDir =
      Directory(join(dataHome.absolute.path, "versions"));

  static void init(Directory root) {
    File configFile = File(join(root.path, "config.json"));
    File accountFile = File(join(root.path, "accounts.json"));
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
    File file =
        File(join(RPMPath.currentConfigHome.absolute.path, "config.json"));

    if (!file.existsSync()) {
      file.create(recursive: true);
      file.writeAsStringSync(json.encode({}));
    }
    return file;
  }

  static File getAccountFile() {
    File file =
        File(join(RPMPath.currentConfigHome.absolute.path, "accounts.json"));

    if (!file.existsSync()) {
      file.create(recursive: true);
      file.writeAsStringSync(json.encode({}));
    }
    return file;
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
    return Directory(
        join(dataHome.absolute.path, "temp_natives", const Uuid().v4()));
  }

  static File getClientJar(String versionID) {
    File file =
        File(join(getVersionsDir(versionID).absolute.path, "$versionID.jar"));

    if (!file.existsSync()) {
      /// RPMLauncher 舊版放置位置
      file = File(join(getVersionsDir(versionID).absolute.path, "client.jar"));
    }
    return file;
  }

  static File getArgsFile(
      String versionID, ModLoader loader, MinecraftSide side,
      {String? loaderVersion}) {
    if (loader != ModLoader.vanilla && loaderVersion == null) {
      throw Exception(
          "Mod loaders other than the vanilla require loader version parameters");
    }

    String argsPath = join(getVersionsDir(versionID).absolute.path, "args");

    /// RPMLauncher 舊版格式
    File oldFile = _oldArgs(loader, argsPath, loaderVersion: loaderVersion);
    if (side.isClient && oldFile.existsSync()) {
      return oldFile;
    } else {
      switch (loader) {
        case ModLoader.fabric:
          return File(
              join(argsPath, "Fabric", "${side.name}-$loaderVersion.json"));
        case ModLoader.forge:
          return File(
              join(argsPath, "Forge", "${side.name}-$loaderVersion.json"));
        case ModLoader.vanilla:
          return File(join(argsPath, "${side.name}-args.json"));
        default:
          throw Exception("Unknown loader, failed to get Args");
      }
    }
  }

  static File _oldArgs(ModLoader loader, String argsPath,
      {String? loaderVersion}) {
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

  static File getModInsdexFile() {
    return File(join(dataHome.absolute.path, "temp", "modindex.json"));
  }

  static File getForgeProfileFile(String versionID) {
    return File(join(getVersionsDir(versionID).path, "forge_profile.json"));
  }

  static Directory getLibraryGlobalDir() {
    return Directory(join(dataHome.absolute.path, "libraries"));
  }
}
