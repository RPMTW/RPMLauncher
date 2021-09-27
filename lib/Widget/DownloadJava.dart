import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/main.dart';
import 'package:system_info/system_info.dart';

import '../path.dart';

class DownloadJava_ extends State<DownloadJava> {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      title: i18nText(
        "gui.tips.info",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25),
      ),
      content: i18nText(
        "launcher.java.install.not",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      actions: [
        Center(
            child: TextButton(
                child: i18nText("launcher.java.install.auto",
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => Task(
                            JavaVersions: widget.JavaVersions,
                          ));
                })),
        SizedBox(
          height: 10,
        ),
        Center(
            child: TextButton(
          child: i18nText("launcher.java.install.manual",
              style: TextStyle(fontSize: 20, color: Colors.lightBlue)),
          onPressed: () {
            navigator.pop();
            navigator.pushNamed(SettingScreen.route);
          },
        )),
      ],
    );
  }
}

class DownloadJava extends StatefulWidget {
  final List<int> JavaVersions;

  DownloadJava({required this.JavaVersions});

  @override
  DownloadJava_ createState() => DownloadJava_();
}

class Task extends StatefulWidget {
  final List<int> JavaVersions;
  Task({required this.JavaVersions}) {}

  @override
  Task_ createState() => Task_();
}

class Task_ extends State<Task> {
  late List<double> DownloadJavaProgreses;
  late List<bool> finishs;

  double get DownloadProgres {
    if (finishs.every((b) => b)) return 1;
    double _p = 0.0;
    DownloadJavaProgreses.forEach((progres) {
      _p += progres;
    });
    return _p / DownloadJavaProgreses.length;
  }

  @override
  void initState() {
    super.initState();
    DownloadJavaProgreses =
        List.generate(widget.JavaVersions.length, (index) => 0);
    finishs = List.generate(widget.JavaVersions.length, (index) => false);
    widget.JavaVersions.forEach((int version) {
      Thread(version);
    });
  }

  Future<void> Thread(int version) async {
    ReceivePort port = ReceivePort();
    Isolate isolate = await Isolate.spawn(
        DownloadJavaProcess, [port.sendPort, version, dataHome]);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
        finishs[widget.JavaVersions.indexOf(version)] = true;
        setState(() {});
      }
    });
    port.listen((message) {
      setState(() {
        DownloadJavaProgreses[widget.JavaVersions.indexOf(version)] =
            double.parse(message.toString());
      });
    });
  }

  static DownloadJavaProcess(List arguments) async {
    int TotalFiles = 0;
    int DoneFiles = 0;
    List<Function> _functions = [];

    SendPort port = arguments[0];
    int JavaVersion = arguments[1];
    Directory DataHome_ = arguments[2];

    Response response = await get(Uri.parse(MojangJREAPI));
    Map MojangJRE = json.decode(response.body);

    Future<void> Download(url) async {
      Response response = await get(Uri.parse(url));
      Map Files = json.decode(response.body);
      TotalFiles = Files["files"].keys.length;

      Files["files"].keys.forEach((String file) async {
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
          }).timeout(Duration(milliseconds: 150), onTimeout: () {});
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
            _functions.add(() {
              Download(VersionMap["manifest"]["url"]);
            });
            return;
          }
        });
        break;
      case 'macos':
        MojangJRE["mac-os"].keys.forEach((version) {
          if (version == "minecraft-java-exe") return;
          var VersionMap = MojangJRE["mac-os"][version][0];
          if (VersionMap["version"]["name"].contains(JavaVersion.toString())) {
            _functions.add(() {
              Download(VersionMap["manifest"]["url"]);
            });
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
            _functions.add(() {
              Download(VersionMap["manifest"]["url"]);
            });
            return;
          }
        });
        break;
      default:
        break;
    }

    await Future.forEach(_functions, (Function f) => f.call());
    await path().init();
    File configFile =
        File(join(path.currentConfigHome.absolute.path, 'config.json'));

    if (Platform.isWindows) {
      Config(configFile).Change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(), "bin",
              "javaw.exe"));
    } else if (Platform.isLinux) {
      Config(configFile).Change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(), "bin",
              "java"));
    } else if (Platform.isMacOS) {
      Config(configFile).Change(
          "java_path_${JavaVersion}",
          join(DataHome_.absolute.path, "jre", JavaVersion.toString(),
              "jre.bundle", "Contents", "Home", "bin", "java"));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (DownloadProgres == 1) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text((DownloadProgres * 100).toStringAsFixed(2) + "%"),
            LinearProgressIndicator(
              value: DownloadProgres,
            ),
          ],
        ),
      );
    }
  }
}
