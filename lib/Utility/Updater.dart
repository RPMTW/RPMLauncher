// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio_http/dio_http.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

enum VersionTypes { stable, dev, debug }

extension WindowsPaser on Platform {
  bool isWindows10() => Platform.operatingSystemVersion.contains('10');
  bool isWindows11() => Platform.operatingSystemVersion.contains('11');
  bool isWindows7() => Platform.operatingSystemVersion.contains('7');
  bool isWindows8() => Platform.operatingSystemVersion.contains('8');
}

class Updater {
  static final String _updateUrl =
      "https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json";

  static String toI18nString(VersionTypes channel) {
    switch (channel) {
      case VersionTypes.stable:
        return i18n.format('settings.advanced.channel.stable');
      case VersionTypes.dev:
        return i18n.format('settings.advanced.channel.dev');
      case VersionTypes.debug:
        return i18n.format('settings.advanced.channel.debug');
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

  static bool versionCompareTo(String a, String b) {
    int aInt = int.parse(a.split(".").join(""));
    int bInt = int.parse(b.split(".").join(""));
    return aInt > bInt;
  }

  static bool versionCodeCompareTo(int a, int b) {
    return a < b;
  }

  static Future<VersionInfo> checkForUpdate(VersionTypes channel) async {
    http.Response response = await http.get(Uri.parse(_updateUrl));
    Map data = json.decode(response.body);
    Map VersionList = data['version_list'];

    bool needUpdate(Map data) {
      String latestVersion = data['latest_version'];
      int latestVersionCode = int.parse(data['latest_version_code']);
      bool mainVersionCheck =
          versionCompareTo(latestVersion, LauncherInfo.getVersion());

      bool versionCodeCheck = versionCodeCompareTo(
          LauncherInfo.getVersionCode(), latestVersionCode);

      bool needUpdate = mainVersionCheck || versionCodeCheck;

      return needUpdate;
    }

    VersionInfo getVersionInfo(Map data) {
      String latestVersion = data['latest_version'];
      String latestVersionCode = data['latest_version_code'];
      return VersionInfo.fromJson(VersionList[latestVersion][latestVersionCode],
          latestVersionCode, latestVersion, VersionList, needUpdate(data));
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
    String downloadUrl;

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
      /// 先刪除舊的更新檔案
      Directory(join(updateDir.absolute.path, "unziped"))
          .deleteSync(recursive: true);

      Archive archive =
          ZipDecoder().decodeBytes(await updateFile.readAsBytes());

      final int allFiles = archive.files.length;
      int doneFiles = 0;

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          File(join(updateDir.absolute.path, "unziped", file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(join(updateDir.absolute.path, "unziped", file.name))
            ..createSync(recursive: true);
        }
        setState(() {
          doneFiles++;
          progress = doneFiles / allFiles;
        });
      }

      return true;
    }

    Future RunUpdater() async {
      String nowPath = LauncherInfo.getRuningDirectory().absolute.path;
      switch (operatingSystem) {
        case "linux":
          await Process.run("chmod", ["+x", join(nowPath, "updater")]);
          await Process.run(join(nowPath, "updater"), [
            "file_path",
            join(updateDir.absolute.path, "unziped",
                "RPMLauncher-${info.versionCode}-linux"),
            "export_path",
            nowPath
          ]);
          exit(0);
        case "windows":
          if (Platform().isWindows10() || Platform().isWindows11()) {
            await Process.run(
                join(
                    updateDir.absolute.path,
                    "unziped",
                    "RPMLauncher-${info.versionCode}-windows_10_11",
                    "Install.bat"),
                []);
            exit(0);
          } else if (Platform().isWindows7() || Platform().isWindows8()) {
            await Process.run(join(nowPath, "updater.exe"), [
              "file_path",
              join(updateDir.absolute.path, "unziped",
                  "RPMLauncher-${info.versionCode}-windows_7"),
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

    FutureBuilder UnzipDialog() {
      return FutureBuilder(
          future: unzip(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return AlertDialog(
                title: Text("解壓縮完成"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        RunUpdater();
                      },
                      child: Text("執行安裝程式"))
                ],
              );
            } else {
              return StatefulBuilder(builder: (context, _setState) {
                setState = _setState;
                return AlertDialog(
                  title: Text("解壓縮檔案中..."),
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
                return UnzipDialog();
              } else {
                return StatefulBuilder(builder: (context, _setState) {
                  setState = _setState;
                  return AlertDialog(
                    title: Text("下載檔案中..."),
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
  final List<Widget>? changelogWidgets;
  final String? versionCode;
  final String? version;
  final bool needUpdate;

  const VersionInfo({
    this.downloadUrl,
    this.type,
    this.versionCode,
    this.version,
    this.changelog,
    this.changelogWidgets,
    required this.needUpdate,
  });
  factory VersionInfo.fromJson(Map json, String versionCode, String version,
      Map VersionList, bool needUpdate) {
    List<String> changelogs = [];
    List<Widget> _changelogWidgets = [];
    VersionList.keys.forEach((_version) {
      VersionList[_version].keys.forEach((_versionCode) {
        bool mainVersionCheck = Updater.versionCompareTo(_version, version);
        bool versionCodeCheck =
            int.parse(_versionCode) + 1 > LauncherInfo.getVersionCode();

        if (mainVersionCheck || versionCodeCheck) {
          String _changelog = VersionList[_version][_versionCode]['changelog'];
          changelogs.add(
              "\\- [$_changelog](https://github.com/RPMTW/RPMLauncher/compare/$_version.${int.parse(_versionCode) - 1}...$_version.$_versionCode)");
        }
      });
    });

    return VersionInfo(
        downloadUrl: DownloadUrl.fromJson(json['download_url']),
        changelog: changelogs.reversed.toList().join("  \n"),
        type: Updater.getVersionTypeFromString(json['type']),
        versionCode: versionCode,
        version: version,
        needUpdate: needUpdate,
        changelogWidgets: _changelogWidgets);
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
  final String? macos;

  const DownloadUrl({
    required this.windows_10_11,
    required this.windows_7,
    required this.linux,
    required this.macos,
  });
  factory DownloadUrl.fromJson(Map json) => DownloadUrl(
        windows_10_11: json['windows_10_11'],
        windows_7: json['windows_7'],
        linux: json['linux'],
        macos: json['macos'],
      );
}
