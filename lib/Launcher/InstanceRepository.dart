import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

import 'GameRepository.dart';

class InstanceRepository {
  static final Directory DataHomeRootDir = dataHome;
  static final Directory ConfigRootDir = dataHome;

  static Directory _InstanceRootDir = GameRepository.getInstanceRootDir();

  static Directory getInstanceDir(InstanceDirName) {
    return Directory(join(_InstanceRootDir.path, InstanceDirName));
  }

  static String getInstanceDirNameByDir(Directory dir) {
    return basename(dir.path);
  }

  static File InstanceConfigFile(InstanceDirName) {
    return File(join(getInstanceDir(InstanceDirName).path, "instance.json"));
  }

  static Map InstanceConfig(InstanceDirName) {
    return json.decode(InstanceConfigFile(InstanceDirName).readAsStringSync());
  }

  static void UpdateInstanceConfigFile(InstanceDirName, Map contents) {
    InstanceConfigFile(InstanceDirName)
        .writeAsStringSync(json.encode(contents));
  }

  static Directory getModRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "mods"));
  }

  static Directory getResourcePackRootDir(InstanceDirName) {
    return Directory(
        join(getInstanceDir(InstanceDirName).path, "resourcepacks"));
  }

  static Directory getShaderpackRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "shaderpacks"));
  }

  static Directory getWorldRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "saves"));
  }

  static Directory getScreenshotRootDir(InstanceDirName) {
    return Directory(join(getInstanceDir(InstanceDirName).path, "screenshots"));
  }
}
