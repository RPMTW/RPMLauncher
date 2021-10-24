import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class LauncherInfo {
  static const String homePageUrl = "https://www.rpmtw.ga";
  static const String githubRepoUrl = "https://github.com/RPMTW/RPMLauncher";
  static bool get isSnapcraftApp =>
      const bool.fromEnvironment('sanp', defaultValue: false);

  static String getVersion() {
    return const String.fromEnvironment('version', defaultValue: '1.0.0');
  }

  static String getFullVersion() {
    return "${getVersion()}.${getVersionCode()}";
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

    VersionTypes versionType = Updater.getVersionTypeFromString(type);
    return versionType;
  }

  static Text getVersionTypeText() {
    String type =
        const String.fromEnvironment('version_type', defaultValue: "debug");

    if (type == "stable") {
      return Text(I18n.format("settings.advanced.channel.stable"),
          style: TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == "dev") {
      return Text(I18n.format("settings.advanced.channel.dev"),
          style: TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == "debug") {
      return Text(I18n.format("settings.advanced.channel.debug"),
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
    if (Platform.isWindows &&
        (Platform().isWindows10() || Platform().isWindows11()) &&
        kReleaseMode) {
      Directory windowsAppsDir =
          Directory(join("C:", "Program Files", "WindowsApps"));
      List<FileSystemEntity> windowsAppsList = windowsAppsDir
          .listSync()
          .where((FileSystemEntity fse) =>
              basename(fse.path).contains('ga.rpmtw.rpmlauncher'))
          .toList();

      if (windowsAppsList.isNotEmpty) {
        return Directory(windowsAppsList.first.path);
      }
    }
    return Directory(dirname(Platform.resolvedExecutable));
  }

  static File getExecutingFile() {
    late String exe;

    if (Platform.isWindows) {
      exe = "rpmlauncher.exe";
    } else if (Platform.isMacOS) {
      exe = "rpmlauncher";
    } else if (Platform.isLinux) {
      if (LauncherInfo.isSnapcraftApp) {
        return File(absolute("/snap/rpmlauncher/current/bin/RPMLauncher"));
      }
      exe = "RPMLauncher";
    }

    return File(join(getRuningDirectory().path, exe));
  }

  static bool get autoFullScreen => Config.getValue("auto_full_screen");

  static bool isDebugMode = false;
}
