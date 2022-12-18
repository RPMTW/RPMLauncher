import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/model/Game/instance.dart';

import 'GameRepository.dart';

class InstanceRepository {
  static final Directory _instanceRootDir = GameRepository.getInstanceRootDir();

  static Directory getInstanceDir(String instanceUUID) {
    return Directory(join(_instanceRootDir.path, instanceUUID));
  }

  static String getUUIDByDir(Directory dir) {
    return basename(dir.path);
  }

  static File instanceConfigFile(String instanceUUID) {
    return File(join(getInstanceDir(instanceUUID).path, "instance.json"));
  }

  static InstanceConfig? instanceConfig(String instanceUUID) {
    return InstanceConfig.fromFile(instanceConfigFile(instanceUUID));
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
