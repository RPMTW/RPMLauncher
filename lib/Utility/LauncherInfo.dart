import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

bool kTestMode = false;

class LauncherInfo {
  static const String homePageUrl = "https://www.rpmtw.com";
  static const String githubRepoUrl = "https://github.com/RPMTW/RPMLauncher";
  static const String discordUrl = "https://discord.gg/5xApZtgV2u";
  static bool get isSnapcraftApp =>
      const bool.fromEnvironment('sanp', defaultValue: false);

  static bool isFlatpakApp = false;

  static bool get multiWindow => windowID != 0;

  static WindowController get windowController =>
      WindowController.fromWindowId(windowID);

  static int windowID = 0;

  static String route = "/";

  static String getVersion() {
    return const String.fromEnvironment('version', defaultValue: '1.0.6');
  }

  static String get userOrigin {
    if (isSnapcraftApp) {
      return "snapcraft";
    } else if (isFlatpakApp) {
      return "flatpak (flathub)";
    } else if (Platform.isWindows) {
      return "windows installer";
    } else if (Platform.isMacOS) {
      return "dmg installer";
    } else {
      return "binary file";
    }
  }

  static Version get version => Version.parse(getFullVersion());

  static String getFullVersion() {
    return "${getVersion()}+${getBuildID()}";
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
          style: const TextStyle(
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center);
    } else if (type == "dev") {
      return Text(I18n.format("settings.advanced.channel.dev"),
          style: const TextStyle(color: Colors.lightBlue, fontSize: 20),
          textAlign: TextAlign.center);
    } else if (type == "debug") {
      return Text(I18n.format("settings.advanced.channel.debug"),
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
      exe = "rpmlauncher.exe";
    } else if (Platform.isMacOS) {
      exe = "rpmlauncher";
    } else if (Platform.isLinux) {
      if (LauncherInfo.isSnapcraftApp) {
        return File(absolute("/snap/rpmlauncher/current/bin/RPMLauncher"));
      }
      exe = "RPMLauncher";
    }

    return File(join(getRunningDirectory().path, exe));
  }

  static bool get autoFullScreen => Config.getValue("auto_full_screen");

  static bool isDebugMode = false;

  static late DateTime startTime;

  static void feedback(BuildContext context) {
    BetterFeedback.of(context).show((UserFeedback feedback) async {
      String text = feedback.text;
      if (text.isAllEmpty) {
        return;
      }

      // ignore: invalid_use_of_internal_member
      final realHub = Sentry.currentHub;

      final id = await realHub.captureMessage(text, withScope: (scope) {
        scope.addAttachment(SentryAttachment.fromUint8List(
          feedback.screenshot,
          'screenshot.png',
          contentType: 'image/png',
        ));
      });
      await realHub.captureUserFeedback(SentryUserFeedback(
        eventId: id,
        comments: '${feedback.text}\n${feedback.extra.toString()}',
      ));
    });
  }
}
