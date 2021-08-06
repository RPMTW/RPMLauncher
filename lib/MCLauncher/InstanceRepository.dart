import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import '../path.dart';
import 'GameRepository.dart';

class InstanceRepository {
  static final Directory DataHomeRootDir = dataHome;
  static final Directory ConfigRootDir = configHome;

  static Directory _InstanceRootDir = GameRepository.getInstanceRootDir();

  static Directory getInstanceDir(InstanceDirName) {
    return Directory(join(_InstanceRootDir.absolute.path, InstanceDirName));
  }

  static File getInstanceConfigFile(InstanceDirName) {
    return File(
        join(getInstanceDir(InstanceDirName).absolute.path, "instance.json"));
  }

  static Map getInstanceConfig(InstanceDirName) {
    return json.decode(getInstanceConfigFile(InstanceDirName).readAsStringSync());
  }

  static Directory getInstanceModRootDir(InstanceDirName) {
    return Directory(
        join(getInstanceDir(InstanceDirName).absolute.path, "mods"));
  }
}
