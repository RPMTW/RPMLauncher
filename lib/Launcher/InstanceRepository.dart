import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

import '../path.dart';
import 'GameRepository.dart';

class InstanceRepository {
  static final Directory DataHomeRootDir = dataHome;
  static final Directory ConfigRootDir = dataHome;

  static Directory _InstanceRootDir = GameRepository.getInstanceRootDir();

  static Directory getInstanceDir(InstanceDirName) {
    return Directory(join(_InstanceRootDir.path, InstanceDirName));
  }

  static File getInstanceConfigFile(InstanceDirName) {
    return File(join(getInstanceDir(InstanceDirName).path, "instance.json"));
  }

  static Map getInstanceConfig(InstanceDirName) {
    return json
        .decode(getInstanceConfigFile(InstanceDirName).readAsStringSync());
  }

  static void UpdateInstanceConfigFile(InstanceDirName, Map contents) {
    getInstanceConfigFile(InstanceDirName)
        .writeAsStringSync(json.encode(contents));
  }

  static Directory getInstanceModRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "mods"));
  }

  static Directory getInstanceResourcePackRootDir(InstanceDirName) {
    return Directory(
        join(getInstanceDir(InstanceDirName).path, "resourcepacks"));
  }
  static Directory getInstanceShaderpackRootDir(InstanceDirName) {
    return Directory(
        join(getInstanceDir(InstanceDirName).path, "shaderpacks"));
  }
  static Directory getInstanceWorldRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "saves"));
  }

  static Directory getInstanceScreenshotRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "screenshots"));
  }
}
