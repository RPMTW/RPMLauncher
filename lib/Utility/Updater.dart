import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/path.dart';

enum UpdateChannels { stable, dev }

class Updater {
  static final String _updateUrl =
      "https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json";

  static String toI18nString(UpdateChannels channel) {
    switch (channel) {
      case UpdateChannels.stable:
        return i18n.Format('settings.advanced.channel.stable');
      case UpdateChannels.dev:
        return i18n.Format('settings.advanced.channel.dev');
      default:
        return "stable";
    }
  }

  static String toStringFromChannelType(UpdateChannels channel) {
    switch (channel) {
      case UpdateChannels.stable:
        return "stable";
      case UpdateChannels.dev:
        return "dev";
      default:
        return "stable";
    }
  }

  static UpdateChannels getChannelFromString(String channel) {
    switch (channel) {
      case "stable":
        return UpdateChannels.stable;
      case "dev":
        return UpdateChannels.dev;
      default:
        return UpdateChannels.stable;
    }
  }

  static bool isStable(UpdateChannels channel) {
    return channel == UpdateChannels.stable;
  }

  static bool isDev(UpdateChannels channel) {
    return channel == UpdateChannels.dev;
  }

  static bool versionCompareTo(String a, String b) {
    int aInt = int.parse(a.split(".").join(""));
    int bInt = int.parse(b.split(".").join(""));
    return (aInt > bInt) || (aInt == bInt);
  }

  static bool versionCodeCompareTo(String a, int b) {
    return int.parse(a) > b;
  }

  static Future<VersionInfo> checkForUpdate(UpdateChannels channel) async {
    http.Response response = await http.get(Uri.parse(_updateUrl));
    Map data = json.decode(response.body);
    Map VersionList = data['version_list'];

    bool needUpdate(Map data) {
      String latestVersion = data['latest_version'];
      String latestVersionCode = data['latest_version_code'];
      bool mainVersionCheck =
          versionCompareTo(latestVersion, LauncherInfo.getVersion());

      bool versionCodeCheck = versionCodeCompareTo(
          latestVersionCode, LauncherInfo.getVersionCode());

      bool needUpdate =
          mainVersionCheck || (mainVersionCheck && versionCodeCheck);

      return needUpdate;
    }

    VersionInfo getVersionInfo(Map data) {
      String latestVersion = data['latest_version'];
      String latestVersionCode = data['latest_version_code'];
      return VersionInfo.fromJson(VersionList[latestVersion][latestVersionCode],
          latestVersionCode, latestVersion, VersionList, needUpdate(data));
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

  static Future<void> download(VersionInfo info, BuildContext context) async {
    Directory updateDir = Directory(join(dataHome.absolute.path, "update"));
    late StateSetter setState;
    String operatingSystem = Platform.operatingSystem;
    String downloadUrl;

    switch (operatingSystem) {
      case "linux":
        downloadUrl = info.downloadUrl!.linux;
        break;
      case "windows":
        String OSVersion = Platform.operatingSystemVersion;
        if (OSVersion.contains('10') || OSVersion.contains('11')) {
          //Windows 10/11
          downloadUrl = info.downloadUrl!.windows_10_11;
        } else if (OSVersion.contains('7')) {
          //Windows 7
          downloadUrl = info.downloadUrl!.windows_7;
        } else {
          throw Exception("Unsupported OS");
        }
        break;
      case "macos":
        downloadUrl = info.downloadUrl!.macos;
        break;
      default:
        throw Exception("Unknown operating system");
    }
    double progress = 0;
    File updateFile = File(join(updateDir.absolute.path, "update.zip"));

    Future<bool> downloading() async {
      Dio dio = Dio();
      await dio.download(downloadUrl, updateFile.absolute.path,
          onReceiveProgress: (count, total) {
        setState(() {
          progress = count / total;
        });
      });
      return true;
    }

    Future unzip() async {
      Archive archive = ZipDecoder().decodeBytes(await updateFile.readAsBytes());

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          File(join(updateDir.absolute.path, "unziped", file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(join(updateDir.absolute.path, "unziped", file.name))
            ..createSync(recursive: true);
        }
      }
    }

    showDialog(
        context: context,
        builder: (context) => FutureBuilder(
            future: downloading(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                unzip();
                return AlertDialog(
                  title: Text("下載完成"),
                  actions: [OkClose()],
                );
              } else {
                return StatefulBuilder(builder: (context, _setState) {
                  setState = _setState;
                  return AlertDialog(
                    title: Text("下載檔案中..."),
                    content: LinearProgressIndicator(
                      value: progress,
                    ),
                  );
                });
              }
            }));
  }
}

class VersionInfo {
  final DownloadUrl? downloadUrl;
  final UpdateChannels? type;
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
  factory VersionInfo.fromJson(Map json, String version_code, String version,
      Map VersionList, bool needUpdate) {
    List<String> changelogs = [];
    List<Widget> _changelogWidgets = [];
    VersionList.keys.forEach((_version) {
      VersionList[_version].keys.forEach((_versionCode) {
        bool mainVersionCheck = Updater.versionCompareTo(_version, version);
        bool versionCodeCheck =
            Updater.versionCodeCompareTo(_versionCode, int.parse(version_code));
        if (mainVersionCheck || (mainVersionCheck && versionCodeCheck)) {
          String _changelog = VersionList[_version][_versionCode]['changelog'];
          changelogs.add("\\- " + _changelog);
        }
      });
    });

    return VersionInfo(
        downloadUrl: DownloadUrl.fromJson(json['download_url']),
        changelog: changelogs.reversed.toList().join("  \n"),
        type: Updater.getChannelFromString(json['type']),
        versionCode: version_code,
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
  final String macos;

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
