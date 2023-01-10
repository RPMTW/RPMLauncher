import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/ui/screen/home_page.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/i18n/i18n.dart';

bool kTestMode = false;

class LauncherInfo {
  static const String homePageUrl = 'https://www.rpmtw.com';
  static const String githubRepoUrl = 'https://github.com/RPMTW/RPMLauncher';
  static const String discordUrl = 'https://discord.gg/5xApZtgV2u';
  static const String microsoftClientID =
      'b7df55b4-300f-4409-8ea9-a172f844aa15';

  static bool get isSnapcraftApp =>
      const bool.fromEnvironment('snap', defaultValue: false);

  static bool isFlatpakApp = false;

  static String route = HomePage.route;

  static String getVersion() {
    return const String.fromEnvironment('version', defaultValue: '2.0.0');
  }

  static String get userOrigin {
    if (isSnapcraftApp) {
      return 'snapcraft';
    } else if (isFlatpakApp) {
      return 'flatpak (flathub)';
    } else if (Platform.isWindows) {
      return 'windows installer';
    } else if (Platform.isMacOS) {
      return 'dmg installer';
    } else {
      return 'binary file';
    }
  }

  static Version get version => Version.parse(getFullVersion());

  static String getFullVersion() {
    return '${getVersion()}+${getBuildID()}';
  }

  static String getLowercaseName() {
    return 'rpmlauncher';
  }

  static String getUpperCaseName() {
    return 'RPMLauncher';
  }

  static String getAbbreviationsName() {
    return 'RWL';
  }

  static VersionTypes getVersionType() {
    String type =
        const String.fromEnvironment('version_type', defaultValue: 'debug');

    return VersionTypes.values.byName(type);
  }

  static Text getVersionTypeText() {
    String type =
        const String.fromEnvironment('version_type', defaultValue: 'debug');

    if (type == 'stable') {
      return Text(I18n.format('settings.advanced.channel.stable'),
          style: const TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == 'dev') {
      return Text(I18n.format('settings.advanced.channel.dev'),
          style: const TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == 'debug') {
      return Text(I18n.format('settings.advanced.channel.debug'),
          style: const TextStyle(color: Colors.red, fontSize: 20),
          textAlign: TextAlign.center);
    } else {
      return Text(type,
          style: const TextStyle(color: Colors.grey, fontSize: 20),
          textAlign: TextAlign.center);
    }
  }

  static int getBuildID() {
    return const int.fromEnvironment('build_id', defaultValue: 0);
  }

  static Directory getRunningDirectory() {
    return Directory(dirname(Platform.resolvedExecutable));
  }

  static File getExecutingFile() {
    late String exe;

    if (Platform.isWindows) {
      exe = 'rpmlauncher.exe';
    } else if (Platform.isMacOS) {
      exe = 'rpmlauncher';
    } else if (Platform.isLinux) {
      if (LauncherInfo.isSnapcraftApp) {
        return File(absolute('/snap/rpmlauncher/current/bin/RPMLauncher'));
      }
      exe = 'RPMLauncher';
    }

    return File(join(getRunningDirectory().path, exe));
  }

  static bool isDebugMode = false;

  static late DateTime startTime;
}
