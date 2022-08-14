import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/util/config.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/util/data.dart';

import 'RPMHttpClient.dart';

enum VersionTypes { stable, dev, debug }

class Updater {
  static const String _updateUrl =
      "https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json";

  static String toI18nString(VersionTypes channel) {
    switch (channel) {
      case VersionTypes.stable:
        return I18n.format('settings.advanced.channel.stable');
      case VersionTypes.dev:
        return I18n.format('settings.advanced.channel.dev');
      case VersionTypes.debug:
        return I18n.format('settings.advanced.channel.debug');
      default:
        return "stable";
    }
  }

  static String toStringFromVersionType(VersionTypes channel) {
    switch (channel) {
      case VersionTypes.stable:
        return "stable";
      case VersionTypes.dev:
        return "dev";
      case VersionTypes.debug:
        return "debug";
      default:
        return "stable";
    }
  }

  static VersionTypes getVersionTypeFromString(String channel) {
    switch (channel) {
      case "stable":
        return VersionTypes.stable;
      case "dev":
        return VersionTypes.dev;
      case "debug":
        return VersionTypes.debug;
      default:
        return VersionTypes.stable;
    }
  }

  static VersionTypes fromConfig() {
    return Updater.getVersionTypeFromString(Config.getValue('update_channel'));
  }

  static bool isStable(VersionTypes channel) {
    return channel == VersionTypes.stable;
  }

  static bool isDev(VersionTypes channel) {
    return channel == VersionTypes.dev;
  }

  static bool _needUpdate(Map data) {
    String latestVersion = data['latest_version_full'];
    return Version.parse(latestVersion) >
        Version.parse(LauncherInfo.getFullVersion());
  }

  static Future<VersionInfo> checkForUpdate(VersionTypes channel) async {
    http.Response response = await http.get(Uri.parse(_updateUrl));
    Map data = json.decode(response.body);
    Map versionList = data['version_list'];

    VersionInfo getVersionInfo(Map data) {
      String latestVersion = data['latest_version'] ?? "1.0.7";
      String latestBuildID = data['latest_build_id'] ?? "0";
      return VersionInfo.fromJson(
          versionList[data['latest_version_full'] ?? "1.0.7+0"],
          latestBuildID,
          latestVersion,
          versionList.cast<String, Map>(),
          _needUpdate(data));
    }

    if (LauncherInfo.isDebugMode) {
      return const VersionInfo(needUpdate: false);
    }

    if (isStable(channel)) {
      Map stable = data['stable'];
      return getVersionInfo(stable);
    } else if (isDev(channel)) {
      Map dev = data['dev'];
      return getVersionInfo(dev);
    } else {
      return const VersionInfo(needUpdate: false);
    }
  }

  static Future<void> download(VersionInfo info) async {
    Directory updateDir = Directory(join(dataHome.absolute.path, "update"));
    late StateSetter setState;
    String operatingSystem = Platform.operatingSystem;
    late String downloadUrl;

    switch (operatingSystem) {
      case "linux":
        downloadUrl = info.downloadUrl!.linux;
        break;
      case "windows":
        downloadUrl = info.downloadUrl!.windows;
        break;
      // case "macos":
      //   downloadUrl = info.downloadUrl!.macos;
      //   break;
      default:
        throw Exception("Unknown operating system");
    }
    double progress = 0;
    File updateFile = File(join(updateDir.absolute.path, "update.zip"));

    if (Platform.isWindows) {
      updateFile = File(join(updateDir.absolute.path, "updater.exe"));
    }

    Future<bool> downloading() async {
      await RPMHttpClient().download(
        downloadUrl,
        updateFile.absolute.path,
        onReceiveProgress: (count, total) {
          setState(() {
            progress = count / total;
          });
        },
      );
      return true;
    }

    Future<bool> unzip() async {
      Directory unzipedDir =
          Directory(join(updateDir.absolute.path, "unziped"));
      if (unzipedDir.existsSync()) {
        /// 先刪除舊的更新檔案
        unzipedDir.deleteSync(recursive: true);
      }

      Archive archive =
          ZipDecoder().decodeBytes(await updateFile.readAsBytes());

      final int allFiles = archive.files.length;
      int doneFiles = 0;

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          File(join(unzipedDir.path, file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(join(unzipedDir.path, file.name))
              .createSync(recursive: true);
        }
        setState(() {
          doneFiles++;
          progress = doneFiles / allFiles;
        });
      }

      return true;
    }

    Future<void> runUpdater() async {
      switch (operatingSystem) {
        case "linux":
          LauncherInfo.getRunningDirectory().deleteSync(recursive: true);

          await Util.copyDirectory(
              Directory(join(
                  updateDir.absolute.path, "unziped", "RPMLauncher-Linux")),
              LauncherInfo.getRunningDirectory());
          Process.run(LauncherInfo.getExecutingFile().absolute.path, []);
          return Util.exit(0);
        case "windows":
          await Process.run(updateFile.path, ["/SILENT"]);
          return Util.exit(0);
        case "macos":
          //目前暫時不支援macOS

          break;
        default:
          throw Exception("Unknown operating system");
      }
    }

    Widget runUpdaterWidget(BuildContext context) {
      return AlertDialog(
        title: I18nText("updater.unzip.done"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                runUpdater();
              },
              child: I18nText("updater.run"))
        ],
      );
    }

    FutureBuilder unzipDialog() {
      return FutureBuilder(
          future: unzip(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return runUpdaterWidget(context);
            } else {
              return StatefulBuilder(builder: (context, _) {
                setState = _;
                return AlertDialog(
                  title: I18nText("updater.unziping"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                      ),
                      Text("${(progress * 100).toStringAsFixed(2)}%"),
                    ],
                  ),
                );
              });
            }
          });
    }

    showDialog(
        context: navigator.context,
        builder: (context) => FutureBuilder(
            future: downloading(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                progress = 0;

                if (Platform.isWindows) {
                  return runUpdaterWidget(context);
                } else {
                  return unzipDialog();
                }
              } else {
                return StatefulBuilder(builder: (context, _) {
                  setState = _;
                  return AlertDialog(
                    title: I18nText("updater.downloading"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                        ),
                        Text("${(progress * 100).toStringAsFixed(2)}%"),
                      ],
                    ),
                  );
                });
              }
            }));
  }
}

