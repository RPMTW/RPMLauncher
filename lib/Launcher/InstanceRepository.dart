import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/main.dart';

import 'GameRepository.dart';

class InstanceRepository {
  static final Directory dataHomeRootDir = dataHome;
  static final Directory configRootDir = dataHome;

  static Directory _instanceRootDir = GameRepository.getInstanceRootDir();

  static Directory getInstanceDir(instanceDirName) {
    return Directory(join(_instanceRootDir.path, instanceDirName));
  }

  static String getinstanceDirNameByDir(Directory dir) {
    return basename(dir.path);
  }

  static File instanceConfigFile(instanceDirName) {
    return File(join(getInstanceDir(instanceDirName).path, "instance.json"));
  }

  static InstanceConfig instanceConfig(instanceDirName) {
    return InstanceConfig.fromFile(instanceConfigFile(instanceDirName));
  }

  static void updateInstanceConfigFile(instanceDirName, Map contents) {
    instanceConfigFile(instanceDirName)
        .writeAsStringSync(json.encode(contents));
  }

  static Directory getModRootDir(instanceDirName) {
    return Directory(join(getInstanceDir(instanceDirName).path, "mods"));
  }

  static Directory getResourcePackRootDir(instanceDirName) {
    return Directory(
        join(getInstanceDir(instanceDirName).path, "resourcepacks"));
  }

  static Directory getShaderpackRootDir(instanceDirName) {
    return Directory(join(getInstanceDir(instanceDirName).path, "shaderpacks"));
  }

  static Directory getWorldRootDir(instanceDirName) {
    return Directory(join(getInstanceDir(instanceDirName).path, "saves"));
  }

  static Directory getScreenshotRootDir(instanceDirName) {
    return Directory(join(getInstanceDir(instanceDirName).path, "screenshots"));
  }
}
