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

  static File getArgsFile(VersionID, Loader) {
    late File _ArgsFile;
    if (Loader == ModLoaders.Fabric || Loader == ModLoaders.Forge) {
      _ArgsFile = File(
          join(getVersionsDir(VersionID).absolute.path, "${Loader}_args.json"));
    } else {
      _ArgsFile =
          File(join(getVersionsDir(VersionID).absolute.path, "args.json"));
    }
    return _ArgsFile;
  }

  static Directory getLibraryRootDir(VersionID) {
    return Directory(
        join(getVersionsDir(VersionID).absolute.path, "libraries"));
  }
}
