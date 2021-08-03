import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:system_info/system_info.dart';

import '../path.dart';
import 'CheckAssets.dart';

class DownloadJava_ extends State<DownloadJava> {
  late Directory InstanceDir;
  late ReceivePort port;
  late Isolate isolate;
  bool finish = false;
  double DownloadJavaProgress = 0.0;

  DownloadJava_(InstanceDir_) {
    InstanceDir = Directory(InstanceDir_);
  }

  @override
  void initState() {
    super.initState();
  }

  DownloadJavaProcess(setState_) async {
    int TotalFiles = 0;
    int DoneFiles = 0;

    var InstanceConfig = json.decode(
        File(join(InstanceDir.absolute.path, "instance.json"))
            .readAsStringSync());
    int JavaVersion = InstanceConfig["java_version"];
    Response response = await get(Uri.parse(MojangJREAPI));
    Map MojangJRE = json.decode(response.body);

    Download(url) async {
      Response response = await get(Uri.parse(url));
      Map Files = json.decode(response.body);
      Files["files"].keys.forEach((file) async {
        TotalFiles++;
        if (Files["files"][file]["type"] == "file") {
          File File_ = File(
              join(dataHome.absolute.path, "jre", JavaVersion.toString(), file))
            ..createSync(recursive: true);
          http
              .get(Uri.parse(Files["files"][file]["downloads"]["raw"]["url"]))
              .then((response) async {
            await File_.writeAsBytes(response.bodyBytes);
            DoneFiles++;
            setState_(() {
              DownloadJavaProgress = DoneFiles / TotalFiles;
            });
          }).timeout(new Duration(milliseconds: 120), onTimeout: () {});
        } else {
          Directory(
              join(dataHome.absolute.path, "jre", JavaVersion.toString(), file))
            ..createSync(recursive: true);
          DoneFiles++;
        }
      });
    }

    switch (Platform.operatingSystem) {
      case 'linux':
        MojangJRE["linux"].keys.forEach((version) {
          var VersionMap = MojangJRE["linux"][version][0];
          if (VersionMap["version"]["name"].contains(JavaVersion.toString())) {
            Download(VersionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      case 'macos':
        MojangJRE["mac-os"].keys.forEach((version) {
          var VersionMap = MojangJRE["mac-os"][version][0];
          if (VersionMap["version"]["name"].contains(JavaVersion.toString())) {
            Download(VersionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      case 'windows':
        if (SysInfo.userSpaceBitness == 32) {
          MojangJRE["windows-x32"].keys.forEach((version) {
            var VersionMap = MojangJRE["windows-x32"][version][0];
            if (VersionMap["version"]["name"]
                .contains(JavaVersion.toString())) {
              Download(VersionMap["manifest"]["url"]);
              return;
            }
          });
        } else if (SysInfo.userSpaceBitness == 64) {
          MojangJRE["windows-x64"].keys.forEach((version) {
            var VersionMap = MojangJRE["windows-x64"][version][0];
            if (VersionMap["version"]["name"]
                .contains(JavaVersion.toString())) {
              Download(VersionMap["manifest"]["url"]);
              return;
            }
          });
        }
        break;
    }

    if (Platform.isWindows) {
      Config().Change(
          "java_path",
          join(dataHome.absolute.path, "jre", JavaVersion.toString(), "bin",
              "javaw.exe"));
    } else if (Platform.isLinux) {
      Config().Change(
          "java_path",
          join(dataHome.absolute.path, "jre", JavaVersion.toString(), "bin",
              "java"));
    } else if (Platform.isMacOS) {
      Config().Change(
          "java_path",
          join(dataHome.absolute.path, "jre", JavaVersion.toString(),
              "jre.bundle", "Contents", "Home", "bin", "java"));
    }
  }

  Widget build(BuildContext context) {
    if (DownloadJavaProgress == 1.0) {
      return CheckAssetsScreen(InstanceDir.absolute.path);
    } else {
      return Center(
          child: AlertDialog(
        title: Text(
          i18n().Format("gui.tips.info"),
          textAlign: TextAlign.center,
          style: new TextStyle(fontSize: 25),
        ),
        content: Text(
          "偵測到您尚未安裝Java，請選擇您要自動安裝Java或手動選擇Java路徑。",
          textAlign: TextAlign.center,
          style: new TextStyle(fontSize: 20),
        ),
        actions: [
          Center(
              child: TextButton(
            child: Text("自動安裝", style: new TextStyle(fontSize: 20)),
            onPressed: () {
              DownloadJavaProcess(setState);
              if (DownloadJavaProgress == 1.0) {
                // Navigator.pop(context);
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) =>
                      CheckAssetsScreen(InstanceDir),
                );
              } else {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("正在下載並安裝Java中...", textAlign: TextAlign.center),
                    content: LinearProgressIndicator(
                      value: DownloadJavaProgress,
                    ),
                  ),
                );
              }
            },
          )),
          SizedBox(
            height: 10,
          ),
          Center(
              child: TextButton(
            child: Text("手動選擇路徑", style: new TextStyle(fontSize: 20)),
            onPressed: () {
              utility.OpenJavaSelectScreen(context);
            },
          )),
        ],
      ));
    }
  }
}

class DownloadJava extends StatefulWidget {
  late var InstanceDir;

  DownloadJava(InstanceDir_) {
    InstanceDir = InstanceDir_;
  }

  @override
  DownloadJava_ createState() => DownloadJava_(InstanceDir);
}
