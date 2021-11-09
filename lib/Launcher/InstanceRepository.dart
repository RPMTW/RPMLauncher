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

  static Directory getInstanceDir(String instanceUUID) {
    return Directory(join(_instanceRootDir.path, instanceUUID));
  }

  static String getUUIDByDir(Directory dir) {
    return basename(dir.path);
  }

  static File instanceConfigFile(String instanceUUID) {
    return File(join(getInstanceDir(instanceUUID).path, "instance.json"));
  }

  static InstanceConfig instanceConfig(String instanceUUID) {
    return InstanceConfig.fromFile(instanceConfigFile(instanceUUID));
  }

  static void updateInstanceConfigFile(String instanceUUID, Map contents) {
    instanceConfigFile(instanceUUID).writeAsStringSync(json.encode(contents));
  }

  static Directory getModRootDir(String instanceUUID) {
    return Directory(join(getInstanceDir(instanceUUID).path, "mods"));
  }

  static Directory getResourcePackRootDir(String instanceUUID) {
    return Directory(join(getInstanceDir(instanceUUID).path, "resourcepacks"));
  }

  static Directory getShaderpackRootDir(String instanceUUID) {
    return Directory(join(getInstanceDir(instanceUUID).path, "shaderpacks"));
  }

  static Directory getWorldRootDir(String instanceUUID) {
    return Directory(join(getInstanceDir(instanceUUID).path, "saves"));
  }

  static Directory getScreenshotRootDir(String instanceUUID) {
    return Directory(join(getInstanceDir(instanceUUID).path, "screenshots"));
  }
}
