// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Instance.dart';
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

  static File instanceConfigFile(InstanceDirName) {
    return File(join(getInstanceDir(InstanceDirName).path, "instance.json"));
  }

  static InstanceConfig instanceConfig(InstanceDirName) {
    return InstanceConfig(instanceConfigFile(InstanceDirName));
  }

  static void UpdateInstanceConfigFile(InstanceDirName, Map contents) {
    instanceConfigFile(InstanceDirName)
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
