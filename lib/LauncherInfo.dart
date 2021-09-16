import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    String type = const String.fromEnvironment('version_type');

    VersionTypes ChannelType = Updater.getVersionTypeFromString(type);
    return ChannelType;
  }

  static Text getVersionTypeText() {
    String type = const String.fromEnvironment('version_type');

    if (type == "stable") {
      return Text(i18n.Format("settings.advanced.channel.stable"),
          style: TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == "dev") {
      return Text(i18n.Format("settings.advanced.channel.dev"),
          style: TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == "debug") {
      return Text(i18n.Format("settings.advanced.channel.debug"),
          style: TextStyle(color: Colors.red, fontSize: 20),
          textAlign: TextAlign.center);
    } else {
      return Text(type,
          style: TextStyle(color: Colors.grey, fontSize: 20),
          textAlign: TextAlign.center);
    }
  }

  static int getVersionCode() {
    return const int.fromEnvironment('build_id');
  }
}
