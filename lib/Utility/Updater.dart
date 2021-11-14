import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/main.dart';

enum VersionTypes { stable, dev, debug }

extension WindowsPaser on Platform {
  bool isWindows10() =>
      Platform.isWindows && Platform.operatingSystemVersion.contains('10');
  bool isWindows11() =>
      Platform.isWindows && Platform.operatingSystemVersion.contains('11');
  bool isWindows7() =>
      Platform.isWindows && Platform.operatingSystemVersion.contains('7');
  bool isWindows8() =>
      Platform.isWindows && Platform.operatingSystemVersion.contains('8');
}

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

  static bool isStable(VersionTypes channel) {
    return channel == VersionTypes.stable;
  }

  static bool isDev(VersionTypes channel) {
    return channel == VersionTypes.dev;
  }

  static bool isDebug(VersionTypes channel) {
    return channel == VersionTypes.debug;
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
      String latestVersion = data['latest_version'];
      String latestBuildID = data['latest_build_id'];
      return VersionInfo.fromJson(versionList[latestVersion][latestBuildID],
          latestBuildID, latestVersion, versionList, _needUpdate(data));
    }

    if (LauncherInfo.isDebugMode) {
      return VersionInfo(needUpdate: false);
    }

    if (isStable(channel)) {
      Map stable = data['stable'];
      return getVersionInfo(stable);
    } else if (isDev(channel)) {
      Map dev = data['dev'];
      return getVersionInfo(dev);
    } else {
      return VersionInfo(needUpdate: false);
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
        if (Platform().isWindows10() || Platform().isWindows11()) {
          downloadUrl = info.downloadUrl!.windows_10_11;
        } else if (Platform().isWindows7() || Platform().isWindows8()) {
          downloadUrl = info.downloadUrl!.windows_7;
        } else {
          throw Exception("Unsupported OS");
        }
        break;
      // case "macos":
      //   downloadUrl = info.downloadUrl!.macos;
      //   break;
      default:
        throw Exception("Unknown operating system");
    }
    double progress = 0;
    File updateFile = File(join(updateDir.absolute.path, "update.zip"));

    Future<bool> downloading() async {
      await Dio().download(
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

    Future runUpdater() async {
      String nowPath = LauncherInfo.getRuningDirectory().absolute.path;
      switch (operatingSystem) {
        case "linux":
          LauncherInfo.getRuningDirectory().deleteSync(recursive: true);

          await Uttily.copyDirectory(
              Directory(join(
                  updateDir.absolute.path, "unziped", "RPMLauncher-Linux")),
              LauncherInfo.getRuningDirectory());
          Process.run(LauncherInfo.getExecutingFile().absolute.path, []);
          exit(0);
        case "windows":
          if (Platform().isWindows10() || Platform().isWindows11()) {
            await Process.run(
                join(updateDir.absolute.path, "unziped",
                    "RPMLauncher-Windows10_11", "Install.bat"),
                []);
            exit(0);
          } else if (Platform().isWindows7() || Platform().isWindows8()) {
            await Process.run(join(nowPath, "updater.exe"), [
              "file_path",
              join(updateDir.absolute.path, "unziped", "RPMLauncher-Windows7"),
              "export_path",
              nowPath
            ]);
            exit(0);
          } else {
            throw Exception("Unsupported OS");
          }
        case "macos":
          //目前暫時不支援macOS

          break;
        default:
          throw Exception("Unknown operating system");
      }
    }

    FutureBuilder unzipDialog() {
      return FutureBuilder(
          future: unzip(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
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
            } else {
              return StatefulBuilder(builder: (context, _setState) {
                setState = _setState;
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
                return unzipDialog();
              } else {
                return StatefulBuilder(builder: (context, _setState) {
                  setState = _setState;
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
      Map versionList, bool needUpdate) {
    List<String> changelogs = [];
    List<Widget> _changelogWidgets = [];

    Version currentVersion = Version.parse("$version+$buildID");
    versionList.keys.forEach((_version) {
      versionList[_version].keys.forEach((_buildID) {
        if (Version.parse("$_version+$_buildID") > currentVersion) {
          List<String> _changelog = versionList[_version][_buildID]['changelog']
              .toString()
              .split("\n\n");

          String? _changelogType;
          Color _changelogColor = Colors.white70;

          List<String> _ = _changelog[0].split(":");
          if (_.length > 1) {
            _changelogType = _[0].toLowerCase();

            if (_changelogType.contains('feature')) {
              _changelogColor = Colors.green;
            } else if (_changelogType.contains('fix')) {
              _changelogColor = Colors.lightBlue;
            } else if (_changelogType.contains('enhancement') ||
                _changelogType.contains('improvements') ||
                _changelogType.contains('optimization')) {
              _changelogColor = Colors.orange;
            }

            _changelog[0] = _[1];
          }

          _changelog[0] = _changelog[0].trim();

          changelogs.add(_changelog[0]);

          _changelogWidgets.add(Column(
            children: [
              ListTile(
                leading: _changelogType == null
                    ? null
                    : Text(_changelogType,
                        style: TextStyle(color: _changelogColor, fontSize: 15)),
                title: Text(
                  _changelog[0],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: _changelog.length > 1
                    ? Text(_changelog[1], textAlign: TextAlign.center)
                    : null,
                onTap: () => Uttily.openUri(
                    "https://github.com/RPMTW/RPMLauncher/compare/$_version+${int.parse(_buildID) - 1}...$_version+$_buildID"),
              ),
              Divider()
            ],
          ));
        }
      });
    });

    return VersionInfo(
        downloadUrl: DownloadUrl.fromJson(json['download_url']),
        changelog: changelogs.reversed.toList().join("  \n"),
        type: Updater.getVersionTypeFromString(json['type']),
        buildID: buildID,
        version: version,
        needUpdate: needUpdate,
        changelogWidgets: _changelogWidgets.reversed.toList());
  }

  Map<String, dynamic> toJson() => {
        'download_url': downloadUrl,
        'type': type,
      };
}

class DownloadUrl {
  final String windows_10_11;
  final String windows_7;
  final String linux;
  final String linuxAppImage;
  final String macos;

  const DownloadUrl(
      {required this.windows_10_11,
      required this.windows_7,
      required this.linux,
      required this.macos,
      required this.linuxAppImage});
  factory DownloadUrl.fromJson(Map json) => DownloadUrl(
      windows_10_11: json['windows_10_11'],
      windows_7: json['windows_7'],
      linux: json['linux'],
      macos: json['macos'],
      linuxAppImage: json['linux-appimage']);
}
