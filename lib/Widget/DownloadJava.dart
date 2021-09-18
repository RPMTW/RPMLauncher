import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:system_info/system_info.dart';

import '../path.dart';
import 'CheckAssets.dart';

class DownloadJava_ extends State<DownloadJava> {
  late int JavaVersion;
  DownloadJava_(JavaVersion_) {
    JavaVersion = JavaVersion_;
  }

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        i18n.format("gui.tips.info"),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25),
      ),
      content: Text(
        i18n.format("launcher.java.install.not"),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      actions: [
        Center(
            child: TextButton(
                child: Text(i18n.format("launcher.java.install.auto"),
                    style: new TextStyle(fontSize: 20, color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => Task(JavaVersion));
                })),
        SizedBox(
          height: 10,
        ),
        Center(
            child: TextButton(
          child: Text(i18n.format("launcher.java.install.manual"),
              style: new TextStyle(fontSize: 20, color: Colors.lightBlue)),
          onPressed: () {
            utility.OpenJavaSelectScreen(context).then((value) {
              if (value[0]) {
                Config.change("java_path_$JavaVersion", value[1]);
                Navigator.of(context).pop();
              }
            });
          },
        )),
      ],
    );
  }
}

class DownloadJava extends StatefulWidget {
  late var JavaVersion;

  DownloadJava(JavaVersion_) {
    JavaVersion = JavaVersion_;
  }

  @override
  DownloadJava_ createState() => DownloadJava_(JavaVersion);
}

class Task extends StatefulWidget {
  late int JavaVersion;
  Task(JavaVersion_) {
    JavaVersion = JavaVersion_;
  }

  @override
  Task_ createState() => Task_(JavaVersion);
}

class Task_ extends State<Task> {
  late ReceivePort port;
  late Isolate isolate;
  late int JavaVersion;
  double DownloadJavaProgress = 0.0;
  bool finish = false;

  Task_(JavaVersion_) {
    JavaVersion = JavaVersion_;
  }

  @override
  void initState() {
    super.initState();
    Thread();
  }

  Thread() async {
    port = ReceivePort();
    isolate = await Isolate.spawn(
        DownloadJavaProcess, [port.sendPort, JavaVersion, dataHome]);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
        setState(() {
          finish = true;
        });
      }
    });
    port.listen((message) {
      setState(() {
        DownloadJavaProgress = double.parse(message.toString());
      });
    });
  }

  static DownloadJavaProcess(List arguments) async {
    int TotalFiles = 0;
    int DoneFiles = 0;

    SendPort port = arguments[0];
    int JavaVersion = arguments[1];
    Directory DataHome_ = arguments[2];

    Response response = await get(Uri.parse(MojangJREAPI));
    Map MojangJRE = json.decode(response.body);

    Download(url) async {
      Response response = await get(Uri.parse(url));
      Map Files = json.decode(response.body);
      TotalFiles = Files["files"].keys.length;

      Files["files"].keys.forEach((file) async {
        if (Files["files"][file]["type"] == "file") {
          File File_ = File(join(
              DataHome_.absolute.path, "jre", JavaVersion.toString(), file))
            ..createSync(recursive: true);
          await http
              .get(Uri.parse(Files["files"][file]["downloads"]["raw"]["url"]))
              .then((response) {
            File_.writeAsBytesSync(response.bodyBytes);
            DoneFiles++;
            port.send(DoneFiles / TotalFiles);
          }).timeout(new Duration(milliseconds: 150), onTimeout: () {});
        } else {
          Directory(join(
              DataHome_.absolute.path, "jre", JavaVersion.toString(), file))
            ..createSync(recursive: true);
          DoneFiles++;
          port.send(DoneFiles / TotalFiles);
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
        MojangJRE["windows-x${SysInfo.userSpaceBitness}"]
            .keys
            .forEach((version) {
          var VersionMap =
              MojangJRE["windows-x${SysInfo.userSpaceBitness}"][version][0];
          if (VersionMap["version"]["name"].contains(JavaVersion.toString())) {
            Download(VersionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      default:
        break;
    }

    await path().init();

    if (Platform.isWindows) {
      Config.change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(), "bin",
              "javaw.exe"));
    } else if (Platform.isLinux) {
      Config.change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(), "bin",
              "java"));
    } else if (Platform.isMacOS) {
      Config.change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(),
              "jre.bundle", "Contents", "Home", "bin", "java"));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DownloadJavaProgress == 1 && finish) {
      return AlertDialog(
        title:
            Text(i18n.format("gui.download.done"), textAlign: TextAlign.center),
        actions: [OkClose()],
      );
    } else {
      return AlertDialog(
        title: Text(
            i18n.format("launcher.java.install.auto.downloading") + "\n",
            textAlign: TextAlign.center),
        content: LinearProgressIndicator(
          value: DownloadJavaProgress,
        ),
      );
    }
  }
}
