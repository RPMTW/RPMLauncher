import 'dart:io';

import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:path/path.dart';

import '../path.dart';

class GameRepository {
  static final Directory DataHomeRootDir = dataHome;
  static final Directory ConfigRootDir = configHome;

  static Directory _InstanceRootDir =
      Directory(join(DataHomeRootDir.absolute.path, "instances"));
  static Directory _VersionRootDir =
      Directory(join(DataHomeRootDir.absolute.path, "versions"));

  static Directory getInstanceRootDir() {
    return _InstanceRootDir;
  }

  static File getConfigFile() {
    return File(join(ConfigRootDir.absolute.path, "config.json"));
  }

  static File getAccountFile() {
    return File(join(ConfigRootDir.absolute.path, "accounts.json"));
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
    if (Loader == ModLoader().Fabric || Loader == ModLoader().Forge) {
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
