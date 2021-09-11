import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  static Text getVersionType() {
    String type = const String.fromEnvironment('version_type');

    if (type == "release") {
      return Text(i18n.Format("edit.instance.mods.release"),
          style: TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == "beta") {
      return Text(i18n.Format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == "alpha") {
      return Text(i18n.Format("edit.instance.mods.alpha"),
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