class VersionInfo {
  final DownloadUrl? downloadUrl;
  final VersionTypes? type;
  final String? changelog;
  final List<Widget> changelogWidgets;
  final String? buildID;
  final String? version;
  final bool needUpdate;

  const VersionInfo({
    this.downloadUrl,
    this.type,
    this.buildID,
    this.version,
    this.changelog,
    this.changelogWidgets = const [],
    required this.needUpdate,
  });
  factory VersionInfo.fromJson(Map json, String buildID, String version,
      Map<String, Map> versionList, bool needUpdate) {
    List<String> changelogs = [];
    List<Widget> changelogWidgets = [];

    Version currentVersion = Version.parse("$version+$buildID");
    VersionTypes type = Updater.getVersionTypeFromString(json['type']);

    versionList.forEach((String versionText, Map meta) {
      Version ver = Version.parse(versionText);
      if (currentVersion >= ver &&
          ver > Version.parse(LauncherInfo.getFullVersion())) {
        String changelogText = meta['changelog'];

        List<String> changelog = changelogText.toString().split("\n\n");

        String? changelogType;
        Color changelogColor = Colors.white70;

        List<String> splitResult = changelog[0].split(":");
        if (splitResult.length > 1) {
          changelogType = splitResult[0].toLowerCase();

          if (changelogType.contains('feat')) {
            changelogColor = Colors.green;
          } else if (changelogType.contains('fix')) {
            changelogColor = Colors.lightBlue;
          } else if (changelogType.contains('style') ||
              changelogType.contains('refactor') ||
              changelogType.contains('docs') ||
              changelogType.contains('perf')) {
            changelogColor = Colors.orange;
          }

          changelog[0] = splitResult[1];
        }

        changelog[0] = changelog[0].trim();

        changelogs.add(changelog[0]);

        Version oldVersion = Version(ver.major, ver.minor, ver.patch,
            build: (int.parse(ver.build.first.toString()) - 1).toString());

        changelogWidgets.add(Column(
          children: [
            ListTile(
              leading: changelogType == null
                  ? null
                  : Text(changelogType,
                      style: TextStyle(color: changelogColor, fontSize: 15)),
              title: Text(
                changelog[0],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              subtitle: changelog.length > 1
                  ? Text(changelog[1], textAlign: TextAlign.center)
                  : null,
              onTap: () => Util.openUri(
                  "https://github.com/RPMTW/RPMLauncher/compare/$oldVersion...$ver"),
            ),
            const Divider()
          ],
        ));
      }
    });

    return VersionInfo(
        downloadUrl: DownloadUrl.fromJson(json['download_url']),
        changelog: changelogs.reversed.toList().join("  \n"),
        type: type,
        buildID: buildID,
        version: version,
        needUpdate: needUpdate,
        changelogWidgets: changelogWidgets.reversed.toList());
  }

  Map<String, dynamic> toJson() => {
        'download_url': downloadUrl,
        'type': type,
      };
}

class DownloadUrl {
  final String windows;
  final String linux;
  final String linuxAppImage;
  final String macos;

  const DownloadUrl(
      {required this.windows,
      required this.linux,
      required this.macos,
      required this.linuxAppImage});
  factory DownloadUrl.fromJson(Map json) => DownloadUrl(
      windows: json['windows'],
      linux: json['linux'],
      macos: json['macos'],
      linuxAppImage: json['linux-appimage']);
}
