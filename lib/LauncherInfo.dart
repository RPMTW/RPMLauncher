import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

class LauncherInfo {
  static final String HomePageUrl = "https://www.rpmtw.ga";
  static final String GithubRepoUrl = "https://github.com/RPMTW/RPMLauncher";

  static String getVersion() {
    return const String.fromEnvironment('version');
  }

  static String getLowercaseName() {
    return "rpmlauncher";
  }

  static String getUpperCaseName() {
    return "RPMLauncher";
  }

  static String getAbbreviationsName() {
    return "RWL";
  }

  static VersionTypes getVersionType() {
    String type =
        const String.fromEnvironment('version_type', defaultValue: "debug");

    VersionTypes VersionType = Updater.getVersionTypeFromString(type);
    return VersionType;
  }

  static Text getVersionTypeText() {
    String type =
        const String.fromEnvironment('version_type', defaultValue: "debug");

    if (type == "stable") {
      return Text(i18n.format("settings.advanced.channel.stable"),
          style: TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == "dev") {
      return Text(i18n.format("settings.advanced.channel.dev"),
          style: TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == "debug") {
      return Text(i18n.format("settings.advanced.channel.debug"),
          style: TextStyle(color: Colors.red, fontSize: 20),
          textAlign: TextAlign.center);
    } else {
      return Text(type,
          style: TextStyle(color: Colors.grey, fontSize: 20),
          textAlign: TextAlign.center);
    }
  }

  static int getVersionCode() {
    return const int.fromEnvironment('build_id', defaultValue: 0);
  }

  static Directory getRuningDirectory() {
    return Directory(dirname(Platform.script.path));
  }

  static File getRuningFile() {
    late String exe;

    if (Platform.isWindows) {
      exe = "rpmlauncher.exe";
    } else if (Platform.isMacOS) {
      exe = "rpmlauncher.app";
    } else if (Platform.isLinux) {
      exe = "rpmlauncher";
    }

    return File(join(getRuningDirectory().path, exe));
  }
}
