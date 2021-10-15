// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';
import 'package:rpmlauncher/path.dart';

class GameRepository {
  static Directory _InstanceRootDir =
      Directory(join(dataHome.absolute.path, "instances"));
  static Directory _VersionRootDir =
      Directory(join(dataHome.absolute.path, "versions"));

  static void init() {
    utility.CreateFolderOptimization(getInstanceRootDir());
    utility.CreateFolderOptimization(getVersionsRootDir());
  }

  static Directory getInstanceRootDir() {
    return _InstanceRootDir;
  }

  static File getConfigFile() {
    return File(join(path.currentConfigHome.absolute.path, "config.json"));
  }

  static File getAccountFile() {
    return File(join(path.currentConfigHome.absolute.path, "accounts.json"));
  }

  static Directory getVersionsRootDir() {
    return _VersionRootDir;
  }

  static Directory getVersionsDir(VersionID) {
    return Directory(join(_VersionRootDir.absolute.path, VersionID));
  }

  static Directory getNativesDir(VersionID) {
    return Directory(join(getVersionsDir(VersionID).absolute.path, "natives"));
  }

  static File getClientJar(VersionID) {
    return File(join(getVersionsDir(VersionID).absolute.path, "client.jar"));
  }

  static File getArgsFile(String VersionID, ModLoaders Loader,
      [String? LoaderVersion]) {
    if (Loader != ModLoaders.vanilla && LoaderVersion == null) {
      throw Exception(
          "Mod loaders other than the vanilla require loader version parameters");
    }

    String ArgsPath = join(getVersionsDir(VersionID).absolute.path, "args");
    switch (Loader) {
      case ModLoaders.fabric:
        return File(join(ArgsPath, "Fabric", "$LoaderVersion.json"));
      case ModLoaders.forge:
        return File(join(ArgsPath, "Forge", "$LoaderVersion.json"));
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
